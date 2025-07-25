// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {Base64} from "solady/src/utils/Base64.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {DataItem, OracleMessage} from "../../contracts/interfaces/core/IQuexActionRegistry.sol";

contract ModelEncodingTest is Test {
    using stdJson for string;

    function test_oracleMessageEncoding() public {
        string memory path = "test/testdata/test-vectors/oracle_message_test_vectors.json";
        string memory json = vm.readFile(path);
        console.log("Got test vector:", json);

        for (uint256 index = 0; index <= 0; ++index) {
            string memory vectorPath = string.concat(".vectors[", vm.toString(index), "]");

            string memory actionIdBase64 = json.readString(string.concat(vectorPath, ".msg.action_id"));
            string memory dataValueBase64 = json.readString(string.concat(vectorPath, ".msg.data_item.value"));
            address relayer = json.readAddress(string.concat(vectorPath, ".msg.relayer"));
            uint256 timestamp = json.readUint(string.concat(vectorPath, ".msg.data_item.timestamp"));
            uint256 error = json.readUint(string.concat(vectorPath, ".msg.data_item.error"));

            bytes32 actionId = bytes32(Base64.decode(actionIdBase64));
            bytes memory dataValue = Base64.decode(dataValueBase64);

            OracleMessage memory message = OracleMessage({
                actionId: uint256(actionId),
                dataItem: DataItem({timestamp: timestamp, error: error, value: dataValue}),
                relayer: relayer
            });
            bytes memory encoded = abi.encode(message);
            console.logBytes(encoded);

            string memory expectedEncodedBase64 = json.readString(string.concat(vectorPath, ".bytes"));
            bytes memory expectedEncoded = Base64.decode(expectedEncodedBase64);

            assertEq(encoded, expectedEncoded, "Encoded bytes do not match expected test vector");
        }
    }
}