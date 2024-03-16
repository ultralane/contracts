import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ZeroAddress } from "ethers";

module.exports = async function ({
  deployments: { deploy, get },
  getNamedAccounts,
}: HardhatRuntimeEnvironment) {
  const { deployer } = await getNamedAccounts();

  const SplitJoin16Verifier = await get("SplitJoin16Verifier");
  const Hash2Verifier = await get("Hash2Verifier");
  const NoteVerifier = await get("NoteVerifier");
  const USDC = await get("USDC");

  await deploy("Pool", {
    from: deployer,
    log: true,
    args: [
      SplitJoin16Verifier.address,
      Hash2Verifier.address,
      NoteVerifier.address,
      USDC.address,
    ],
  });
};

module.exports.tags = ["Pool"];
module.exports.dependencies = [
  "USDC",
  "SplitJoin16Verifier",
  "Hash2Verifier",
  "NoteVerifier",
];
