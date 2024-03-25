//const { ethers } = require("hardhat");
//const exceptions = require("./exceptions");
const { expect } = require('chai');
const { ethers } = require('hardhat');
const { signMetaTxRequest } = require('../utils');

const generateMultiCallData = (contract, functionName, callData) => {
  let encodedData = [];
  console.log({ callData });
  if (callData) {
    for (const callD of callData) {
      const encodedD = contract.interface.encodeFunctionData(functionName, [...callD]);
      encodedData.push(encodedD);
    }
  }
  return encodedData;
};

async function getMetaTxRequest(signer, forwarderContract, storageContract, functionName, params) {
  return signMetaTxRequest(signer, forwarderContract, {
    from: signer.address,
    to: storageContract.target,
    data: storageContract.interface.encodeFunctionData(functionName, params),
  });
}

describe.only('------ Tayaba Flow ------', function () {
  //Contracts
  let rahatDonor;
  let rahatRegistry;
  let rahatClaim;
  let rahatCommunity1;
  let cvaProject1;
  let forwarderContract;

  let otpOracle;

  //Tokens
  let token1;

  //Accounts
  let deployer;
  let admin;
  let manager; //srso
  let vendor1;
  let vendor2;
  let otpServer1;
  let beneficiary1;
  let beneficiary2;
  let vendorRole;

  //Tests Variables
  const communityName1 = 'Nepal Community';
  const rahatToken1 = {
    name: 'H20 Wheels',
    symbol: 'H2W',
    decimals: 0,
  };
  const cvaProjectDetails1 = {
    name: 'cva project',
    approveAmount: '1000000',
    beneficiaryClaim1: '1',
    beneficiaryClaim2: '1',
    vendorTransferAmount1: '20',
    vendorTransferAmount2: '20',
  };

  const otpServerDetails = {
    otpExpiryTime: 500,
    otp: '1212',
  };

  before(async function () {
    [deployer, donor, admin, manager, vendor1, vendor2, otpServer1, beneficiary1, beneficiary2] =
      await ethers.getSigners();
    const RahatDonor = await ethers.getContractFactory('RahatDonor');
    const ForwarderContract = await ethers.getContractFactory('ERC2771Forwarder');
    //const RahatRegistry = await ethers.getContractFactory("RahatRegistry");
    const RahatClaim = await ethers.getContractFactory('RahatClaim');
    const RahatCommunity = await ethers.getContractFactory('RahatCommunity');
    //common
    forwarderContract = await ForwarderContract.deploy('Rumsan Forwarder');
    rahatDonor = await RahatDonor.deploy(donor.address);
    //rahatRegistry = await RahatRegistry.deploy(admin.address);
    rahatClaim = await RahatClaim.deploy();
    //community
    rahatCommunity1 = await RahatCommunity.deploy(communityName1, admin.address);
    vendorRole = await rahatCommunity1.VENDOR_ROLE();
    // await admin.sendTransaction({
    //   to: await rahatCommunity1.getAddress(),
    //   value: ethers.parseEther('1.0'),
    // });
  });

  describe('Deployment', function () {
    it('Should deploy contract', async function () {
      donorAdmins = await rahatDonor.listOwners();
      expect(donorAdmins[0]).to.equal(donor.address);
      expect(await rahatCommunity1.name()).to.equal(communityName1);
      expect(await rahatClaim.getAddress()).to.be.a('string');
    });
  });

  describe('Token Minting', function () {
    it('Should create token ', async function () {
      const TokenContract = await ethers.getContractFactory('RahatToken');
      token1 = await TokenContract.deploy(
        rahatToken1.name,
        rahatToken1.symbol,
        await rahatDonor.getAddress(),
        rahatToken1.decimals
      );
      expect(await token1.name()).to.equal(rahatToken1.name);
    });
    // it("Should create token by Rahat Donor", async function () {
    //     await rahatDonor.connect(donor).createToken(rahatToken1.name, rahatToken1.symbol, rahatToken1.decimals);
    //     const tokens = await rahatDonor.listTokens();
    //     tokenAddress = tokens[0];
    //     const TokenContract = await ethers.getContractFactory("RahatToken");
    //     token1 = await TokenContract.attach(tokenAddress);
    //     expect(tokens.length).to.equal(1);
    // })
  });

  describe('Deploy and Add project to Community', function () {
    it('Should deploy CVA Project', async function () {
      const CVAProject = await ethers.getContractFactory('CVAProject');
      cvaProject1 = await CVAProject.deploy(
        cvaProjectDetails1.name,
        await token1.getAddress(),
        await rahatClaim.getAddress(),
        otpServer1.address,
        await rahatCommunity1.getAddress(),
        await forwarderContract.getAddress()
      );
      expect(await cvaProject1.defaultToken()).to.equal(await token1.getAddress());
      expect(await cvaProject1.name()).to.equal(cvaProjectDetails1.name);
    });

    it('Should not be able to add project_address with unsupported interface', async function () {
      //TODO check if project is deployed for this community?
      expect(rahatCommunity1.connect(admin).approveProject(await token1.getAddress())).to.be
        .reverted;
      expect(rahatCommunity1.connect(admin).approveProject(rahatDonor.target)).to.be.revertedWith(
        'project interface not supported'
      );
    });

    it('Should add project to community', async function () {
      //TODO check if project is deployed for this community?
      await rahatCommunity1.connect(admin).approveProject(await cvaProject1.getAddress());
      expect(await rahatCommunity1.isProject(await cvaProject1.getAddress())).to.equal(true);
    });
  });

  describe('Initial Fund Management', function () {
    it('should send fund to project', async function () {
      await rahatDonor
        .connect(donor)
        .mintTokenAndApprove(
          await token1.getAddress(),
          await cvaProject1.getAddress(),
          cvaProjectDetails1.approveAmount
        );
      const allowanceTocvaProject_1 = await token1.allowance(
        rahatDonor.target,
        await cvaProject1.getAddress()
      );

      expect(allowanceTocvaProject_1.toString()).to.equal(cvaProjectDetails1.approveAmount);
    });

    it('should accept fund from donor and get the tokens', async function () {
      const allowanceToProject = await token1.allowance(
        rahatDonor.target,
        await cvaProject1.getAddress()
      );
      expect(allowanceToProject.toString()).to.equal(cvaProjectDetails1.approveAmount);
      await cvaProject1
        .connect(admin)
        .acceptToken(rahatDonor.target, allowanceToProject.toString());
      const finalAllowanceToProject = await token1.allowance(
        rahatDonor.target,
        await cvaProject1.getAddress()
      );
      expect(finalAllowanceToProject).to.equal(0n);

      const balanceOfProject_1 = await token1.balanceOf(await cvaProject1.getAddress());
      expect(balanceOfProject_1.toString()).to.equal(cvaProjectDetails1.approveAmount);
    });
  });

  describe('Token Allowance Disbursement to Vendors', function () {
    it('should add vendor to community', async function () {
      expect(await rahatCommunity1.hasRole(vendorRole, vendor1.address)).to.equal(false);
      await rahatCommunity1.connect(admin).grantRole(vendorRole, vendor1.address);
      await rahatCommunity1.connect(admin).grantRole(vendorRole, vendor2.address);
      expect(await rahatCommunity1.hasRole(vendorRole, vendor1.address)).to.equal(true);
    });
    it('should transfer allowances to vendor1', async function () {
      await cvaProject1
        .connect(admin)
        .createAllowanceToVendor(vendor1.address, cvaProjectDetails1.vendorTransferAmount1);
      const pendingAllowanceToVendor1 = await cvaProject1.vendorAllowancePending(vendor1.address);
      expect(pendingAllowanceToVendor1.toString()).to.equal(
        cvaProjectDetails1.vendorTransferAmount1
      );
    });

    it('Should accept allowance from project', async function () {
      await cvaProject1
        .connect(vendor1)
        .acceptAllowanceByVendor(cvaProjectDetails1.vendorTransferAmount1);
      const allowanceToVendor1 = await cvaProject1.vendorAllowance(vendor1.address);
      expect(allowanceToVendor1.toString()).to.equal(cvaProjectDetails1.vendorTransferAmount1);
    });

    it('should transfer allowances to vendor2', async function () {
      await cvaProject1
        .connect(admin)
        .sendAllowanceToVendor(vendor2.address, cvaProjectDetails1.vendorTransferAmount2);
      const allowanceToVendor2 = await cvaProject1.vendorAllowance(vendor2.address);
      console.log({ allowanceToVendor2 });
      expect(allowanceToVendor2.toString()).to.equal(cvaProjectDetails1.vendorTransferAmount2);
    });
  });

  describe('Beneficiary Claims Management', function () {
    it('should add beneficiary to community', async function () {
      expect(await rahatCommunity1.isBeneficiary(beneficiary1.address)).to.equal(false);
      expect(await rahatCommunity1.isBeneficiary(beneficiary1.address)).to.equal(false);
      await rahatCommunity1.connect(admin).addBeneficiary(beneficiary1.address);
      await rahatCommunity1.connect(admin).addBeneficiary(beneficiary2.address);
      expect(await rahatCommunity1.isBeneficiary(beneficiary1.address)).to.equal(true);
      expect(await rahatCommunity1.isBeneficiary(beneficiary1.address)).to.equal(true);
    });

    it('should assign token claims to beneficiary1', async function () {
      await cvaProject1
        .connect(admin)
        .assignClaims(beneficiary1.address, cvaProjectDetails1.beneficiaryClaim1);
      await cvaProject1
        .connect(admin)
        .assignClaims(beneficiary2.address, cvaProjectDetails1.beneficiaryClaim2);

      const beneficiary1_claim = await cvaProject1.beneficiaryClaims(beneficiary1.address);
      const beneficiary1_count = await cvaProject1.beneficiaryCount();
      expect(beneficiary1_claim.toString()).to.equal(cvaProjectDetails1.beneficiaryClaim1);
      expect(beneficiary1_count).to.equal(2n);
    });

    it('should lock project', async function () {
      expect(await cvaProject1.isLocked()).to.equal(false);
      await rahatDonor.connect(donor).lockProject(await cvaProject1.getAddress());
      expect(await cvaProject1.isLocked()).to.equal(true);
    });
  });

  describe('Vendor to Beneficiary Charge Process', function () {
    it('should charge tokens to beneficairy', async function () {
      const request = await getMetaTxRequest(
        vendor1,
        forwarderContract,
        cvaProject1,
        'requestTokenFromBeneficiary(address,uint256)',
        [beneficiary1.address, cvaProjectDetails1.beneficiaryClaim1]
      );

      console.log({ request });

      const tx = await forwarderContract.connect(deployer).execute(request);

      const receipt = await tx.wait();
      console.log(receipt);
    });

    it('should not be able to approve vendor request by random wallet', async function () {
      const otpHash = ethers.id(otpServerDetails.otp);
      const expiryDate = Math.floor(Date.now() / 1000) + otpServerDetails.otpExpiryTime;
      const intitialClaimsState = await rahatClaim.claims(1);
      expect(intitialClaimsState.expiryDate).to.equal(0n);
      expect(intitialClaimsState.otpHash).to.equal(ethers.ZeroHash);
      expect(intitialClaimsState.claimerAddress).to.equal(vendor1.address);
      expect(rahatClaim.connect(vendor1).addOtpToClaim(1, otpHash, expiryDate)).to.be.revertedWith(
        'unauthorized otpServer'
      );

      const finalClaimsState = await rahatClaim.claims(1);
      expect(finalClaimsState.expiryDate).to.not.equal(expiryDate);
      expect(finalClaimsState.otpHash).to.not.equal(otpHash);
    }),
      it('should approve vendor request and add OTP via otpServers', async function () {
        const otpHash = ethers.id(otpServerDetails.otp);
        const expiryDate = Math.floor(Date.now() / 1000) + otpServerDetails.otpExpiryTime;
        const intitialClaimsState = await rahatClaim.claims(1);
        expect(intitialClaimsState.expiryDate).to.equal(0n);
        expect(intitialClaimsState.otpHash).to.equal(ethers.ZeroHash);
        expect(intitialClaimsState.claimerAddress).to.equal(vendor1.address);
        await rahatClaim.connect(otpServer1).addOtpToClaim(1, otpHash, expiryDate);

        const finalClaimsState = await rahatClaim.claims(1);
        expect(finalClaimsState.expiryDate).to.equal(BigInt(expiryDate));
        expect(finalClaimsState.otpHash).to.equal(otpHash);
      }),
      it('should process the token charge request', async function () {
        const initialVendorBalance = await token1.balanceOf(vendor1.address);
        expect(initialVendorBalance).to.equal(0n);
        const initialClaimState = await rahatClaim.claims(1);
        expect(initialClaimState.isProcessed).to.equal(false);

        const request = await getMetaTxRequest(
          vendor1,
          forwarderContract,
          cvaProject1,
          'processTokenRequest',
          [beneficiary1.address, otpServerDetails.otp]
        );

        console.log({ request });

        const tx = await forwarderContract.execute(request);

        const receipt = await tx.wait();
        console.log(receipt);
        const finalVendorBalance = await token1.balanceOf(vendor1.address);
        const finalClaimsState = await rahatClaim.claims(1);
        const beneficiary1Claim = await cvaProject1.beneficiaryClaims(beneficiary1.address);
        const allowanceToVendor1 = await cvaProject1.vendorAllowance(vendor1.address);
        expect(allowanceToVendor1).to.equal(
          BigInt(cvaProjectDetails1.vendorTransferAmount1) -
            BigInt(cvaProjectDetails1.beneficiaryClaim1)
        );
        expect(beneficiary1Claim).to.equal(0n);
        expect(finalClaimsState.isProcessed).to.equal(true);
        expect(finalVendorBalance).to.equal(BigInt(cvaProjectDetails1.beneficiaryClaim1));
      });

    it('should be able to send beneficiary tokens to vendor upon offline transaction', async function () {
      const initialVendorBalance = await token1.balanceOf(vendor1.address);
      const initialClaimState = await rahatClaim.claims(1);
      await cvaProject1
        .connect(otpServer1)
        .sendBeneficiaryTokenToVendor(
          beneficiary2.address,
          vendor1.address,
          cvaProjectDetails1.beneficiaryClaim2
        );
      const finalVendorBalance = await token1.balanceOf(vendor1.address);
      const finalClaimsState = await rahatClaim.claims(1);
      const beneficiary1Claim = await cvaProject1.beneficiaryClaims(beneficiary1.address);
      expect(beneficiary1Claim).to.equal(0n);
      expect(finalClaimsState.isProcessed).to.equal(true);
      expect(finalVendorBalance).to.equal(
        initialVendorBalance + BigInt(cvaProjectDetails1.beneficiaryClaim1)
      );
    });

    it('bulk claim process', async function () {
      const multicallData = generateMultiCallData(cvaProject1, 'sendBeneficiaryTokenToVendor', [
        [beneficiary1.address, vendor1.address, cvaProjectDetails1.beneficiaryClaim1],
        [beneficiary1.address, vendor1.address, cvaProjectDetails1.beneficiaryClaim1],
      ]);

      console.log(multicallData);
    });
  });
});
