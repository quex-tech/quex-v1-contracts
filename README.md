# quex-v1-contracts

## Description

This repository contains the set of V1 Quex smart-contracts

## Rationale

Quex provides the set of oracles for EVM-compatible blockchains utilizing Trusted Execution Environment (TEE)
attestation. The current set of contracts performs on-chain verification of Intel Trusted Domain Extensions (TDX)
quotes together with the verification of the certificate chain up to the Intel SGX root CA. The software inside TD
issues the attestation quote containing the public key (more precisely, ETH address) generated inside the domain.

This quote is signed by standard Intel DCAP enclave and registered on-chain together with all the necessary
certificates. From that point, the data signed with the corresponding private key can be set as trusted for the
particular `V1QuexLog` contract.

## High-Level Overview

### `P256Verifier.sol`
The contract contains elliptic curve arithmetics and provides functionality for ECDSA verification on P256 curve.
Borrowed from [daimo-eth](https://github.com/daimo-eth/p256-verifier).

### `V1CertificateVerifier.sol`
The contract supplies the set of interfaces for X.509 certificate verification. The verified certificates are stored
on-chain for future use of their public keys and possibility of revocation. According to [Intel SGX PCK Certificate and
Certificate Revocation List Profile Specification, rev
1.5](https://api.trustedservices.intel.com/documents/Intel_SGX_PCK_Certificate_CRL_Spec-1.5.pdf), the certificate tree
is of fixed depth, so no recursion is encoded, and the interfaces are separate for root key, platform key and PCK.

The contract requires access to `P256Verifier` as ECDSA verification back-end.

### `V1QuoteVerifier.sol`
The contract performs verification and storage of DCAP-attested TDX quotes. The structure of the quote and possible
field values can be found
[here](https://download.01.org/intel-sgx/latest/dcap-latest/linux/docs/Intel_TDX_DCAP_Quoting_Library_API.pdf). The
contract requires access to `V1CertificateVerifier` to retrieve verified PCKs, and to `P256Verifier` as ECDSA
verification back-end. During the attestation process, two parts of code are executed inside TEE (one is Intel
attesting enclave, residing in SGX, and another one is trusted domain to be attested). They utilize different subsets of
Intel architecture, and operate two types of quotes (SGX and TDX). Therefore, quote upload and verification is split
in two stages. The first is attesting enclave quote verification using public PCK from `V1CertificateVerifier`. The second is TDX quote verification using the attesting enclave report from the previous stage. TDX report structure is also stored for future use. For the storage and usage convenience, `REPORT_DATA` field of TDX quote is split in two 32-byte parts.

Note that contracts `P256Verifier`, `V1CertificateVerifier` and `V1QuoteVerifier` are agnostic of Quex machinery.

### `V1SignersRegistry.sol`
Quex could attest TD keys by submitting their public counterparts via `REPORT_DATA` field. EVM natively provides
signature verification by `erecover` which returns ETH address signature belongs to. Hence, Quex TDs submit ETH
addresses corresponding to public keys instead of public keys themselves. `V1SignersRegistry` extracts `REPORT_DATA`
from `V1QuoteVerifier` by the ID of Trusted Domain, re-interprets it as an address, and stores in a separate mapping.
The rationale behind splitting it from `V1QuoteVerifier` is to keep Quex-related logic separate from purely
Intel-related (or general X.509).

### `V1LogPolicies.sol`
The contract determines the policies applied by the log owner for giving write access to the log. The idea is that one
log may wish to allow data writes from several TDs. Some of the potential scenarios are:
+ Give write permissions to a single known enclave
+ Give write permissions to several known enclaves
+ Give write permissions to any enclave containing the specific code, which is controlled by `MRTD` field of the quote
+ Give write access to any enclave with given `MRTD`, but with CPU being not older than some model, run in production
  mode and having specific configuration (matching fields in PCK certificate extensions and TD quote)

For now, it only contains fiducial logic with filtering by ID.

### `V1Log.sol`
Storage for the off-chain data. Every received data item must be signed by TD. The contract verifies that TD has
write permissions by calling `isAllowed` method of `V1LogPolicies`, verifies the signature, and stores the data. For API
key management and query efficiency, single TD can provide several data feeds signed with the same key. For thet reason,
`feedID` is included in signed data, and single log contract can manage several feeds (given that the same log policies
are applied to all of them).
