const { expect } = require('chai');
const { ethers } = require('hardhat');
describe.only('-------- C2C Flow --------', () => {
  let rahatDonor;
  let rahatToken;
  let rahatCommunity;
  let c2CProject;

  const rahatToken1 = {
    name: 'Rumsan Coin',
    symbol: 'RUM',
    decimals: 18,
  };
  const C2CProjectDetails = {
    name: 'C2C Project',
    approveAmount: '10000000',
    beneficiaryClaim1: '500',
    beneficiaryClaim2: '500',
  };
  const communityName = 'Rumsan Community';

  before(async () => {
    [deployer, donor, admin, beneficiary1, beneficiary2] = await ethers.getSigners();
    rahatDonor = await ethers.deployContract('RahatDonor', [donor.address]);
    rahatCommunity = await ethers.deployContract('RahatCommunity', [communityName, admin.address]);
  });

  describe('Deployment', () => {
    it('should deploy the RahatDonor contract', async () => {
      const owner = await rahatDonor.listOwners();
      expect(owner[0]).to.equal(donor.address);
    });

    it('should deploy the RahatCommunity contract', async () => {
      const name = await rahatCommunity.name();
      expect(name).to.equal(communityName);
    });
  });

  describe('Token Minting', () => {
    it('should mint tokens', async () => {
      rahatToken = await ethers.deployContract('RahatToken', [
        rahatToken1.name,
        rahatToken1.symbol,
        await rahatDonor.getAddress(),
        rahatToken1.decimals,
      ]);

      expect(await rahatToken.name()).to.equal(rahatToken1.name);
    });
  });

  describe('Deploy and Add C2C Project to Community', () => {
    it('should deploy C2C Project', async () => {
      c2CProject = await ethers.deployContract('C2CProject', [
        C2CProjectDetails.name,
        await rahatToken.getAddress(),
        await rahatCommunity.getAddress(),
      ]);

      expect(await c2CProject.name()).to.equal(C2CProjectDetails.name);
      expect(await c2CProject.defaultToken()).to.equal(await rahatToken.getAddress());
    });

    it('Should not be able to add  Project to Community with unsupported Interface', async () => {
      expect(rahatCommunity.connect(admin).approveProject(rahatDonor.target)).to.be.revertedWith(
        'project interface not supported'
      );
      expect(rahatCommunity.connect(admin).approveProject(await rahatToken.getAddress())).to.be
        .reverted;
    });

    it('Should be able to add  Project to Community', async () => {
      await rahatCommunity.connect(admin).approveProject(await c2CProject.getAddress());
      expect(await rahatCommunity.isProject(await c2CProject.getAddress())).to.be.true;
    });
  });
  describe('Initial Fund Management', () => {
    it('Should  be able to add funds to Project ', async () => {
      await rahatDonor
        .connect(donor)
        .mintTokenAndApprove(
          await rahatToken.getAddress(),
          await c2CProject.getAddress(),
          C2CProjectDetails.approveAmount
        );
      const allowanceToC2CProject = await rahatToken.allowance(
        rahatDonor.target,
        await c2CProject.getAddress()
      );

      expect(allowanceToC2CProject.toString()).to.equal(C2CProjectDetails.approveAmount);
    });

    it('should be able to send the erc20 token to the project', async () => {});

    it('Should accept fund from donor and get the tokens ', async () => {
      const allowanceToProject = await rahatToken.allowance(
        rahatDonor.target,
        await c2CProject.getAddress()
      );

      expect(allowanceToProject.toString()).to.equal(C2CProjectDetails.approveAmount);

      await c2CProject.connect(admin).acceptToken(rahatDonor.target, allowanceToProject.toString());
      const finalAllowanceToProject = await rahatToken.allowance(
        rahatDonor.target,
        await c2CProject.getAddress()
      );
      expect(finalAllowanceToProject.toString()).to.equal('0');
      const balanceOfProject = await rahatToken.balanceOf(await c2CProject.getAddress());

      expect(balanceOfProject.toString()).to.equal(C2CProjectDetails.approveAmount);
    });
  });

  describe('Beneficiary Claims Management', () => {
    it('Should be able to add Beneficiary to Community', async () => {
      expect(await rahatCommunity.isBeneficiary(beneficiary1.address)).to.be.false;
      expect(await rahatCommunity.isBeneficiary(beneficiary2.address)).to.be.false;
      await rahatCommunity.connect(admin).addBeneficiary(beneficiary1.address);
      await rahatCommunity.connect(admin).addBeneficiary(beneficiary2.address);
      expect(await rahatCommunity.isBeneficiary(beneficiary1.address)).to.be.true;
      expect(await rahatCommunity.isBeneficiary(beneficiary2.address)).to.be.true;
    });

    it('Should be able to assign token claims to Beneficiary', async () => {
      await c2CProject
        .connect(admin)
        .assignClaims(beneficiary1.address, C2CProjectDetails.beneficiaryClaim1);
      await c2CProject
        .connect(admin)
        .assignClaims(beneficiary2.address, C2CProjectDetails.beneficiaryClaim2);

      const claim1 = await c2CProject.beneficiaryClaims(beneficiary1.address);
      const claim2 = await c2CProject.beneficiaryClaims(beneficiary2.address);

      expect(claim1.toString()).to.equal(C2CProjectDetails.beneficiaryClaim1);
      expect(claim2.toString()).to.equal(C2CProjectDetails.beneficiaryClaim2);
    });
  });

  describe('processTransferToBeneficiary', () => {
    it('should process transfer to beneficiary', async () => {
      // Process transfer
      await c2CProject
        .connect(admin)
        .processTransferToBeneficiary(beneficiary1.address, C2CProjectDetails.beneficiaryClaim1);

      // Check beneficiary claim
      const claim = await c2CProject.beneficiaryClaims(beneficiary1.address);
      expect(claim.toString()).to.equal('0');

      // Check token balance
      const balance = await rahatToken.balanceOf(beneficiary1);
      expect(balance.toString()).to.equal(C2CProjectDetails.beneficiaryClaim1.toString());

      // Check event emission
      expect(
        await c2CProject
          .connect(admin)
          .processTransferToBeneficiary(beneficiary2.address, C2CProjectDetails.beneficiaryClaim2)
      )
        .to.emit(c2CProject, 'ClaimProcessed')
        .withArgs(
          beneficiary1.address,
          await rahatToken.getAddress(),
          C2CProjectDetails.beneficiaryClaim1
        );
    });

    it('should revert if beneficiary is not a beneficiary', async () => {
      await expect(
        c2CProject.connect(admin).processTransferToBeneficiary(donor.address, 100)
      ).to.be.revertedWith('Not a Beneficiary');
    });

    it('should revert if beneficiary does not have enough claims', async () => {
      await expect(
        c2CProject.connect(admin).processTransferToBeneficiary(beneficiary1.address, 100)
      ).to.be.revertedWith('Not enough Claims');
    });
  });
});
