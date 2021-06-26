const Migrations = artifacts.require("Migrations");
require("dotenv").config();
const accountNo = process.env.DEPLOY_ACCOUNT_NO;

module.exports = async (deployer, network, accounts) => {
  console.log("accounts[accountNo]", accounts[accountNo]);
  await deployer.deploy(Migrations, { from: accounts[accountNo] });
};
