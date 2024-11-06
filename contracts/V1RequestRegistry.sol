// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IV1RequestLogic.sol";
import "../interfaces/IV1RequestRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract V1RequestRegistry is IV1RequestRegistry, Ownable {
    struct Request {
        bytes32 feedId;
        address callbackAddress;
        bytes4 callbackMethod;
        uint32 callbackGasLimit;
        uint256 price;
    }

    IV1RequestLogic internal requestLogic;

    mapping(bytes32 => Request) public requests;

    constructor(address initialOwner, address requestLogicAddress) Ownable(initialOwner) {
        requestLogic = IV1RequestLogic(requestLogicAddress);
    }

    function sendRequest(
        bytes32 feedId,
        address callbackAddress,
        bytes4 callbackMethod,
        uint32 callbackGasLimit
    ) external payable returns (bytes32 requestId, uint256 requestPrice) {
        requestPrice = requestLogic.calculateRequestPrice(callbackGasLimit);
        require(msg.value >= requestPrice, "Insufficient value sent");

        requestId = requestLogic.sendRequest(feedId);

        requests[requestId] = Request(
            feedId,
            callbackAddress,
            callbackMethod,
            callbackGasLimit,
            requestPrice
        );

        if (msg.value > requestPrice) {
            payable(msg.sender).transfer(msg.value - requestPrice);
        }

        return (requestId, requestPrice);
    }

    function processResponse(
        bytes32 requestId,
        RequestResult memory requestResult
    ) external {
        Request memory request = requests[requestId];
        requestLogic.processResponse{value: request.price}(
            requestId,
            request.feedId,
            request.callbackAddress,
            request.callbackMethod,
            request.callbackGasLimit,
            requestResult,
            payable(msg.sender)
        );
        delete requests[requestId];
    }

    function changeRequestLogic(address newContractAddress) external onlyOwner {
        requestLogic = IV1RequestLogic(newContractAddress);
    }
}
