// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract DecentralizedIdentity {
    
    struct Identity {
        string name;
        string metadataURI; // IPFS/Arweave hash containing identity data
        bool exists;
    }

    // user address => identity
    mapping(address => Identity) public identities;

    // user => verifier => verified?
    mapping(address => mapping(address => bool)) public attestations;

    // approved verifiers
    mapping(address => bool) public trustedVerifiers;

    address public owner;

    event IdentityCreated(address indexed user, string name);
    event IdentityUpdated(address indexed user);
    event VerifierAdded(address indexed verifier);
    event IdentityVerified(address indexed user, address indexed verifier);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyVerifier() {
        require(trustedVerifiers[msg.sender], "Not trusted verifier");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// Add trusted verifier
    function addVerifier(address verifier) external onlyOwner {
        trustedVerifiers[verifier] = true;
        emit VerifierAdded(verifier);
    }

    /// Create decentralized identity
    function createIdentity(
        string calldata name,
        string calldata metadataURI
    ) external {
        require(!identities[msg.sender].exists, "Identity already exists");

        identities[msg.sender] = Identity({
            name: name,
            metadataURI: metadataURI,
            exists: true
        });

        emit IdentityCreated(msg.sender, name);
    }

    /// Update identity metadata
    function updateIdentity(
        string calldata newName,
        string calldata newMetadataURI
    ) external {
        require(identities[msg.sender].exists, "Identity not found");

        identities[msg.sender].name = newName;
        identities[msg.sender].metadataURI = newMetadataURI;

        emit IdentityUpdated(msg.sender);
    }

    /// Verifier attests identity
    function verifyIdentity(address user) external onlyVerifier {
        require(identities[user].exists, "Identity not found");

        attestations[user][msg.sender] = true;

        emit IdentityVerified(user, msg.sender);
    }

    /// Check if a verifier verified a user
    function isVerifiedBy(
        address user,
        address verifier
    ) external view returns (bool) {
        return attestations[user][verifier];
    }

    /// Check total trust status
    function hasTrustedVerification(
        address user,
        address verifier
    ) external view returns (bool) {
        return trustedVerifiers[verifier] &&
               attestations[user][verifier];
    }
}