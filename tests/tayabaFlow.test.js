//const { ethers } = require("hardhat");
//const exceptions = require("./exceptions");
const { expect } = require("chai");
const { ethers } = require("hardhat");


describe.only("------ Tayaba Flow ------", function () {
    //Contracts
    let rahatDonor;
    let rahatRegistry;
    let rahatClaim;
    let rahatCommunity1;
    let cvaProject1;

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

    //Tests Variables
    const communityName1 = 'Nepal Community';
    const rahatToken1 = {
        name: 'H20 Wheels',
        symbol: 'H2W',
        decimals: 0
    }
    const cvaProjectDetails1 = {
        name: 'cva project',
        approveAmount: '1000000',
        beneficiaryClaim1: '1',
        beneficiaryClaim2: '1',
        vendorTransferAmount1: '20',
        vendorTransferAmount2: '20'
    }

    before(async function () {
        [deployer, donor, admin, manager, vendor1, vendor2, otpServer1, beneficiary1, beneficiary2] = await ethers.getSigners();
        const RahatDonor = await ethers.getContractFactory("RahatDonor");
        //const RahatRegistry = await ethers.getContractFactory("RahatRegistry");
        const RahatClaim = await ethers.getContractFactory("RahatClaim");
        const RahatCommunity = await ethers.getContractFactory("RahatCommunity");
        //common
        rahatDonor = await RahatDonor.deploy(donor.address);
        //rahatRegistry = await RahatRegistry.deploy(admin.address);
        rahatClaim = await RahatClaim.deploy();

        //community
        rahatCommunity1 = await RahatCommunity.deploy(
            communityName1,
            admin.address
        )

    });

    describe("Deployment", function () {
        it("Should deploy contract", async function () {
            donorAdmins = await rahatDonor.listOwners();
            expect(donorAdmins[0]).to.equal(donor.address);
            expect(await rahatCommunity1.name()).to.equal(communityName1);
            console.log("rahatDonor:", rahatDonor.address);
        });
    });

    describe("Token Minting", function () {
        it("Should create token ", async function () {
            const TokenContract = await ethers.getContractFactory("RahatToken");
            token1 = await TokenContract.deploy(
                rahatToken1.name, rahatToken1.symbol, rahatDonor.address, rahatToken1.decimals
            );
            expect(await token1.name()).to.equal(rahatToken1.name);
        })
        // it("Should create token by Rahat Donor", async function () {
        //     await rahatDonor.connect(donor).createToken(rahatToken1.name, rahatToken1.symbol, rahatToken1.decimals);
        //     const tokens = await rahatDonor.listTokens();
        //     tokenAddress = tokens[0];
        //     const TokenContract = await ethers.getContractFactory("RahatToken");
        //     token1 = await TokenContract.attach(tokenAddress);
        //     expect(tokens.length).to.equal(1);
        // })
    })


    describe("Deploy and Add project to Community", function () {
        it("Should deploy CVA Project", async function () {
            const CVAProject = await ethers.getContractFactory("CVAProject");
            cvaProject1 = await CVAProject.deploy(
                cvaProjectDetails1.name,
                token1.address,
                rahatClaim.address,
                otpServer1.address,
                rahatCommunity1.address
            );
            expect(await cvaProject1.defaultToken()).to.equal(token1.address);
            expect(await cvaProject1.name()).to.equal(cvaProjectDetails1.name);
        })

        it("Should add project to community", async function () {
            //TODO check if project is deployed for this community?
            await rahatCommunity1.connect(admin).approveProject(cvaProject1.address);
            expect(await rahatCommunity1.isProject(cvaProject1.address)).to.equal(true);
        })
    })

    describe("Initial Fund Management", function () {
        it("should send fund to project", async function () {
            await rahatDonor.connect(donor).mintTokenAndApprove(token1.address, cvaProject1.address, cvaProjectDetails1.approveAmount)
            const allowanceTocvaProject_1 = await token1.allowance(rahatDonor.address, cvaProject1.address);
            expect(allowanceTocvaProject_1.toNumber().toString()).to.equal(cvaProjectDetails1.approveAmount);
        })

        it("should accept fund from donor and get the tokens", async function () {
            await cvaProject1.connect(admin).acceptToken(rahatDonor.address, cvaProjectDetails1.approveAmount)
            const balanceOfProject_1 = await token1.balanceOf(cvaProject1.address);
            expect(balanceOfProject_1.toNumber().toString()).to.equal(cvaProjectDetails1.approveAmount)
        })
    })

    describe("Token Allowance Disbursement to Vendors", function () {

        it("should add vendor to community", async function () {
            expect(await rahatCommunity1.isVendor(vendor1.address)).to.equal(false);
            const vendorRole = await rahatCommunity1.VENDOR_ROLE();
            await rahatCommunity1.connect(admin).grantRole(vendorRole,vendor1.address);
            expect(await rahatCommunity1.isVendor(vendor1.address)).to.equal(true);
        })
        it("should transfer allowances to vendor1", async function () {
            await cvaProject1.connect(admin).createAllowanceToVendor(vendor1.address,
                cvaProjectDetails1.vendorTransferAmount1)
            const pendingAllowanceToVendor1 = await cvaProject1.vendorAllowancePending(vendor1.address);
            expect(pendingAllowanceToVendor1.toNumber().toString()).to.equal(cvaProjectDetails1.vendorTransferAmount1);
        })

        it("Should accept allowance from project", async function () {
            await cvaProject1.connect(vendor1).acceptAllowanceByVendor(cvaProjectDetails1.vendorTransferAmount1);
            const allowanceToVendor1 = await cvaProject1.vendorAllowance(vendor1.address);
            expect(allowanceToVendor1.toNumber().toString()).to.equal(cvaProjectDetails1.vendorTransferAmount1);
        })

    })

    describe("Beneficiary Claims Management", function () {
        it("should add beneficiary to community", async function () {
            expect(await rahatCommunity1.isBeneficiary(beneficiary1.address)).to.equal(false);
            expect(await rahatCommunity1.isBeneficiary(beneficiary1.address)).to.equal(false)
            await rahatCommunity1.connect(admin).addBeneficiary(beneficiary1.address);
            await rahatCommunity1.connect(admin).addBeneficiary(beneficiary2.address);
            expect(await rahatCommunity1.isBeneficiary(beneficiary1.address)).to.equal(true);
            expect(await rahatCommunity1.isBeneficiary(beneficiary1.address)).to.equal(true)
        })

        it("should assign token claims to beneficiary1", async function () {
            await cvaProject1.connect(admin).assignClaims(beneficiary1.address, cvaProjectDetails1.beneficiaryClaim1)
            await cvaProject1.connect(admin).assignClaims(beneficiary2.address, cvaProjectDetails1.beneficiaryClaim2)

            const beneficiary1_claim = await cvaProject1.beneficiaryClaims(beneficiary1.address);
            const beneficiary1_count = await cvaProject1.beneficiaryCount();
            expect(beneficiary1_claim.toNumber().toString()).to.equal(cvaProjectDetails1.beneficiaryClaim1);
            expect(beneficiary1_count.toNumber()).to.equal(2);
        })

    })

    describe("Vendor to Beneficiary Charge Process", function(){

        it("should charge tokens to beneficairy",async function(){

        })

        it("should approve vendor request to charge token by otpServer",async function(){

        }),

        it("should process the token charge re",async function(){

        })

    })





});
