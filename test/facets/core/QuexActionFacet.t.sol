// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Vm.sol";
import "@solidstate/contracts/cryptography/ECDSA.sol";
import "@solidstate/contracts/interfaces/IERC2535DiamondCutInternal.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";
import {Flow, IFlowRegistry} from "../../../contracts/interfaces/core/IFlowRegistry.sol";
import {IOraclePool} from "../../../contracts/interfaces/core/IOraclePool.sol";
import {IQuexMonetary} from "../../../contracts/interfaces/core/IQuexMonetary.sol";
import {ITrustDomainRegistry} from "../../../contracts/interfaces/core/ITrustDomainRegistry.sol";
import {IdType, DataItem, OracleMessage, ETHSignature, IQuexActionRegistry} from "../../../contracts/interfaces/core/IQuexActionRegistry.sol";
import {QuexActionFacet} from "../../../contracts/facets/actions/QuexActionFacet.sol";
import {IQuexActionFacet} from "../../../contracts/facets/actions/IQuexActionFacet.sol";
import {QuexDiamond} from "../../../contracts/diamond/QuexDiamond.sol";
import {QuexRoles} from "../../../contracts/QuexRoles.sol";

abstract contract QuexActionFacetTestBase is Test {
    QuexDiamond internal diamond;
    IQuexActionFacet internal testObject;
    address internal oraclePoolAddress = address(100);
    address internal consumerAddress = address(200);
    Vm.Wallet internal manager = vm.createWallet("manager");
    bytes4 internal callbackSignature = 0x12345678;
    uint256 internal constant actionId = 15;
    uint256 internal constant flowId = 111;
    Flow internal flow = Flow(100, actionId, oraclePoolAddress, consumerAddress, callbackSignature);

    uint256 internal constant unknownFlowId = 2;

    uint256 internal constant quexFee = 100;
    uint256 internal constant oraclePoolFee = 150;

    uint256 internal constant pastTimeSkew = 30 * 60;
    uint256 internal constant futureTimeSkew = 30;

    function setUp() public virtual {
        diamond = new QuexDiamond();
        diamond.init(address(this));
        diamond.grantRole(QuexRoles.Manager, manager.addr);
        QuexActionFacet t = new QuexActionFacet();
        IERC2535DiamondCutInternal.FacetCut[] memory cuts = new IERC2535DiamondCutInternal.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](9);

        selectors[0] = QuexActionFacet.createRequest.selector;
        selectors[1] = QuexActionFacet.getRequestFee.selector;
        selectors[2] = QuexActionFacet.pushData.selector;
        selectors[3] = QuexActionFacet.getQuexGas.selector;
        selectors[4] = QuexActionFacet.setQuexGas.selector;
        selectors[5] = QuexActionFacet.fulfillRequest.selector;
        selectors[6] = QuexActionFacet.setTimeSkew.selector;
        selectors[7] = QuexActionFacet.getTimeSkew.selector;
        selectors[8] = QuexActionFacet.getRequest.selector;

        cuts[0] = IERC2535DiamondCutInternal.FacetCut({
            target: address(t),
            action: IERC2535DiamondCutInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        diamond.diamondCut(cuts, address(0), "");
        testObject = IQuexActionFacet(address(diamond));

        vm.txGasPrice(1000);
        vm.mockCall(address(diamond), abi.encodeWithSelector(IFlowRegistry.getFlow.selector, flowId), abi.encode(flow));

        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(IFlowRegistry.getFlow.selector, unknownFlowId),
            abi.encode(Flow(0, 0, address(0), address(0), 0x00000000))
        );

        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(IQuexMonetary.getQuexFee.selector),
            abi.encode(quexFee)
        );

        vm.mockCall(
            oraclePoolAddress,
            abi.encodeWithSelector(IOraclePool.getActionFee.selector),
            abi.encode(oraclePoolFee)
        );

        vm.label(oraclePoolAddress, "OraclePool");
        vm.label(consumerAddress, "Consumer");
    }
}

