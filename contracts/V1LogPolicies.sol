// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IV1LogPolicies.sol";

contract V1LogPolicies is IV1LogPolicies, Ownable {
    mapping(uint256 => uint) trusted_tds;

    constructor (address initialOwner) Ownable (initialOwner) {
    }

    function addTD(uint256 td_id) public onlyOwner {
        trusted_tds[td_id] = 1;
    }

    function removeTD(uint256 td_id) public onlyOwner {
        trusted_tds[td_id] = 0;
    }

    function isAllowed(uint256 td_id) public view returns (bool) {
        return (trusted_tds[td_id] == 1);
    }
}
