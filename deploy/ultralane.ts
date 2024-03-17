import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ZeroAddress, ZeroHash } from "ethers";

module.exports = async function ({
  deployments: { deterministic, get },
  getNamedAccounts,
  network,
}: HardhatRuntimeEnvironment) {
  const { deployer } = await getNamedAccounts();

  const USDC = await get("USDC");
  const SplitJoin16Verifier = await get("SplitJoin16Verifier");
  const Hash2Verifier = await get("Hash2Verifier");
  const NoteVerifier = await get("NoteVerifier");
  const Input16Verifier = await get("Input16Verifier");
  const mailbox = (() => {
    switch (network.name) {
      case "sepolia":
        return "0xfFAEF09B3cd11D9b20d1a19bECca54EEC2884766";
      case "scrollsep":
        return "0x3C5154a193D6e2955650f9305c8d80c18C814A68";
      case "mumbai":
        return "0x2d1889fe5B092CD988972261434F7E5f26041115";
      default:
        return ZeroAddress;
    }
  })();

  const { deploy, address } = await deterministic("Ultralane", {
    from: deployer,
    log: true,
    args: [
      "0x2188DC59E7a26a3AF6eEE0117CF7A222bbd31980",
      USDC.address,
      SplitJoin16Verifier.address,
      Hash2Verifier.address,
      NoteVerifier.address,
      Input16Verifier.address,
      mailbox,
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
  "Input16Verifier",
];
