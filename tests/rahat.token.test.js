const { web3 } = require("hardhat");
//const exceptions = require("./exceptions");
const RahatToken = artifacts.require("RahatToken");

describe.only("------ Rahat Token Tests ------", function () {
  let rahatToken;

  before(async function () {
    [deployer, donor, agency, palika] = await web3.eth.getAccounts();

    rahatToken = await RahatToken.new("Rahat", "RHT", donor, 0);

    // await web3.eth.sendTransaction({
    //   from: agency,
    //   to: rahat.address,
    //   value: web3.utils.toWei("5", "ether"),
    // });
  });
});
