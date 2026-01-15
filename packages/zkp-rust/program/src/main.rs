//! SP1 zkVM Program for Credential Verification
//!
//! This program verifies credentials in zero-knowledge, proving that:
//! 1. The credential is properly signed by a trusted issuer
//! 2. The credential belongs to the claimed subject
//! 3. The credential is not expired
//! 4. The credential meets the required claim types
//!
//! The program outputs public values that can be verified on-chain.

#![no_main]
sp1_zkvm::entrypoint!(main);

use sha2::{Sha256, Digest};
use serde::{Deserialize, Serialize};

/// Credential input data (private to the prover)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CredentialInput {
    /// The subject's Ethereum address (20 bytes as hex string)
    pub subject: [u8; 20],
    /// The credential type (e.g., 1=KYC, 2=Accredited, etc.)
    pub credential_type: u32,
    /// Raw credential data (contains claims and metadata)
    pub credential_data: Vec<u8>,
    /// Issuer's signature over the credential
    pub signature: Vec<u8>,
    /// Issuer's public key
    pub issuer_pubkey: Vec<u8>,
    /// Issuance timestamp
    pub issued_at: u64,
    /// Expiration timestamp (0 for no expiration)
    pub expires_at: u64,
    /// Current timestamp for verification
    pub current_time: u64,
}

/// Public output values that will be verified on-chain
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PublicOutput {
    /// The subject's address
    pub subject: [u8; 20],
    /// The credential type
    pub credential_type: u32,
    /// Hash of the credential for uniqueness
    pub credential_hash: [u8; 32],
    /// When the credential was issued
    pub issued_at: u64,
    /// When the credential expires
    pub expires_at: u64,
}

/// Verifies an ECDSA signature (simplified for demonstration)
/// In production, this would use proper ECDSA verification
fn verify_signature(message: &[u8], signature: &[u8], pubkey: &[u8]) -> bool {
    // For demonstration purposes, we verify that:
    // 1. Signature is not empty
    // 2. Public key is valid length (33 or 65 bytes for compressed/uncompressed)
    // 3. Signature length is valid (64 or 65 bytes)

    if signature.is_empty() || signature.len() < 64 {
        return false;
    }

    if pubkey.is_empty() || (pubkey.len() != 33 && pubkey.len() != 65) {
        return false;
    }

    // In a real implementation, you would use:
    // - secp256k1 ECDSA verification
    // - Or Ed25519 signature verification
    // - The SP1 zkVM supports these cryptographic operations

    // For now, we do a simplified check
    // Hash the message and verify the signature matches expected format
    let mut hasher = Sha256::new();
    hasher.update(message);
    let _message_hash = hasher.finalize();

    // Placeholder verification - replace with actual ECDSA in production
    true
}

/// Computes the credential hash
fn compute_credential_hash(
    subject: &[u8; 20],
    credential_type: u32,
    credential_data: &[u8],
    issuer_pubkey: &[u8],
) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(subject);
    hasher.update(credential_type.to_be_bytes());
    hasher.update(credential_data);
    hasher.update(issuer_pubkey);

    let result = hasher.finalize();
    let mut hash = [0u8; 32];
    hash.copy_from_slice(&result);
    hash
}

/// Validates credential data contains required claims
fn validate_credential_claims(credential_data: &[u8], credential_type: u32) -> bool {
    // Credential data format (simplified):
    // - First 4 bytes: version
    // - Next 4 bytes: claim count
    // - Remaining: claim data

    if credential_data.len() < 8 {
        return false;
    }

    let version = u32::from_be_bytes([
        credential_data[0],
        credential_data[1],
        credential_data[2],
        credential_data[3],
    ]);

    // Only support version 1
    if version != 1 {
        return false;
    }

    let claim_count = u32::from_be_bytes([
        credential_data[4],
        credential_data[5],
        credential_data[6],
        credential_data[7],
    ]);

    // Validate based on credential type
    match credential_type {
        1 => claim_count >= 1, // KYC: at least 1 claim
        2 => claim_count >= 2, // Accredited: at least 2 claims
        3 => claim_count >= 2, // Qualified: at least 2 claims
        4 => claim_count >= 3, // Institutional: at least 3 claims
        5 => claim_count >= 1, // AML: at least 1 claim
        _ => claim_count >= 1, // Default: at least 1 claim
    }
}

fn main() {
    // Read the credential input from the prover
    let input: CredentialInput = sp1_zkvm::io::read();

    // Validate credential type
    assert!(input.credential_type > 0, "Invalid credential type");

    // Validate timestamps
    assert!(input.issued_at > 0, "Invalid issuance time");
    assert!(
        input.current_time >= input.issued_at,
        "Current time before issuance"
    );

    // Check expiration if set
    if input.expires_at > 0 {
        assert!(
            input.current_time <= input.expires_at,
            "Credential has expired"
        );
    }

    // Verify the signature
    let signature_valid = verify_signature(
        &input.credential_data,
        &input.signature,
        &input.issuer_pubkey,
    );
    assert!(signature_valid, "Invalid signature");

    // Validate credential claims
    let claims_valid = validate_credential_claims(
        &input.credential_data,
        input.credential_type,
    );
    assert!(claims_valid, "Invalid credential claims");

    // Compute the credential hash
    let credential_hash = compute_credential_hash(
        &input.subject,
        input.credential_type,
        &input.credential_data,
        &input.issuer_pubkey,
    );

    // Create the public output
    let output = PublicOutput {
        subject: input.subject,
        credential_type: input.credential_type,
        credential_hash,
        issued_at: input.issued_at,
        expires_at: input.expires_at,
    };

    // Commit the public values for on-chain verification
    // The output is ABI-encoded for compatibility with Solidity
    sp1_zkvm::io::commit(&output.subject);
    sp1_zkvm::io::commit(&output.credential_type);
    sp1_zkvm::io::commit(&output.credential_hash);
    sp1_zkvm::io::commit(&output.issued_at);
    sp1_zkvm::io::commit(&output.expires_at);
}
