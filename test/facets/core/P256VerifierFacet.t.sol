// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {P256VerifierFacet} from "../../../contracts/facets/p256_verifier/P256VerifierFacet.sol";

using stdJson for string;

contract P256VerifierTest is Test {
    P256VerifierFacet public verifier;

    function setUp() public {
        verifier = new P256VerifierFacet();
    }

    /** Checks a single test vector: signature rs, pubkey Q = (x,y). */
    function evaluate(
        bytes32 hash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) private returns (bool valid, uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        bool result = verifier.ecdsaVerify(hash, r, s, [x, y]);
        gasUsed = gasBefore - gasleft();

        return (result, gasUsed);
    }

    // Sanity check. Demonstrate input and output handling.
    function testBasic() public {
        // Zero inputs
        bytes32 hash = bytes32(0);
        (uint256 r, uint256 s, uint256 x, uint256 y) = (0, 0, 0, 0);
        (bool res, uint256 gasUsed) = evaluate(hash, r, s, x, y);
        console2.log("Zero inputs, gasUsed ", gasUsed);
        assertEq(res, false);

        // First valid Wycheproof vector
        hash = 0xbb5a52f42f9c9261ed4361f59422a1e30036e7c32b270c8807a419feca605023;
        r = 19738613187745101558623338726804762177711919211234071563652772152683725073944;
        s = 34753961278895633991577816754222591531863837041401341770838584739693604822390;
        x = 18614955573315897657680976650685450080931919913269223958732452353593824192568;
        y = 90223116347859880166570198725387569567414254547569925327988539833150573990206;
        (res, gasUsed) = evaluate(hash, r, s, x, y);
        console2.log("Valid signature, gasUsed ", gasUsed);
        assertEq(res, true);

        // Same as above, but off by 1
        (res, gasUsed) = evaluate(hash, r, s, x + 1, y);
        console2.log("Invalid signature, gasUsed ", gasUsed);
        assertEq(res, false);
    }

    // This is the most comprehensive test, covering many edge cases. See vector
    // generation and validation in the test-vectors directory.
    function testWycheproof() public {
        string memory file = "./test/testdata/test-vectors/vectors_wycheproof.jsonl";
        while (true) {
            string memory vector = vm.readLine(file);
            if (bytes(vector).length == 0) {
                break;
            }

            uint256 x = uint256(vector.readBytes32(".x"));
            uint256 y = uint256(vector.readBytes32(".y"));
            uint256 r = uint256(vector.readBytes32(".r"));
            uint256 s = uint256(vector.readBytes32(".s"));
            bytes32 hash = vector.readBytes32(".hash");
            bool expected = vector.readBool(".valid");
            string memory comment = vector.readString(".comment");

            (bool result, ) = evaluate(hash, r, s, x, y);

            string memory err = string(
                abi.encodePacked(
                    "exp ",
                    expected ? "1" : "0",
                    ", we return ",
                    result ? "1" : "0",
                    ": ",
                    comment
                )
            );
            assertTrue(result == expected, err);
        }
    }

    function testOutOfBounds() public {
        // Curve prime field modulus
        uint256 p = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;

        bytes32 hash = bytes32(0);
        (uint256 r, uint256 s, uint256 x, uint256 y) = (1, 1, 1, 1);

        // In-bounds dummy key (1, 1)
        // Calls modexp, which takes gas.
        (bool result, uint256 gasUsed) = evaluate(hash, r, s, x, y);
        console2.log("gasUsed ", gasUsed);
        assertEq(result, false);
        assertGt(gasUsed, 2000);

        // Out-of-bounds public key. Fails fast, takes less gas.
        (x, y) = (0, 1);
        (result, gasUsed) = evaluate(hash, r, s, x, y);
        console2.log("gasUsed ", gasUsed);
        assertEq(result, false);
        assertLt(gasUsed, 2000);

        (x, y) = (1, 0);
        (result, gasUsed) = evaluate(hash, r, s, x, y);
        console2.log("gasUsed ", gasUsed);
        assertEq(result, false);
        assertLt(gasUsed, 2000);

        (x, y) = (1, p);
        (result, gasUsed) = evaluate(hash, r, s, x, y);
        console2.log("gasUsed ", gasUsed);
        assertEq(result, false);
        assertLt(gasUsed, 2000);

        (x, y) = (p, 1);
        (result, gasUsed) = evaluate(hash, r, s, x, y);
        console2.log("gasUsed ", gasUsed);
        assertEq(result, false);
        assertLt(gasUsed, 2000);

        // p-1 is in-bounds but point is not on curve.
        (x, y) = (p - 1, 1);
        (result, gasUsed) = evaluate(hash, r, s, x, y);
        console2.log("gasUsed ", gasUsed);
        assertEq(result, false);
    }
}