contract QuexActionFacetTestDataBase is QuexActionFacetTestBase {
    using ECDSA for bytes32;

    struct TDTestData {
        uint256 privateKey;
        address tdAddress;
        uint256 tdId;
    }

    TDTestData internal TD_validInQuex_inOraclePool;
    TDTestData internal TD_validInQuex_notInOraclePool;
    TDTestData internal TD_notValidInQuex_inOraclePool;
    TDTestData internal TD_notValidInQuex_notInOraclePool;

    address internal quexTreasury = address(300);
    address internal oraclePoolTreasury = address(400);

    function setUp() public override virtual {
        QuexActionFacetTestBase.setUp();

        uint256 privateKey1 = 0x123abc;
        TD_validInQuex_inOraclePool = TDTestData(privateKey1, vm.addr(privateKey1) ,1);

        uint256 privateKey2 = 0x987fed;
        TD_validInQuex_notInOraclePool = TDTestData(privateKey2, vm.addr(privateKey2), 2);

        uint256 privateKey3 = 0x112233;
        TD_notValidInQuex_inOraclePool = TDTestData(privateKey3, vm.addr(privateKey3), 3);

        uint256 privateKey4 = 0xaabbcc;
        TD_notValidInQuex_notInOraclePool = TDTestData(privateKey4, vm.addr(privateKey4), 4);

        vm.label(quexTreasury, "QuexTreasury");
        vm.label(oraclePoolTreasury, "OraclePoolTreasury");

        // mock ITrustDomainRegistry.getTDSignerAddress
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(ITrustDomainRegistry.getTDSignerAddress.selector, TD_validInQuex_inOraclePool.tdId),
            abi.encode(TD_validInQuex_inOraclePool.tdAddress)
        );
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(ITrustDomainRegistry.getTDSignerAddress.selector, TD_validInQuex_notInOraclePool.tdId),
            abi.encode(TD_validInQuex_notInOraclePool.tdAddress)
        );
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(ITrustDomainRegistry.getTDSignerAddress.selector, TD_notValidInQuex_inOraclePool.tdId),
            abi.encode(TD_notValidInQuex_inOraclePool.tdAddress)
        );
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(ITrustDomainRegistry.getTDSignerAddress.selector, TD_notValidInQuex_notInOraclePool.tdId),
            abi.encode(TD_notValidInQuex_notInOraclePool.tdAddress)
        );

        // mock ITrustDomainRegistry.isTDValid
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(ITrustDomainRegistry.isTDValid.selector, TD_validInQuex_inOraclePool.tdId),
            abi.encode(true)
        );
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(ITrustDomainRegistry.isTDValid.selector, TD_validInQuex_notInOraclePool.tdId),
            abi.encode(true)
        );
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(ITrustDomainRegistry.isTDValid.selector),
            abi.encode(false)
        );

        // mock IOraclePool.isInPool
        vm.mockCall(
            address(oraclePoolAddress),
            abi.encodeWithSelector(IOraclePool.isInPool.selector, TD_validInQuex_inOraclePool.tdId),
            abi.encode(true)
        );
        vm.mockCall(
            address(oraclePoolAddress),
            abi.encodeWithSelector(IOraclePool.isInPool.selector, TD_notValidInQuex_inOraclePool.tdId),
            abi.encode(true)
        );
        vm.mockCall(
            address(oraclePoolAddress),
            abi.encodeWithSelector(IOraclePool.isInPool.selector),
            abi.encode(false)
        );

        // mock quex treasury
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(IQuexMonetary.getTreasury.selector),
            abi.encode(quexTreasury)
        );

        // mock oracle pool treasury
        vm.mockCall(
            address(oraclePoolAddress),
            abi.encodeWithSelector(IOraclePool.getTreasury.selector),
            abi.encode(oraclePoolTreasury)
        );
    }

    function _signOracleMessage(
        OracleMessage memory oracleMessage,
        TDTestData memory tdData
    ) internal returns (ETHSignature memory ethSignature) {
        vm.startPrank(tdData.tdAddress);
        bytes32 messageHash = keccak256(abi.encode(oracleMessage)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(tdData.privateKey, messageHash);
        vm.stopPrank();
        return ETHSignature(r, s, v);
    }

    function _mockSuccessfulCallback(uint256 id, DataItem memory dataItem, IdType idType) internal {
        vm.mockCall(
            consumerAddress,
            abi.encodeWithSelector(callbackSignature, id, dataItem, idType),
            abi.encode()
        );
    }

    function _mockRevertedCallback(uint256 id, DataItem memory dataItem, IdType idType) internal {
        vm.mockCallRevert(
            consumerAddress,
            abi.encodeWithSelector(callbackSignature, id, dataItem, idType),
            abi.encode("REVERT_MESSAGE")
        );
    }
}
