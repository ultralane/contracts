import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

module.exports = async function ({
  deployments: { deploy },
  getNamedAccounts,
}: HardhatRuntimeEnvironment) {
  const { deployer } = await getNamedAccounts();

  await deploy("SplitJoin16Verifier", {
    from: deployer,
    log: true,
  });

  await deploy("SplitJoin32Verifier", {
    from: deployer,
    log: true,
  });

  await deploy("Hash2Verifier", {
    from: deployer,
    log: true,
  });

  await deploy("NoteVerifier", {
    from: deployer,
    log: true,
  });

  await deploy("Input16Verifier", {
    from: deployer,
    log: true,
  });
};

module.exports.tags = [
  "SplitJoin16Verifier",
  "SplitJoin32Verifier",
  "Hash2Verifier",
  "NoteVerifier",
  "Input16Verifier",
];
