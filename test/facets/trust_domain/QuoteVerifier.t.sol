// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {QuoteVerifier} from "../../../contracts/facets/trust_domain/QuoteVerifier.sol";
import {TDQuote} from "../../../contracts/facets/trust_domain/TrustDomainStorage.sol";

contract QuoteVerifierTest is Test {
    using QuoteVerifier for *;

    function test_ensureTDIsNotInDebugMode_ValidAttributes() public {
        bytes8 validAttributes = bytes8(0);
        validAttributes = _setBit(validAttributes, 28);
        validAttributes = _setBit(validAttributes, 30);
        validAttributes = _setBit(validAttributes, 31);
        validAttributes = _setBit(validAttributes, 63);
        console.logBytes8(validAttributes);

        TDQuote memory tdQuote = _createTDQuote(validAttributes);

        // This should not revert
        QuoteVerifier.ensureTDIsNotInDebugMode(tdQuote);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_ensureTDIsNotInDebugMode_InvalidBits0to27() public {
        // Test each bit from 0 to 27
        for (uint8 i = 0; i <= 27; i++) {
            bytes8 invalidAttributes = bytes8(0);
            invalidAttributes = _setBit(invalidAttributes, i);
            console.logBytes8(invalidAttributes);

            TDQuote memory tdQuote = _createTDQuote(invalidAttributes);

            vm.expectRevert(QuoteVerifier.TDReport_InDebugMode.selector);
            QuoteVerifier.ensureTDIsNotInDebugMode(tdQuote);
        }
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_ensureTDIsNotInDebugMode_InvalidBit29() public {
        bytes8 invalidAttributes = bytes8(0);
        invalidAttributes = _setBit(invalidAttributes, 29);
        console.logBytes8(invalidAttributes);

        TDQuote memory tdQuote = _createTDQuote(invalidAttributes);

        vm.expectRevert(QuoteVerifier.TDReport_InDebugMode.selector);
            QuoteVerifier.ensureTDIsNotInDebugMode(tdQuote);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_ensureTDIsNotInDebugMode_InvalidBits32to62() public {
        // Test each bit from 32 to 62
        for (uint8 i = 32; i <= 62; i++) {
            bytes8 invalidAttributes = bytes8(0);
            invalidAttributes = _setBit(invalidAttributes, i);

            TDQuote memory tdQuote = _createTDQuote(invalidAttributes);

            vm.expectRevert(QuoteVerifier.TDReport_InDebugMode.selector);
            QuoteVerifier.ensureTDIsNotInDebugMode(tdQuote);
        }
    }

    function _setBit(bytes8 value, uint8 bit) internal pure returns (bytes8) {
        if (bit % 8 / 4 == 0) {
            bit += 4;
        } else {
            bit -= 4;
        }
        return bytes8(uint64(uint64(value) | (1 << (63 - bit))));
    }

    function _createTDQuote(bytes8 attributes) internal pure returns (TDQuote memory) {
        bytes memory zero = new bytes(0);
        return TDQuote({
                TDATTRIBUTES: attributes,
                TEE_TCB_SVN: bytes16(0),
                MRSEAM: zero,
                MRSIGNERSEAM: zero,
                SEAMATTRIBUTES: bytes8(0),
                XFAM: bytes8(0),
                MRTD: zero,
                MRCONFIGID: zero,
                MROWNER: zero,
                MROWNERCONFIG: zero,
                RTMR0: zero,
                RTMR1: zero,
                RTMR2: zero,
                RTMR3: zero,
                REPORT_DATA1: bytes32(0),
                REPORT_DATA2: bytes32(0),
                USER_DATA: bytes20(0)
            });
    }
}
