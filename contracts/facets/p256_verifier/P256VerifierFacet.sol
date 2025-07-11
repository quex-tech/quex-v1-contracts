// SPDX-License-Identifier: MIT
// Force a specific Solidity version for reproducibility.
pragma solidity 0.8.22;

import {IP256Verifier} from "../../interfaces/core/IP256Verifier.sol";

/**
 * This contract verifies P256 (secp256r1) signatures. It matches the exact
 * interface specified in the EIP-7212 precompile, allowing it to be used as a
 * fallback. It's based on Ledger's optimized implementation:
 * https://github.com/rdubois-crypto/FreshCryptoLib/tree/master/solidity
 **/
contract P256VerifierFacet is IP256Verifier {
    // Parameters for the sec256r1 (P256) elliptic curve
    // Curve prime field modulus
    uint256 private constant P =
        0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
    // Short weierstrass first coefficient
    uint256 private constant A = // The assumption a == -3 (mod p) is used throughout the codebase
        0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
    // Short weierstrass second coefficient
    uint256 private constant B =
        0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
    // Generating point affine coordinates
    uint256 private constant GX =
        0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
    uint256 private constant GY =
        0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;
    // Curve order (number of points)
    uint256 private constant N =
        0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
    // -2 mod p constant, used to speed up inversion and doubling (avoid negation)
    uint256 private constant MINUS_2MODP =
        0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFD;
    // -2 mod n constant, used to speed up inversion
    uint256 private constant MINUS_2MODN =
        0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC63254F;

    /**
     * @dev ECDSA verification given signature and public key.
     */
    function ecdsaVerify(
        bytes32 messageHash,
        uint256 r,
        uint256 s,
        uint256[2] calldata pubKey
    ) external view returns (bool) {
        // Check r and s are in the scalar field
        if (r == 0 || r >= N || s == 0 || s >= N) {
            return false;
        }

        if (!ecAffIsValidPubkey(pubKey[0], pubKey[1])) {
            return false;
        }

        uint256 sInv = nModInv(s);

        uint256 scalarU = mulmod(uint256(messageHash), sInv, N); // (h * s^-1) in scalar field
        uint256 scalarV = mulmod(r, sInv, N); // (r * s^-1) in scalar field

        uint256 rX = ecZZMulmuladd(
            pubKey[0],
            pubKey[1],
            scalarU,
            scalarV
        );
        return rX % N == r;
    }

    /**
     * @dev Check if a point in affine coordinates is on the curve
     * Reject 0 point at infinity.
     */
    function ecAffIsValidPubkey(
        uint256 x,
        uint256 y
    ) internal pure returns (bool) {
        if (x >= P || y >= P || (x == 0 && y == 0)) {
            return false;
        }

        return ecAffSatisfiesCurveEqn(x, y);
    }

    function ecAffSatisfiesCurveEqn(
        uint256 x,
        uint256 y
    ) internal pure returns (bool) {
        uint256 lhs = mulmod(y, y, P); // y^2
        uint256 rhs = addmod(mulmod(mulmod(x, x, P), x, P), mulmod(A, x, P), P); // x^3 + a x
        rhs = addmod(rhs, B, P); // x^3 + a*x + b

        return lhs == rhs;
    }

    /**
     * @dev Computation of uG + vQ using Strauss-Shamir's trick, G basepoint, Q public key
     * returns tuple of (x coordinate of uG + vQ, boolean that is false if internal precompile staticcall fail)
     * Strauss-Shamir is described well in https://stackoverflow.com/a/50994362
     */
    function ecZZMulmuladd(
        uint256 qX,
        uint256 qY, // affine rep for input point Q
        uint256 scalarU,
        uint256 scalarV
    ) internal view returns (uint256 x) {
        uint256 zz = 1;
        uint256 zzz = 1;
        uint256 y;
        uint256 hX;
        uint256 hY;

        if (scalarU == 0 && scalarV == 0) return 0;

        // H = g + Q
        (hX, hY) = ecAffAdd(GX, GY, qX, qY);

        int256 index = 255;
        uint256 bitpair;

        // Find the first bit index that's active in either scalar_u or scalar_v.
        while(index >= 0) {
            bitpair = computeBitpair(uint256(index), scalarU, scalarV);
            --index;
            if (bitpair != 0) break;
        }

        // initialise (X, Y) depending on the first active bitpair.
        // invariant(bitpair != 0); // bitpair == 0 is only possible if u and v are 0.
        
        if (bitpair == 1) {
            (x, y) = (GX, GY);
        } else if (bitpair == 2) {
            (x, y) = (qX, qY);
        } else if (bitpair == 3) {
            (x, y) = (hX, hY);
        }

        uint256 tX;
        uint256 tY;
        while(index >= 0) {
            (tX, tY, zz, zzz) = ecZZDoubleZz(tX, tY, zz, zzz);

            bitpair = computeBitpair(uint256(index), scalarU, scalarV);
            --index;

            if (bitpair == 0) {
                continue;
            } else if (bitpair == 1) {
                (tX, tY) = (GX, GY);
            } else if (bitpair == 2) {
                (tX, tY) = (qX, qY);
            } else {
                (tX, tY) = (hX, hY);
            }

            (tX, tY, zz, zzz) = ecZZDaddAffine(tX, tY, zz, zzz, tX, tY);
        }

        uint256 zzInv = pModInv(zz); // If zz = 0, zzInv = 0.
        x = mulmod(x, zzInv, P); // X/zz
    }

    /**
     * @dev Compute the bits at `index` of u and v and return
     * them as 2 bit concatenation. The bit at index 0 is on 
     * if the `index`th bit of scalar_u is on and the bit at
     * index 1 is on if the `index`th bit of scalar_v is on.
     * Examples:
     * - compute_bitpair(0, 1, 1) == 3
     * - compute_bitpair(0, 1, 0) == 1
     * - compute_bitpair(0, 0, 1) == 2
     */
    function computeBitpair(uint256 index, uint256 scalarU, uint256 scalarV) internal pure returns (uint256 ret) {
        ret = (((scalarV >> index) & 1) << 1) + ((scalarU >> index) & 1);
    }

    /**
     * @dev Add two elliptic curve points in affine coordinates
     * Assumes points are on the EC
     */
    function ecAffAdd(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) internal view returns (uint256, uint256) {
        // invariant(ecAff_IsZero(x1, y1) || ecAff_isOnCurve(x1, y1));
        // invariant(ecAff_IsZero(x2, y2) || ecAff_isOnCurve(x2, y2));

        uint256 zz1;
        uint256 zzz1;

        if (ecAffIsInf(x1, y1)) return (x2, y2);
        if (ecAffIsInf(x2, y2)) return (x1, y1);

        (x1, y1, zz1, zzz1) = ecZZDaddAffine(x1, y1, 1, 1, x2, y2);

        return ecZZSetAff(x1, y1, zz1, zzz1);
    }

    /**
     * @dev Check if a point is the infinity point in affine rep.
     * Assumes point is on the EC or is the point at infinity.
     */
    function ecAffIsInf(
        uint256 x,
        uint256 y
    ) internal pure returns (bool flag) {
        // invariant((x == 0 && y == 0) || ecAff_isOnCurve(x, y));

        return (x == 0 && y == 0);
    }

    /**
     * @dev Check if a point is the infinity point in ZZ rep.
     * Assumes point is on the EC or is the point at infinity.
     */
    function ecZZIsInf(
        uint256 zz,
        uint256 zzz
    ) internal pure returns (bool flag) {
        // invariant((zz == 0 && zzz == 0) || ecAff_isOnCurve(x, y) for affine 
        // form of the point)

        return (zz == 0 && zzz == 0);
    }

    /**
     * @dev Add a ZZ point to an affine point and return as ZZ rep
     * Uses madd-2008-s and mdbl-2008-s internally
     * https://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz-3.html#addition-madd-2008-s
     * Matches https://github.com/supranational/blst/blob/9c87d4a09d6648e933c818118a4418349804ce7f/src/ec_ops.h#L705 closely
     * Handles points at infinity gracefully
     */
    function ecZZDaddAffine(
        uint256 x1,
        uint256 y1,
        uint256 zz1,
        uint256 zzz1,
        uint256 x2,
        uint256 y2
    ) internal pure returns (uint256 x3, uint256 y3, uint256 zz3, uint256 zzz3) {
        if (ecAffIsInf(x2, y2)) { // (X2, Y2) is point at infinity
            if (ecZZIsInf(zz1, zzz1)) return ecZZPointAtInf();
            return (x1, y1, zz1, zzz1);
        } else if (ecZZIsInf(zz1, zzz1)) { // (X1, Y1) is point at infinity
            return (x2, y2, 1, 1);
        }

        uint256 compR = addmod(mulmod(y2, zzz1, P), P - y1, P); // R = S2 - y1 = y2*zzz1 - y1
        uint256 compP = addmod(mulmod(x2, zz1, P), P - x1, P); // P = U2 - x1 = x2*zz1 - x1

        if (compP != 0) { // X1 != X2
            // invariant(x1 != x2);
            uint256 compPP = mulmod(compP, compP, P); // PP = P^2
            uint256 compPPP = mulmod(compPP, compP, P); // PPP = P*PP
            zz3 = mulmod(zz1, compPP, P); //// ZZ3 = ZZ1*PP
            zzz3 = mulmod(zzz1, compPPP, P); //// ZZZ3 = ZZZ1*PPP
            uint256 compQ = mulmod(x1, compPP, P); // Q = X1*PP
            x3 = addmod(
                addmod(mulmod(compR, compR, P), P - compPPP, P), // (R^2) + (-PPP)
                mulmod(MINUS_2MODP, compQ, P), // (-2)*(Q)
                P
            ); // R^2 - PPP - 2*Q
            y3 = addmod(
                mulmod(addmod(compQ, P - x3, P), compR, P), //(Q+(-x3))*R
                mulmod(P - y1, compPPP, P), // (-y1)*PPP
                P
            ); // R*(Q-x3) - y1*PPP
        } else if (compR == 0) { // X1 == X2 and Y1 == Y2
            // invariant(x1 == x2 && y1 == y2);

            // Must be affine because (X2, Y2) is affine.
            (x3, y3, zz3, zzz3) = ecZZDoubleAffine(x2, y2);
        } else { // X1 == X2 and Y1 == -Y2
            // invariant(x1 == x2 && y1 == p - y2);
            (x3, y3, zz3, zzz3) = ecZZPointAtInf();
        }

        return (x3, y3, zz3, zzz3);
    }

    /**
     * @dev Double a ZZ point 
     * Uses http://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz.html#doubling-dbl-2008-s-1
     * Handles point at infinity gracefully
     */
    function ecZZDoubleZz(uint256 x1,
        uint256 y1, uint256 zz1, uint256 zzz1) internal pure returns (uint256 x3, uint256 y3, uint256 zz3, uint256 zzz3) {
        if (ecZZIsInf(zz1, zzz1)) return ecZZPointAtInf();
    
        uint256 compU = mulmod(2, y1, P); // U = 2*Y1
        uint256 compV = mulmod(compU, compU, P); // V = U^2
        uint256 compW = mulmod(compU, compV, P); // W = U*V
        uint256 compS = mulmod(x1, compV, P); // S = X1*V
        uint256 compM = addmod(mulmod(3, mulmod(x1, x1, P), P), mulmod(A, mulmod(zz1, zz1, P), P), P); //M = 3*(X1)^2 + a*(zz1)^2
        
        x3 = addmod(mulmod(compM, compM, P), mulmod(MINUS_2MODP, compS, P), P); // M^2 + (-2)*S
        y3 = addmod(mulmod(compM, addmod(compS, P - x3, P), P), mulmod(P - compW, y1, P), P); // M*(S+(-X3)) + (-W)*Y1
        zz3 = mulmod(compV, zz1, P); // V*ZZ1
        zzz3 = mulmod(compW, zzz1, P); // W*ZZZ1
    }

    /**
     * @dev Double an affine point and return as a ZZ point 
     * Uses http://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz.html#doubling-mdbl-2008-s-1
     * Handles point at infinity gracefully
     */
    function ecZZDoubleAffine(uint256 x1,
        uint256 y1) internal pure returns (uint256 x3, uint256 y3, uint256 zz3, uint256 zzz3) {
        if (ecAffIsInf(x1, y1)) return ecZZPointAtInf();

        uint256 compU = mulmod(2, y1, P); // U = 2*Y1
        zz3 = mulmod(compU, compU, P); // V = U^2 = zz3
        zzz3 = mulmod(compU, zz3, P); // W = U*V = zzz3
        uint256 compS = mulmod(x1, zz3, P); // S = X1*V
        uint256 compM = addmod(mulmod(3, mulmod(x1, x1, P), P), A, P); // M = 3*(X1)^2 + a
        
        x3 = addmod(mulmod(compM, compM, P), mulmod(MINUS_2MODP, compS, P), P); // M^2 + (-2)*S
        y3 = addmod(mulmod(compM, addmod(compS, P - x3, P), P), mulmod(P - zzz3, y1, P), P); // M*(S+(-X3)) + (-W)*Y1
    }

    /**
     * @dev Convert from ZZ rep to affine rep
     * Assumes (zz)^(3/2) == zzz (i.e. zz == z^2 and zzz == z^3)
     * See https://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz-3.html
     */
    function ecZZSetAff(
        uint256 x,
        uint256 y,
        uint256 zz,
        uint256 zzz
    ) internal view returns (uint256 x1, uint256 y1) {
        if(ecZZIsInf(zz, zzz)) {
            (x1, y1) = ecAffinePointAtInf();
            return (x1, y1);
        }

        uint256 zzzInv = pModInv(zzz); // 1 / zzz
        uint256 zInv = mulmod(zz, zzzInv, P); // 1 / z
        uint256 zzInv = mulmod(zInv, zInv, P); // 1 / zz

        // invariant(mulmod(FCL_pModInv(zInv), FCL_pModInv(zInv), p) == zz)
        // invariant(mulmod(mulmod(FCL_pModInv(zInv), FCL_pModInv(zInv), p), FCL_pModInv(zInv), p) == zzz)

        x1 = mulmod(x, zzInv, P); // X / zz
        y1 = mulmod(y, zzzInv, P); // y = Y / zzz
    }

    /**
     * @dev Point at infinity in ZZ rep
     */
    function ecZZPointAtInf() internal pure returns (uint256, uint256, uint256, uint256) {
        return (0, 0, 0, 0);
    }

    /**
     * @dev Point at infinity in affine rep
     */
    function ecAffinePointAtInf() internal pure returns (uint256, uint256) {
        return (0, 0);
    }

    /**
     * @dev u^-1 mod n
     */
    function nModInv(uint256 u) internal view returns (uint256) {
        return modInv(u, N, MINUS_2MODN);
    }

    /**
     * @dev u^-1 mod p
     */
    function pModInv(uint256 u) internal view returns (uint256) {
        return modInv(u, P, MINUS_2MODP);
    }

    /**
     * @dev u^-1 mod f = u^(phi(f) - 1) mod f = u^(f-2) mod f for prime f
     * by Fermat's little theorem, compute u^(f-2) mod f using modexp precompile
     * Assume f != 0. If u is 0, then u^-1 mod f is undefined mathematically, 
     * but this function returns 0.
     */
    function modInv(uint256 u, uint256 f, uint256 minus2modf) internal view returns (uint256 result) {
        // invariant(f != 0);
        // invariant(f prime);

        // This seems like a relatively standard way to use this precompile:
        // https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3298/files#diff-489d4519a087ca2c75be3315b673587abeca3b302f807643e97efa7de8cb35a5R427

        (bool success, bytes memory ret) = (address(0x05).staticcall(abi.encode(32, 32, 32, u, minus2modf, f)));
        assert(success); // precompile should never fail on regular EVM environments
        result = abi.decode(ret, (uint256));
    }
}
