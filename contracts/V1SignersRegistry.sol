// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
import "../interfaces/IV1QuoteVerifier.sol";
import "../interfaces/IV1SignersRegistry.sol";

contract V1SignersRegistry is IV1SignersRegistry {
    address QUOTE_VERIFIER;
    mapping (uint256 => address) td_to_signer;

    event SignerAdded(uint256 td_id, address signer);

    constructor(address _quote_verifier) {
        QUOTE_VERIFIER = _quote_verifier;
    }

    function addSigner(uint256 td_id) public {
        address addr = address(uint160(uint256(IV1QuoteVerifier(QUOTE_VERIFIER).getTD(td_id).REPORT_DATA1)));
        td_to_signer[td_id] = addr;
        emit SignerAdded(td_id, addr);
    }

    function getAddr(uint256 td_id) external view returns (address) {
        return td_to_signer[td_id];
    }
}
