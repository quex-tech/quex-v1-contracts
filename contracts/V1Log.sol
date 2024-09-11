// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IV1QuexLogWriter.sol";
import "../interfaces/IV1QuexLogReader.sol";
import "../interfaces/IV1LogPolicies.sol";
import "../interfaces/IV1SignersRegistry.sol";

struct StrippedData {
    int256 value;
    uint256 timestamp;
}

contract V1Log is Ownable, IV1QuexLogWriter, IV1QuexLogReader {
    IV1LogPolicies LOG_POLICIES;
    IV1SignersRegistry SIGNERS_REGISTRY;
    mapping (bytes32 => mapping (uint256 => StrippedData)) data_items;
    mapping (bytes32 => uint256) curr_ids;
    bytes32[] feeds;
    uint256 constant MAX_LAG = 30 minutes;

    event DataRecorded(uint256 td_id, DataItem data, uint256 id);

    constructor (
        address initialOwner, 
        address _log_policies, 
        address _signers_registry
    ) Ownable(initialOwner) {
        LOG_POLICIES = IV1LogPolicies(_log_policies);
        SIGNERS_REGISTRY = IV1SignersRegistry(_signers_registry);
    }

    function getLastData(bytes32 feedID) public view returns (uint256 id, int256 value, uint256 timestamp) {
        uint256 curr_id = curr_ids[feedID];
        return (curr_id, data_items[feedID][curr_id].value, data_items[feedID][curr_id].timestamp);
    }

    function setLogPoliciesContract(address log_policies) public onlyOwner {
        LOG_POLICIES = IV1LogPolicies(log_policies);
    }

    function addFeed(bytes32 feedID) public onlyOwner {
        feeds.push(feedID);
    }

    function getFeeds() public view returns (bytes32[] memory) {
        return feeds;
    }

    function getDataByID(bytes32 feedID, uint id) public view returns (uint256, int256, uint256) {
        return (id, data_items[feedID][id].value, data_items[feedID][id].timestamp);
    }

    function verifySignature(address signer, bytes memory message, uint8 v, bytes32 r, bytes32 s) internal pure
    returns (bool) {
        bytes32 _messageHash = keccak256(message);
        bytes32 _ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
        return (ecrecover(_ethSignedMessageHash, v, r, s) == signer);
    }

    function pushData(DataItem memory data_item, uint256 td_id, uint8 v, bytes32 r, bytes32 s) public {
        require(LOG_POLICIES.isAllowed(td_id), "TD is not allowed by V1LogPolicies Contract");
        bytes memory message = abi.encode(data_item);
        address signer = SIGNERS_REGISTRY.getAddr(td_id);
        require(verifySignature(signer, message, v, r, s), "Signature verification failed"); 
        uint256 curr_id = curr_ids[data_item.feedID];
        uint256 latest_timestamp = data_items[data_item.feedID][curr_id].timestamp;
        require(data_item.timestamp > latest_timestamp, "Out-of-order write attempt");
        require((block.timestamp - MAX_LAG < data_item.timestamp) && (block.timestamp + MAX_LAG > data_item.timestamp), 
                "Time skew too high");
        curr_id++;
        curr_ids[data_item.feedID] = curr_id;
        data_items[data_item.feedID][curr_id] = StrippedData(data_item.value, data_item.timestamp);
        emit DataRecorded(td_id, data_item, curr_id);
    }
}
