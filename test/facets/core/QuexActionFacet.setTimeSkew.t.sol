// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {QuexActionFacetTestBase} from "./QuexActionFacet.t.sol";
import "forge-std/Vm.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract QuexActionFacet_setTimeSkew is QuexActionFacetTestBase {
    function testFuzz_SetsTimeSkew(uint256 pastTimeSkew, uint256 futureTimeSkew) public {
        vm.prank(manager.addr);
        testObject.setTimeSkew(pastTimeSkew, futureTimeSkew);

        (uint256 actualPastTimeSkew, uint256 actualFutureTimeSkew) = testObject.getTimeSkew();
        vm.assertEq(pastTimeSkew, actualPastTimeSkew);
        vm.assertEq(futureTimeSkew, actualFutureTimeSkew);
    }

    function test_RevertsIf_CallerIsNotManager() public {
        vm.expectRevert();
        testObject.setTimeSkew(100, 100);
    }
}
