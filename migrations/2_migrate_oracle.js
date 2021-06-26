const BirdOracle = artifacts.require("BirdOracle");
const BirdToken = artifacts.require("RedToken");
require("dotenv").config();
const accountNo = process.env.DEPLOY_ACCOUNT_NO;

const localDeployScript = async (deployer) => {
  console.log("Deploying to local blockchain");
  await deployer.deploy(BirdToken);
  await deployer.deploy(BirdOracle, BirdToken.address);
};

const kovanDeployScript = async (deployer) => {
  console.log("Deploying to kovan");
  const usdtAddress = "0xaA7C9d8544Dd696239D9a953De2fAF7AA2852e22";
  await deployer.deploy(BirdOracle, usdtAddress);
};

const bscTestnetDeployScript = async (deployer, accounts) => {
  console.log("Deploying to bscTestnet..");
  const usdtAddress = "0x10e0BC6EBCf6B07D2c8457C806AbCf8Fa0bDA2b7";
  await deployer.deploy(BirdOracle, usdtAddress, { from: accounts[accountNo] });
};

const bscMainnetDeployScript = async (deployer, accounts) => {
  console.log("Deploying to Mainnet");
  const usdtAddress = "0x55d398326f99059ff775485246999027b3197955";
  await deployer.deploy(BirdOracle, usdtAddress);
};

const defaultDeployScript = async (deployer) => {
  console.log("Deploying to Default");
  const birdTokenAddress = "0x70401dFD142A16dC7031c56E862Fc88Cb9537Ce0";
  await deployer.deploy(BirdOracle, birdTokenAddress);
};

module.exports = async (deployer, network, accounts) => {
  switch (network) {
    case "bscMainnet":
      bscMainnetDeployScript(deployer, accounts);
      break;

    case "bscTestnet":
      bscTestnetDeployScript(deployer, accounts);
      break;

    case "kovan":
      kovanDeployScript(deployer);
      break;

    case "development":
    case "develop":
      localDeployScript(deployer);
      break;

    default:
      console.log("default: ", network);
      defaultDeployScript(deployer);
  }
};
