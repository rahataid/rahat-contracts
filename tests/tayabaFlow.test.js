//const { ethers } = require("hardhat");
//const exceptions = require("./exceptions");
const { expect } = require("chai");
const { ethers } = require("hardhat");


describe.only("------ Tayaba Flow ------", function () {
    //Contracts
    let rahatDonor;
    let rahatRegistry;
    let rahatClaim;
    let rahatCommunity_1;
    let cvaProject_1;
    let beneficiary1;
    let beneficiary2;

    let otpOracle;

    //Tokens
    let token_1;

    //Accounts
    let deployer;
    let admin;
    let manager; //srso
    let vendor1;
    let vendor2;
    let otpServer_1;

    //Tests Variables
    const communityName1 = 'Nepal Community';
    const rahatToken1 = {
        name: 'H20 Wheels',
        symbol: 'H2W',
        decimals: 0
    }
    const cvaProject_1_details = {
        approveAmount: '1000000',
        beneficiary_1_claim: '1',
        beneficiary_2_claim: '1',
        vendor_1_transferAmount: '20',
        vendor_2_transferAmount: '20'
    }

    before(async function () {
        [deployer, admin, manager, vendor1, vendor2, otpServer_1, beneficiary1, beneficiary2] = await ethers.getSigners();
        const RahatDonor = await ethers.getContractFactory("RahatDonor");
        const RahatRegistry = await ethers.getContractFactory("RahatRegistry");
        const RahatClaim = await ethers.getContractFactory("RahatClaim");
        const RahatCommunity = await ethers.getContractFactory("RahatCommunity");


        //common
        rahatDonor = await RahatDonor.deploy(admin.address);
        rahatRegistry = await RahatRegistry.deploy(admin.address);
        rahatClaim = await RahatClaim.deploy();

        //community
        rahatCommunity_1 = await RahatCommunity.deploy(
            communityName1,
            rahatClaim.address,
            rahatRegistry.address,
            otpServer_1.address,
            admin.address
        )

    });

    describe("Deployment", function () {
        it("Should deploy contract", async function () {
            expect(await rahatDonor.owner(admin.address)).to.equal(true);
            expect(await rahatRegistry.owner(admin.address)).to.equal(true);
            expect(await rahatCommunity_1.name()).to.equal(communityName1);

            console.log("rahatDonor:", rahatDonor.address);
        });
    });

    describe("Token Minting", function () {
        it("Should create token by Rahat Donor", async function () {
            await rahatDonor.connect(admin).createToken(rahatToken1.name, rahatToken1.symbol, rahatToken1.decimals);
            const tokens = await rahatDonor.listTokens();
            tokenAddress = tokens[0];
            const TokenContract = await ethers.getContractFactory("RahatToken");
            token_1 = await TokenContract.attach(tokenAddress);
            expect(tokens.length).to.equal(1);
        })
    })


    describe("Deploy and Add project to Community", function () {
        it("Should deploy CVA Project", async function () {
            const CVAProject = await ethers.getContractFactory("CVAProject");
            cvaProject_1 = await CVAProject.deploy(
                token_1.address,
                rahatClaim.address,
                otpServer_1.address,
                rahatCommunity_1.address,
                admin.address
            );
            expect(await cvaProject_1.defaultToken()).to.equal(token_1.address);
            expect(await cvaProject_1.name()).to.equal(`CVA Project`);
        })

        it("Should add project to community", async function () {
            //TODO check if project is deployed for this community?
            await rahatCommunity_1.connect(admin).addProject(cvaProject_1.address);
            const projects = await rahatCommunity_1.projects(0);
            expect(projects).to.equal(cvaProject_1.address);
        })
    })

    describe("Initial Fund Management", function () {
        it("should send fund to project", async function () {
            await rahatDonor.connect(admin).mintTokenAndApprove(token_1.address, cvaProject_1.address, cvaProject_1_details.approveAmount)
            const allowanceTocvaProject_1 = await token_1.allowance(rahatDonor.address, cvaProject_1.address);
            expect(allowanceTocvaProject_1.toNumber().toString()).to.equal(cvaProject_1_details.approveAmount);
        })

        it("should accept fund from donor and get the tokens", async function () {
            await cvaProject_1.acceptToken(token_1.address, rahatDonor.address, cvaProject_1_details.approveAmount)
            const balanceOfProject_1 = await token_1.balanceOf(cvaProject_1.address);
            expect(balanceOfProject_1.toNumber().toString()).to.equal(cvaProject_1_details.approveAmount)
        })
    })

    describe("Token Disbursement to Vendors", function () {

        it("should add vendor to community", async function () {
            const vendorRole = await rahatCommunity_1.vendorRole();
            expect(await rahatCommunity_1.hasRole(vendorRole, vendor1.address)).to.equal(false);
            await rahatCommunity_1.connect(admin).addVendor(vendor1.address);
            expect(await rahatCommunity_1.hasRole(vendorRole, vendor1.address)).to.equal(true);
        })
        it("should transfer tokens to vendor1", async function () {
            await cvaProject_1.sendTokenToVendor(vendor1.address, cvaProject_1_details.vendor_1_transferAmount)
            const allowanceToVendor1 = await token_1.allowance(cvaProject_1.address, vendor1.address);
            expect(allowanceToVendor1.toNumber().toString()).to.equal(cvaProject_1_details.vendor_1_transferAmount);
        })

        it("Should accept tokens from project", async function () {
            const initialVendor1Balance = await token_1.balanceOf(vendor1.address);
            expect(initialVendor1Balance.toNumber()).to.equal(0);
            await token_1.connect(vendor1).transferFrom(cvaProject_1.address, vendor1.address, cvaProject_1_details.vendor_1_transferAmount);
            const vendor1Balance = await token_1.balanceOf(vendor1.address);
            expect(vendor1Balance.toNumber().toString()).to.equal(cvaProject_1_details.vendor_1_transferAmount);
        })

    })

    describe("Beneficiary Management", function () {
        it("should add beneficiary to community", async function () {
            expect(await rahatCommunity_1.isBeneficiary(beneficiary1.address)).to.equal(false);
            expect(await rahatCommunity_1.isBeneficiary(beneficiary1.address)).to.equal(false)
            await rahatCommunity_1.connect(admin).addBeneficiary(beneficiary1.address);
            await rahatCommunity_1.connect(admin).addBeneficiary(beneficiary2.address);
            expect(await rahatCommunity_1.isBeneficiary(beneficiary1.address)).to.equal(true);
            expect(await rahatCommunity_1.isBeneficiary(beneficiary1.address)).to.equal(true)
        })

        it("should assign beneficiary to project", async function () {
            expect(await cvaProject_1.isBeneficiary(beneficiary1.address)).to.equal(false)
            await rahatCommunity_1.connect(admin).assignBeneficiaryToProject(cvaProject_1.address, beneficiary1.address);
            expect(await cvaProject_1.isBeneficiary(beneficiary1.address)).to.equal(true)

        })

        it("should assign token claims to beneficiary1", async function () {
            await cvaProject_1.connect(admin).addClaimToBeneficiary(beneficiary1.address, cvaProject_1_details.beneficiary_1_claim)
            const beneficiary1_claim = await cvaProject_1.claims(beneficiary1.address, token_1.address);
            expect(beneficiary1_claim.toNumber().toString()).to.equal(cvaProject_1_details.beneficiary_1_claim);
        })

    })





});
