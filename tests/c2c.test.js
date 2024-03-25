const { expect } = require('chai');
const { ethers } = require('hardhat');

const rahatToken1 = {
  name: 'RahatToken1',
  symbol: 'RHT',
  decimals: 0,
};

describe('c2c', () => {
  let RahatTokenTransfer;
  let rahatDonor;
  let deployer;
  let sender;
  let receiver;

  before(async () => {
    [deployer, sender, receiver, donor] = await ethers.getSigners();
    RahatTokenTransfer = await ethers.deployContract('RahatTokenTransferGateway');
    rahatDonor = await ethers.deployContract('RahatDonor', [donor.address]);
    await RahatTokenTransfer.waitForDeployment();
  });

  describe('RahatDonor', async () => {
    it('should deploy RahatDonor contract', async () => {
      console.log('deployer:', donor.address);
      console.log('RahatDonor:', await rahatDonor.getAddress());
    });

    it('should mint the erc20 token', async () => {
      const RHTToken1 = await ethers.deployContract('RahatToken', [
        rahatToken1.name,
        rahatToken1.symbol,
        deployer.address,
        rahatToken1.decimals,
      ]);

      await RHTToken1.mint(sender.address, 1000);
      const senderBalance = await RHTToken1.balanceOf(sender.address);

      // await RHTToken1.approve(sender.address, 500);
      await RHTToken1.connect(deployer).transfer(receiver.address, 500);
      console.log(
        await RHTToken1.balanceOf(receiver.address),
        await RHTToken1.balanceOf(sender.address)
      );
      expect(await RHTToken1.name()).to.equal(rahatToken1.name);
      expect('1000').to.equal(senderBalance.toString());
    });

    // it('should transfer a erc20 token', async () => {
    //   const amount = ethers.parseEther('1');
    //   const tx = await rahatDonor.connect(donor).donate({
    //     value: amount,
    //   });
    //   const receipt = await tx.wait();
    //   const txReceipt = await ethers.provider.getTransactionReceipt(tx.hash);
    //   const event = txReceipt.events;
    //   console.log({ event });

    //   const donorBalance = await ethers.provider.getBalance(donor.address);
    //   const rahatDonorBalance = await ethers.provider.getBalance(rahatDonor.address);
    //   console.log('Donor balance:', ethers.formatEther(donorBalance));
    //   console.log('RahatDonor balance:', ethers.formatEther(rahatDonorBalance));
    // });
  });

  it('should deploy the contract', async () => {
    console.log('deployer:', deployer.address);
    console.log('RahatTokenTransfer:', await RahatTokenTransfer.getAddress());
  });

  it('should send native tokens', async () => {
    const amount = ethers.parseEther('1');
    const tx = await RahatTokenTransfer.connect(sender).transferToken(receiver.address, amount, {
      value: ethers.parseEther('1'),
    });
    const receipt = await tx.wait();
    const txReceipt = await ethers.provider.getTransactionReceipt(tx.hash);
    const event = txReceipt.events;
    console.log({ event });

    const senderBalance = await ethers.provider.getBalance(sender.address);
    const receiverBalance = await ethers.provider.getBalance(receiver.address);
    console.log('Sender balance:', ethers.formatEther(senderBalance));
    console.log('Receiver balance:', ethers.formatEther(receiverBalance));
  });

  it('should send ERC20 tokens', async () => {
    const RahatToken = await ethers.deployContract('RahatToken', [
      rahatToken1.name,
      rahatToken1.symbol,
      deployer.address,
      rahatToken1.decimals,
    ]);

    await RahatToken.mint(sender.address, 1000);

    const senderBalance = await RahatToken.balanceOf(sender.address);
    console.log(`${sender.address} : ${senderBalance.toString()}`);
    // await RahatToken.connect(sender).approve(sender.address, 500);
    // await RahatToken.connect(sender).transferFrom(
    //   sender.address,
    //   RahatTokenTransfer.getAddress(),
    //   500
    // );
    // console.log(await RahatToken.balanceOf(RahatTokenTransfer.getAddress()));
    await RahatToken.connect(sender).approve(RahatTokenTransfer.getAddress(), 500);
    await RahatTokenTransfer.connect(sender).transferERC20Token(
      RahatToken.getAddress(),
      receiver.address,
      500
    );

    const senderBalance1 = await RahatToken.balanceOf(sender.address);
    const receiverBalance = await RahatToken.balanceOf(receiver.address);

    console.log({ senderBalance1, receiverBalance });

    expect(await RahatToken.name()).to.equal(rahatToken1.name);
  });
});
