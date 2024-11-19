// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IV1CertificateVerifier.sol";
import "hardhat/console.sol";

// TODO date verifications + malformed certs

contract V1CertificateVerifier is IV1CertificateVerifier, Ownable {
    address VERIFIER;
    // root cert template
    bytes constant ri1 = hex"30";
    bytes constant ri3 = hex"a00302010202";
    bytes constant ri7 = hex"300a06082a8648ce3d0403023068311a301806035504030c11496e74656c2053475820526f6f74204341311a3018060355040a0c11496e74656c20436f72706f726174696f6e3114301206035504070c0b53616e746120436c617261310b300906035504080c024341310b3009060355040613025553301e170d";
    bytes constant ri11 =
        hex"170d3333303532313130353031305a30703122302006035504030c19496e74656c205347582050434b20506c6174666f726d204341311a3018060355040a0c11496e74656c20436f72706f726174696f6e3114301206035504070c0b53616e746120436c617261310b300906035504080c024341310b30090603550406130255533059301306072a8648ce3d020106082a8648ce3d03010703420004";
    bytes constant ri16 = hex"a3";
    uint256 constant rbase_len = 349;

    // platform cert template
    bytes constant pi1 = hex"30";
    bytes constant pi3 = hex"a00302010202";
    bytes constant pi7 =
        hex"300a06082a8648ce3d04030230703122302006035504030c19496e74656c205347582050434b20506c6174666f726d204341311a3018060355040a0c11496e74656c20436f72706f726174696f6e3114301206035504070c0b53616e746120436c617261310b300906035504080c024341310b3009060355040613025553301e170d";
    bytes constant pi11 = hex"170d";
    bytes constant pi13 =
        hex"30703122302006035504030c19496e74656c205347582050434b204365727469666963617465311a3018060355040a0c11496e74656c20436f72706f726174696f6e3114301206035504070c0b53616e746120436c617261310b300906035504080c024341310b30090603550406130255533059301306072a8648ce3d020106082a8648ce3d03010703420004";
    bytes constant pi16 = hex"a3";
    uint256 constant pbase_len = 344;

    ECKey rootCA;
    mapping(uint256 => ECKey) platformCAs;
    mapping(uint256 => mapping(uint256 => ECKey)) processorPCKs;
    mapping(uint256 => uint256[]) processorPCKserials;

    constructor(
        address initialOwner,
        address _ecverifier
    ) Ownable(initialOwner) {
        VERIFIER = _ecverifier;
    }

    // TODO find proper replacement
    function tail(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (bytes memory) {
        uint256 _length = _bytes.length - _start;
        require(_length + 31 >= _length, "slice_overflow");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40)
                let lengthmod := and(_length, 31)
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }
                mstore(tempBytes, _length)
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)
                mstore(0x40, add(tempBytes, 0x20))
            }
        }
        return tempBytes;
    }
    function encodeLengthDER (
        uint256 n
    ) internal pure returns (bytes memory) {
        if (n < 127) {
            return abi.encodePacked(uint8(n));
        } else {
            bytes memory nb = abi.encodePacked(n);
            uint8 i = 0;
            while (nb[i] == 0x00) { i++; }
            return bytes.concat(bytes1((32 - i) | 0x80), tail(nb, i));
        }
    }

    function rootCertBodyHash(
        bytes memory serial,
        bytes memory not_before,
        uint256 x,
        uint256 y,
        bytes memory extensions
    ) public pure returns (bytes32) {
        bytes memory i17 = encodeLengthDER(extensions.length);
        bytes memory i5 = encodeLengthDER(serial.length);
        bytes memory i2 = encodeLengthDER(rbase_len + i17.length + i5.length + extensions.length + serial.length +
                                          not_before.length);
        return sha256(bytes.concat(ri1,i2,ri3,i5,serial,ri7,not_before,ri11,bytes32(x),bytes32(y),ri16,i17,extensions));
    }

    function platformCertBodyHash(
        bytes memory serial,
        bytes memory not_before,
        bytes memory not_after,
        uint256 x,
        uint256 y,
        bytes memory extensions
    ) public pure returns (bytes32) {
        bytes memory i17 = encodeLengthDER(extensions.length);
        bytes memory i5 = encodeLengthDER(serial.length);
        bytes memory i2 = encodeLengthDER(pbase_len + i17.length + i5.length + extensions.length + serial.length +
                                          not_before.length + not_after.length);
        bytes memory part_sum = bytes.concat(pi1, i2, pi3, i5, serial, pi7, not_before, pi11, not_after);
        return sha256(bytes.concat(part_sum, pi13, bytes32(x),bytes32(y), pi16, i17, extensions));
    }

    function addRootKey (
        ECKey memory key
    ) public onlyOwner {
        rootCA = key;
    }

    function uintToBytesDER(
        uint256 n
    ) public pure returns (bytes memory) {
        require(n < 0x8000000000000000000000000000000000000000000000000000000000000000, "Can only encode small integers");
        if (n == 0) {
            return hex"0000";
        } else {
            bytes memory b = abi.encodePacked(n);
            uint i = 0;
            while(b[i] == 0) {
                i++;
            }
            if((b[i] & 0x80) !=  0) {
                i--;
            }
            return tail(b, i);
        }
    }
    
    function addPlatformCAKey(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory not_before,
        bytes memory extensions,
        uint256 r,
        uint256 s
    ) public {
        bytes32 hash = rootCertBodyHash(
                    uintToBytesDER(serial),
                    not_before,
                    x,
                    y,
                    extensions
        );
        bool success = verifySignatureAllowMalleability(
            hash,
            r,
            s,
            rootCA.x,
            rootCA.y
        );
        require(success, "Signature is invalid");
        // TODO: not_before, not_after decoding
        platformCAs[serial] = ECKey(x,y,0,0);
    }

    function verifySignatureAllowMalleability(
        bytes32 message_hash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool) {
        bytes memory args = abi.encode(message_hash, r, s, x, y);
        (bool success, bytes memory ret) = VERIFIER.staticcall(args);
        assert(success); // never reverts, always returns 0 or 1

        return abi.decode(ret, (uint256)) == 1;
    }

    function addPCK(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory not_before,
        bytes memory not_after,
        bytes memory extensions,
        uint256 authority,
        uint256 r,
        uint256 s
    ) public {
        ECKey memory authority_key = platformCAs[authority];
        require(authority_key.x != 0, "Couldn't find related platform CA");
        bytes32 hash = platformCertBodyHash(
                    uintToBytesDER(serial),
                    not_before,
                    not_after,
                    x,
                    y,
                    extensions
        );
        bool success = verifySignatureAllowMalleability(
            hash,
            r,
            s,
            authority_key.x,
            authority_key.y
        );
        require(success, "Signature is invalid");
        // TODO not_before, not_after
        processorPCKs[authority][serial] = ECKey(x,y,0,0);
        processorPCKserials[authority].push(serial);
    }

    function revokePCK(uint256 platform_serial, uint256 pck_serial) public onlyOwner {
        delete processorPCKs[platform_serial][pck_serial];
    }

    // TODO rewrite such that unneeded items are popped
    function revokePlatformCA(uint256 serial) public onlyOwner {
        console.logUint(serial);
        delete platformCAs[serial];
        uint256 curr_len = processorPCKserials[serial].length;

        while(curr_len > 0) {
            uint256 pck_serial = processorPCKserials[serial][curr_len - 1];
            delete processorPCKs[serial][pck_serial];
            processorPCKserials[serial].pop();
            curr_len -= 1;
        }
    }

    function getPCK(uint256 platform_serial, uint256 pck_serial) public view returns (ECKey memory) {
        return processorPCKs[platform_serial][pck_serial];
    }
}
