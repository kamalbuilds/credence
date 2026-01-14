import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("Credence Contracts", function () {
  let owner: SignerWithAddress;
  let agent: SignerWithAddress;
  let investor1: SignerWithAddress;
  let investor2: SignerWithAddress;

  let claimTopicsRegistry: any;
  let trustedIssuersRegistry: any;
  let identityRegistryStorage: any;
  let identityRegistry: any;
  let modularCompliance: any;
  let verifiToken: any;
  let credentialSBT: any;

  beforeEach(async function () {
    [owner, agent, investor1, investor2] = await ethers.getSigners();

    // Deploy ClaimTopicsRegistry
    const ClaimTopicsRegistry = await ethers.getContractFactory("ClaimTopicsRegistry");
    claimTopicsRegistry = await ClaimTopicsRegistry.deploy();
    await claimTopicsRegistry.waitForDeployment();

    // Deploy TrustedIssuersRegistry
    const TrustedIssuersRegistry = await ethers.getContractFactory("TrustedIssuersRegistry");
    trustedIssuersRegistry = await TrustedIssuersRegistry.deploy();
    await trustedIssuersRegistry.waitForDeployment();

    // Deploy IdentityRegistryStorage
    const IdentityRegistryStorage = await ethers.getContractFactory("IdentityRegistryStorage");
    identityRegistryStorage = await IdentityRegistryStorage.deploy();
    await identityRegistryStorage.waitForDeployment();

    // Deploy IdentityRegistry
    const IdentityRegistry = await ethers.getContractFactory("IdentityRegistry");
    identityRegistry = await IdentityRegistry.deploy(
      await trustedIssuersRegistry.getAddress(),
      await claimTopicsRegistry.getAddress(),
      await identityRegistryStorage.getAddress()
    );
    await identityRegistry.waitForDeployment();

    // Bind IdentityRegistry to Storage
    await identityRegistryStorage.bindIdentityRegistry(await identityRegistry.getAddress());

    // Deploy ModularCompliance
    const ModularCompliance = await ethers.getContractFactory("ModularCompliance");
    modularCompliance = await ModularCompliance.deploy();
    await modularCompliance.waitForDeployment();

    // Deploy VerifiToken
    const VerifiToken = await ethers.getContractFactory("VerifiToken");
    verifiToken = await VerifiToken.deploy(
      "Credence Security Token",
      "MVST",
      await identityRegistry.getAddress(),
      await modularCompliance.getAddress(),
      ethers.ZeroAddress
    );
    await verifiToken.waitForDeployment();

    // Bind token to compliance
    await modularCompliance.bindToken(await verifiToken.getAddress());

    // Deploy CredentialSBT
    const CredentialSBT = await ethers.getContractFactory("CredentialSBT");
    credentialSBT = await CredentialSBT.deploy(
      "Credence Credential",
      "MVC",
      "https://api.mantleverifi.io/metadata/"
    );
    await credentialSBT.waitForDeployment();
  });

  describe("VerifiToken", function () {
    it("should have correct name and symbol", async function () {
      expect(await verifiToken.name()).to.equal("Credence Security Token");
      expect(await verifiToken.symbol()).to.equal("MVST");
    });

    it("should have owner as agent", async function () {
      expect(await verifiToken.isAgent(owner.address)).to.be.true;
    });

    it("should allow owner to add agents", async function () {
      await verifiToken.addAgent(agent.address);
      expect(await verifiToken.isAgent(agent.address)).to.be.true;
    });

    it("should allow agents to pause and unpause", async function () {
      expect(await verifiToken.paused()).to.be.false;
      await verifiToken.pause();
      expect(await verifiToken.paused()).to.be.true;
      await verifiToken.unpause();
      expect(await verifiToken.paused()).to.be.false;
    });

    it("should return correct version", async function () {
      expect(await verifiToken.version()).to.equal("1.0.0");
    });
  });

  describe("ClaimTopicsRegistry", function () {
    it("should allow adding claim topics", async function () {
      await claimTopicsRegistry.addClaimTopic(1);
      await claimTopicsRegistry.addClaimTopic(7);

      const topics = await claimTopicsRegistry.getClaimTopics();
      expect(topics.length).to.equal(2);
    });

    it("should not allow duplicate claim topics", async function () {
      await claimTopicsRegistry.addClaimTopic(1);
      await expect(claimTopicsRegistry.addClaimTopic(1)).to.be.revertedWith("ClaimTopicsRegistry: topic already exists");
    });
  });

  describe("ModularCompliance", function () {
    it("should have token bound", async function () {
      expect(await modularCompliance.getTokenBound()).to.equal(await verifiToken.getAddress());
    });

    it("should return true for canTransfer when no modules", async function () {
      // When no modules are added, canTransfer should return true
      expect(await modularCompliance.canTransfer(investor1.address, investor2.address, 100)).to.be.true;
    });
  });

  describe("CredentialSBT", function () {
    it("should have correct name and symbol", async function () {
      expect(await credentialSBT.name()).to.equal("Credence Credential");
      expect(await credentialSBT.symbol()).to.equal("MVC");
    });

    it("should allow authorized minter to mint credentials", async function () {
      const tx = await credentialSBT.mintCredential(
        investor1.address,
        1, // KYC credential type
        ethers.keccak256(ethers.toUtf8Bytes("credential_hash")),
        0, // No expiration
        "ipfs://QmTest"
      );
      await tx.wait();

      expect(await credentialSBT.balanceOf(investor1.address)).to.equal(1);
    });

    it("should report tokens as locked (soulbound)", async function () {
      await credentialSBT.mintCredential(
        investor1.address,
        1,
        ethers.keccak256(ethers.toUtf8Bytes("credential_hash")),
        0,
        "ipfs://QmTest"
      );

      const tokenId = 1;
      expect(await credentialSBT.locked(tokenId)).to.be.true;
    });

    it("should not allow transfer of SBT", async function () {
      await credentialSBT.mintCredential(
        investor1.address,
        1,
        ethers.keccak256(ethers.toUtf8Bytes("credential_hash")),
        0,
        "ipfs://QmTest"
      );

      await expect(
        credentialSBT.connect(investor1).transferFrom(investor1.address, investor2.address, 1)
      ).to.be.revertedWithCustomError(credentialSBT, "SoulboundTokenCannotBeTransferred");
    });
  });

  describe("IdentityRegistry", function () {
    it("should have owner as agent", async function () {
      expect(await identityRegistry.isAgent(owner.address)).to.be.true;
    });

    it("should return false for non-registered addresses", async function () {
      expect(await identityRegistry.contains(investor1.address)).to.be.false;
    });
  });
});
