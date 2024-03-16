import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ZeroAddress, ZeroHash } from "ethers";

module.exports = async function ({
  deployments: { deterministic, get },
  getNamedAccounts,
}: HardhatRuntimeEnvironment) {
  const { deployer } = await getNamedAccounts();

  const SplitJoin16Verifier = await get("SplitJoin16Verifier");
  const Hash2Verifier = await get("Hash2Verifier");
  const NoteVerifier = await get("NoteVerifier");
  const USDC = await get("USDC");

  const { deploy, address } = await deterministic("Pool", {
    from: deployer,
    log: true,
    args: [
      SplitJoin16Verifier.address,
      Hash2Verifier.address,
      NoteVerifier.address,
      USDC.address,
    ],
    salt: ZeroHash,
  });

  await deploy();
};

module.exports.tags = ["Pool"];
module.exports.dependencies = [
  "USDC",
  "SplitJoin16Verifier",
  "Hash2Verifier",
  "NoteVerifier",
];
