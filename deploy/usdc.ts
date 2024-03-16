import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

module.exports = async function ({
  deployments: { deploy },
  getNamedAccounts,
}: HardhatRuntimeEnvironment) {
  const { deployer } = await getNamedAccounts();

  await deploy("USDC", {
    from: deployer,
    log: true,
  });
};

module.exports.tags = ["USDC"];
