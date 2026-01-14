import { ethers } from "hardhat";

/**
 * Deployment script for Credence contracts
 *
 * Deploys the following contracts in order:
 * 1. ClaimTopicsRegistry
 * 2. TrustedIssuersRegistry
 * 3. IdentityRegistryStorage
 * 4. IdentityRegistry
 * 5. ModularCompliance
 * 6. VerifiToken
 * 7. SP1CredentialVerifier
 * 8. CredentialSBT
 * 9. RWAGate
 * 10. RWAPool
 */

interface DeployedContracts {
  claimTopicsRegistry: string;
  trustedIssuersRegistry: string;
  identityRegistryStorage: string;
  identityRegistry: string;
  modularCompliance: string;
  verifiToken: string;
  sp1CredentialVerifier: string;
  credentialSBT: string;
  rwaGate: string;
  rwaPool: string;
}

async function main(): Promise<DeployedContracts> {
  const [deployer] = await ethers.getSigners();

  console.log("=".repeat(60));
  console.log("Credence Deployment Script");
  console.log("=".repeat(60));
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Network: ${(await ethers.provider.getNetwork()).name}`);
  console.log(`Chain ID: ${(await ethers.provider.getNetwork()).chainId}`);
  console.log("=".repeat(60));

  // Deploy ClaimTopicsRegistry
  console.log("\n1. Deploying ClaimTopicsRegistry...");
  const ClaimTopicsRegistry = await ethers.getContractFactory("ClaimTopicsRegistry");
  const claimTopicsRegistry = await ClaimTopicsRegistry.deploy();
  await claimTopicsRegistry.waitForDeployment();
  const claimTopicsRegistryAddress = await claimTopicsRegistry.getAddress();
  console.log(`   ClaimTopicsRegistry deployed to: ${claimTopicsRegistryAddress}`);

  // Deploy TrustedIssuersRegistry
  console.log("\n2. Deploying TrustedIssuersRegistry...");
  const TrustedIssuersRegistry = await ethers.getContractFactory("TrustedIssuersRegistry");
  const trustedIssuersRegistry = await TrustedIssuersRegistry.deploy();
  await trustedIssuersRegistry.waitForDeployment();
  const trustedIssuersRegistryAddress = await trustedIssuersRegistry.getAddress();
  console.log(`   TrustedIssuersRegistry deployed to: ${trustedIssuersRegistryAddress}`);

  // Deploy IdentityRegistryStorage
  console.log("\n3. Deploying IdentityRegistryStorage...");
  const IdentityRegistryStorage = await ethers.getContractFactory("IdentityRegistryStorage");
  const identityRegistryStorage = await IdentityRegistryStorage.deploy();
  await identityRegistryStorage.waitForDeployment();
  const identityRegistryStorageAddress = await identityRegistryStorage.getAddress();
  console.log(`   IdentityRegistryStorage deployed to: ${identityRegistryStorageAddress}`);

  // Deploy IdentityRegistry
  console.log("\n4. Deploying IdentityRegistry...");
  const IdentityRegistry = await ethers.getContractFactory("IdentityRegistry");
  const identityRegistry = await IdentityRegistry.deploy(
    trustedIssuersRegistryAddress,
    claimTopicsRegistryAddress,
    identityRegistryStorageAddress
  );
  await identityRegistry.waitForDeployment();
  const identityRegistryAddress = await identityRegistry.getAddress();
  console.log(`   IdentityRegistry deployed to: ${identityRegistryAddress}`);

  // Bind IdentityRegistry to Storage
  console.log("   Binding IdentityRegistry to Storage...");
  await identityRegistryStorage.bindIdentityRegistry(identityRegistryAddress);
  console.log("   IdentityRegistry bound to Storage");

  // Deploy ModularCompliance
  console.log("\n5. Deploying ModularCompliance...");
  const ModularCompliance = await ethers.getContractFactory("ModularCompliance");
  const modularCompliance = await ModularCompliance.deploy();
  await modularCompliance.waitForDeployment();
  const modularComplianceAddress = await modularCompliance.getAddress();
  console.log(`   ModularCompliance deployed to: ${modularComplianceAddress}`);

  // Deploy VerifiToken
  console.log("\n6. Deploying VerifiToken...");
  const VerifiToken = await ethers.getContractFactory("VerifiToken");
  const verifiToken = await VerifiToken.deploy(
    "Credence Security Token",
    "MVST",
    identityRegistryAddress,
    modularComplianceAddress,
    ethers.ZeroAddress // Token OnchainID (can be set later)
  );
  await verifiToken.waitForDeployment();
  const verifiTokenAddress = await verifiToken.getAddress();
  console.log(`   VerifiToken deployed to: ${verifiTokenAddress}`);

  // Bind token to compliance
  console.log("   Binding token to compliance...");
  await modularCompliance.bindToken(verifiTokenAddress);
  console.log("   Token bound to compliance");

  // Deploy SP1CredentialVerifier
  console.log("\n7. Deploying SP1CredentialVerifier...");
  // Use a placeholder SP1 verifier address for now
  // In production, this should be the actual SP1 verifier contract
  const placeholderSP1Verifier = "0x3B6041173B80E77f038f3F2C0f9744f04837185e"; // Sepolia SP1 Verifier
  const placeholderVKey = ethers.encodeBytes32String("placeholder_vkey");

  const SP1CredentialVerifier = await ethers.getContractFactory("SP1CredentialVerifier");
  const sp1CredentialVerifier = await SP1CredentialVerifier.deploy(
    placeholderSP1Verifier,
    placeholderVKey
  );
  await sp1CredentialVerifier.waitForDeployment();
  const sp1CredentialVerifierAddress = await sp1CredentialVerifier.getAddress();
  console.log(`   SP1CredentialVerifier deployed to: ${sp1CredentialVerifierAddress}`);

  // Deploy CredentialSBT
  console.log("\n8. Deploying CredentialSBT...");
  const CredentialSBT = await ethers.getContractFactory("CredentialSBT");
  const credentialSBT = await CredentialSBT.deploy(
    "Credence Credential",
    "MVC",
    "https://api.mantleverifi.io/metadata/"
  );
  await credentialSBT.waitForDeployment();
  const credentialSBTAddress = await credentialSBT.getAddress();
  console.log(`   CredentialSBT deployed to: ${credentialSBTAddress}`);

  // Deploy RWAGate
  console.log("\n9. Deploying RWAGate...");
  const RWAGate = await ethers.getContractFactory("RWAGate");
  const rwaGate = await RWAGate.deploy(
    identityRegistryAddress,
    credentialSBTAddress,
    sp1CredentialVerifierAddress
  );
  await rwaGate.waitForDeployment();
  const rwaGateAddress = await rwaGate.getAddress();
  console.log(`   RWAGate deployed to: ${rwaGateAddress}`);

  // Deploy RWAPool (using a mock USDC for testing)
  console.log("\n10. Deploying RWAPool...");
  // For testing, we'll use the token itself as the investment asset
  // In production, this would be USDC or another stablecoin
  const RWAPool = await ethers.getContractFactory("RWAPool");
  const rwaPool = await RWAPool.deploy(
    rwaGateAddress,
    verifiTokenAddress,
    verifiTokenAddress, // Using token as investment asset for demo
    "Credence RWA Pool",
    "MVRP",
    ethers.parseEther("1000000"), // 1M capacity
    ethers.parseEther("1") // 1:1 exchange rate
  );
  await rwaPool.waitForDeployment();
  const rwaPoolAddress = await rwaPool.getAddress();
  console.log(`   RWAPool deployed to: ${rwaPoolAddress}`);

  // Configure RWAGate
  console.log("\n11. Configuring RWAGate...");
  await rwaGate.whitelistPool(rwaPoolAddress);
  await rwaGate.configurePool(
    rwaPoolAddress,
    [1, 2], // Require KYC and Accredited credentials
    ethers.parseEther("100"), // Min investment 100 tokens
    ethers.parseEther("100000") // Max investment 100k tokens
  );
  console.log("   RWAPool whitelisted and configured");

  // Deploy compliance modules
  console.log("\n12. Deploying Compliance Modules...");

  const CountryRestrictModule = await ethers.getContractFactory("CountryRestrictModule");
  const countryRestrictModule = await CountryRestrictModule.deploy();
  await countryRestrictModule.waitForDeployment();
  const countryRestrictModuleAddress = await countryRestrictModule.getAddress();
  console.log(`   CountryRestrictModule deployed to: ${countryRestrictModuleAddress}`);

  const AccreditedInvestorModule = await ethers.getContractFactory("AccreditedInvestorModule");
  const accreditedInvestorModule = await AccreditedInvestorModule.deploy();
  await accreditedInvestorModule.waitForDeployment();
  const accreditedInvestorModuleAddress = await accreditedInvestorModule.getAddress();
  console.log(`   AccreditedInvestorModule deployed to: ${accreditedInvestorModuleAddress}`);

  // Add modules to compliance
  console.log("\n13. Configuring Compliance Modules...");
  await modularCompliance.addModule(countryRestrictModuleAddress);
  await modularCompliance.addModule(accreditedInvestorModuleAddress);
  console.log("   Modules added to ModularCompliance");

  // Add claim topics
  console.log("\n14. Setting up Claim Topics...");
  await claimTopicsRegistry.addClaimTopic(1); // KYC
  await claimTopicsRegistry.addClaimTopic(7); // Accredited Investor
  console.log("   Claim topics added");

  // Summary
  console.log("\n" + "=".repeat(60));
  console.log("DEPLOYMENT COMPLETE");
  console.log("=".repeat(60));

  const deployedContracts: DeployedContracts = {
    claimTopicsRegistry: claimTopicsRegistryAddress,
    trustedIssuersRegistry: trustedIssuersRegistryAddress,
    identityRegistryStorage: identityRegistryStorageAddress,
    identityRegistry: identityRegistryAddress,
    modularCompliance: modularComplianceAddress,
    verifiToken: verifiTokenAddress,
    sp1CredentialVerifier: sp1CredentialVerifierAddress,
    credentialSBT: credentialSBTAddress,
    rwaGate: rwaGateAddress,
    rwaPool: rwaPoolAddress,
  };

  console.log("\nDeployed Contracts:");
  console.log("-".repeat(60));
  Object.entries(deployedContracts).forEach(([name, address]) => {
    console.log(`${name.padEnd(25)} : ${address}`);
  });

  // Save deployment addresses to file
  const fs = await import("fs");
  const deploymentPath = "./deployments";
  if (!fs.existsSync(deploymentPath)) {
    fs.mkdirSync(deploymentPath, { recursive: true });
  }

  const network = (await ethers.provider.getNetwork()).name;
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const filename = `${deploymentPath}/${network}-${timestamp}.json`;

  fs.writeFileSync(
    filename,
    JSON.stringify(
      {
        network,
        chainId: (await ethers.provider.getNetwork()).chainId.toString(),
        deployer: deployer.address,
        timestamp: new Date().toISOString(),
        contracts: deployedContracts,
      },
      null,
      2
    )
  );

  console.log(`\nDeployment info saved to: ${filename}`);
  console.log("=".repeat(60));

  return deployedContracts;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
