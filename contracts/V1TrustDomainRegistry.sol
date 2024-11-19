// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IV1TrustDomainRegistry.sol";
import "../interfaces/IV1QuoteVerifier.sol";

contract V1TrustDomainRegistry is IV1TrustDomainRegistry, Ownable {
    mapping(uint256 => uint) trustedTDs;
    mapping(uint256 => address) signerAddresses;

    IV1QuoteVerifier internal quoteVerifier;

    constructor(address initialOwner, address quoteVerifierAddress) Ownable(initialOwner) {
        quoteVerifier = IV1QuoteVerifier(quoteVerifierAddress);
    }

    function addQE(
        QEReport memory qeReport,
        uint256 platformSerial,
        uint256 pckSerial,
        uint256 r,
        uint256 s
    ) public returns (uint256) {
        return quoteVerifier.addQE(qeReport, platformSerial, pckSerial, r, s);
    }

    function addTD(
        TDQuote memory tdQuote,
        uint qeId,
        uint256 x,
        uint256 y,
        bytes32 authenticationData,
        uint256 r,
        uint256 s
    ) public returns (uint256) {
        uint256 tdId = quoteVerifier.addTD(tdQuote, qeId, x, y, authenticationData, r, s);
        bytes memory publicKey = abi.encodePacked(tdQuote.REPORT_DATA1, tdQuote.REPORT_DATA2);
        address signerAddress = _convertPublicKeyToAddress(publicKey);
        signerAddresses[tdId] = signerAddress;
        return tdId;
    }

    function enableTD(uint256 tdId) public onlyOwner {
        trustedTDs[tdId] = 1;
    }

    function disableTD(uint256 tdId) public onlyOwner {
        trustedTDs[tdId] = 0;
    }

    function isAllowed(uint256 tdId) public view returns (bool) {
        return (trustedTDs[tdId] == 1);
    }

    function getSignerAddress(uint256 tdId) public view returns (address) {
        return signerAddresses[tdId];
    }

    function changeQuoteVerifier(address newContractAddress) external onlyOwner {
        quoteVerifier = IV1QuoteVerifier(newContractAddress);
    }

    function _convertPublicKeyToAddress(bytes memory publicKey) private pure returns (address) {
        require(publicKey.length == 64, "Invalid public key length");
        bytes32 hash = keccak256(publicKey);
        return address(uint160(uint256(hash)));
    }
}
