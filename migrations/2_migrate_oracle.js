const BirdOracle = artifacts.require('BirdOracle');
const BirdToken = artifacts.require('RedToken');

const localDeployScript = async (deployer) => {
  console.log('Deploying to local blockchain');
  await deployer.deploy(BirdToken);
  await deployer.deploy(BirdOracle, BirdToken.address);
};

const kovanDeployScript = async (deployer) => {
  console.log('Deploying to kovan');
  const usdtAddress = '0xaA7C9d8544Dd696239D9a953De2fAF7AA2852e22';
  await deployer.deploy(BirdOracle, usdtAddress);
};

const mainnetDeployScript = async (deployer) => {
  console.log('Deploying to Mainnet');
  const birdTokenAddress = '0x70401dFD142A16dC7031c56E862Fc88Cb9537Ce0';
  await deployer.deploy(BirdOracle, birdTokenAddress);
};

const defaultDeployScript = async (deployer) => {
  console.log('Deploying to Mainnet');
  const birdTokenAddress = '0x70401dFD142A16dC7031c56E862Fc88Cb9537Ce0';
  await deployer.deploy(BirdOracle, birdTokenAddress);
};

module.exports = async (deployer, network) => {
  switch (network) {
    case 'mainnet':
      mainnetDeployScript(deployer);
      break;

    case 'kovan':
      kovanDeployScript(deployer);
      break;

    case 'development':
    case 'develop':
      localDeployScript(deployer);
      break;

    default:
      console.log('default: ', network);
      defaultDeployScript(deployer);
  }
};
