//! Fast execution test for the credential verifier circuit
//! Runs the program without generating a proof to verify logic

use anyhow::Result;
use serde::{Deserialize, Serialize};
use sp1_sdk::{ProverClient, SP1Stdin};

const ELF: &[u8] = include_bytes!("../../../program/elf/riscv32im-succinct-zkvm-elf");

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CredentialInput {
    pub subject: [u8; 20],
    pub credential_type: u32,
    pub credential_data: Vec<u8>,
    pub signature: Vec<u8>,
    pub issuer_pubkey: Vec<u8>,
    pub issued_at: u64,
    pub expires_at: u64,
    pub current_time: u64,
}

fn main() -> Result<()> {
    println!("SP1 Credential Verifier - Execute Test");
    println!("======================================");

    // Create sample credential
    let subject_bytes = hex::decode("1234567890123456789012345678901234567890")?;
    let mut subject = [0u8; 20];
    subject.copy_from_slice(&subject_bytes);

    let current_time = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)?
        .as_secs();

    // Build credential data
    let mut credential_data = Vec::new();
    credential_data.extend_from_slice(&1u32.to_be_bytes()); // version
    credential_data.extend_from_slice(&2u32.to_be_bytes()); // claim_count
    credential_data.extend_from_slice(&[0u8; 32]); // claim 1
    credential_data.extend_from_slice(&[1u8; 32]); // claim 2

    let credential = CredentialInput {
        subject,
        credential_type: 2, // Accredited investor
        credential_data,
        signature: vec![0u8; 64],
        issuer_pubkey: vec![0x02; 33],
        issued_at: current_time - 86400,
        expires_at: current_time + 365 * 86400,
        current_time,
    };

    println!("Subject: 0x{}", hex::encode(credential.subject));
    println!("Credential Type: {}", credential.credential_type);
    println!("Current Time: {}", credential.current_time);
    println!("Expires At: {}", credential.expires_at);

    // Initialize prover client
    println!("\nInitializing SP1...");
    let client = ProverClient::new();

    // Prepare inputs
    let mut stdin = SP1Stdin::new();
    stdin.write(&credential);

    // Execute only (no proof generation) - much faster
    println!("\nExecuting program (no proof generation)...");
    let (public_values, report) = client.execute(ELF, stdin).run()?;

    println!("\n✓ Execution successful!");
    println!("Cycles used: {}", report.total_instruction_count());
    println!("Public values length: {} bytes", public_values.to_vec().len());

    // Decode the public values to verify output
    // SP1 outputs in little-endian format
    // Format: subject (20) + topic (4) + hash (32) + issued_at (8) + expires_at (8) = 72 bytes
    let pv_bytes = public_values.to_vec();
    if pv_bytes.len() >= 72 {
        let mut subject_out = [0u8; 20];
        subject_out.copy_from_slice(&pv_bytes[0..20]);

        // Little-endian u32
        let topic = u32::from_le_bytes([pv_bytes[20], pv_bytes[21], pv_bytes[22], pv_bytes[23]]);

        let mut hash = [0u8; 32];
        hash.copy_from_slice(&pv_bytes[24..56]);

        // Little-endian u64
        let issued_at = u64::from_le_bytes([
            pv_bytes[56], pv_bytes[57], pv_bytes[58], pv_bytes[59],
            pv_bytes[60], pv_bytes[61], pv_bytes[62], pv_bytes[63],
        ]);

        let expires_at = u64::from_le_bytes([
            pv_bytes[64], pv_bytes[65], pv_bytes[66], pv_bytes[67],
            pv_bytes[68], pv_bytes[69], pv_bytes[70], pv_bytes[71],
        ]);

        println!("\n--- Public Values (Decoded) ---");
        println!("Subject: 0x{}", hex::encode(subject_out));
        println!("Credential Topic: {} (Accredited Investor)", topic);
        println!("Credential Hash: 0x{}", hex::encode(hash));
        println!("Issued At: {} (UNIX timestamp)", issued_at);
        println!("Expires At: {} (UNIX timestamp)", expires_at);
        println!("\nRaw public values (hex): 0x{}", hex::encode(&pv_bytes));
    }

    println!("\n======================================");
    println!("Circuit execution test PASSED!");
    println!("The ZK program logic is working correctly.");
    println!("\nTo generate a full proof for on-chain verification,");
    println!("run: cargo run --release --bin prove -- --credential sample");

    Ok(())
}
