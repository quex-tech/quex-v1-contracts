// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IP256Verifier {
    function ecdsaVerify(bytes32 messageHash, uint256 r, uint256 s, uint256[2] memory pubKey)
        external
        view
        returns (bool);
}
