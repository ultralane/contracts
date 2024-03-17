import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import "@nomicfoundation/hardhat-chai-matchers";
import hre from "hardhat";
import { HardhatEthersHelpers } from "@nomicfoundation/hardhat-ethers/types";
import { Field, KeyPair, Note, NoteMerkleTree, logtime } from "@ultralane/sdk";
import { ZeroAddress, hexlify, parseUnits, randomBytes } from "ethers";

describe("Ultralane", function () {
  let ethers = hre.ethers as any as HardhatEthersHelpers;
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function setup() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await (
      ethers as any as HardhatEthersHelpers
    ).getSigners();
    const keypair = await KeyPair.random();

    const usdc = await hre.ethers.deployContract("USDC");
    await usdc.transfer(otherAccount, parseUnits("1000", 6));

    const splitJoinVerifier = await hre.ethers.deployContract(
      "SplitJoin16Verifier"
    );
    const hash2Verifier = await hre.ethers.deployContract("Hash2Verifier");
    const noteVerifier = await hre.ethers.deployContract("NoteVerifier");
    const input16Verifier = await hre.ethers.deployContract("Input16Verifier");

    const ultralane = await hre.ethers.deployContract("Ultralane", [
      owner,
      usdc,
      splitJoinVerifier,
      hash2Verifier,
      noteVerifier,
      input16Verifier,
      ZeroAddress,
    ]);
    return {
      ultralane,
      splitJoinVerifier,
      hash2Verifier,
      usdc,
      keypair,
      owner,
      otherAccount,
    };
  }

  describe("Deployment", function () {
    it("Should set the splitJoinVerifier", async function () {
      const { ultralane, splitJoinVerifier } = await loadFixture(setup);

      expect(await ultralane.splitJoinVerifier()).to.equal(
        await splitJoinVerifier.getAddress()
      );
    });

    it("Should set the hash2Verifier", async function () {
      const { ultralane, hash2Verifier } = await loadFixture(setup);

      expect(await ultralane.hash2Verifier()).to.equal(
        await hash2Verifier.getAddress()
      );
    });
  });

  // describe("Deposit", function () {
  //   it("Should deposit", async function () {
  //     const { pool, usdc, keypair } = await loadFixture(setup);

  //     const depositAmount = parseUnits("100", 6);

  //     const tree = new NoteMerkleTree(32);
  //     const tx = await tree.createTransaction({
  //       depositAmount,
  //       keypair,
  //       updateTree: true,
  //     });
  //     const { root, commitments } = await tx.publicData();
  //     const { proof } = await tx.prove();

  //     await usdc.approve(pool, depositAmount);
  //     await pool.deposit(
  //       depositAmount,
  //       commitments[0].raw(),
  //       proof,
  //       ZeroAddress,
  //       await tree.calculateRootHex(),
  //     );
  //   });
  // });

  describe("Transact", function () {
    it("Should deposit", async function () {
      const { ultralane, usdc, keypair } = await loadFixture(setup);

      let depositAmount = parseUnits("100", 6);

      const tree = new NoteMerkleTree(16);
      // await pool.setDepositsRoot(await tree.calculateRootHex());

      const tx = await tree.createTransaction({
        inputNotes: [],
        keypair,
        updateTree: true,
        depositAmount,
      });
      const { proof, publicInputs } = await tx.prove();
      const updatedDepositRoot = await tree.calculateRootHex();
      await usdc.approve(ultralane, depositAmount);
      await ultralane.transact(proof, publicInputs);
    });

    it("Should withdraw", async function () {
      const { ultralane, usdc, keypair, owner } = await loadFixture(setup);

      const tree = new NoteMerkleTree(16);
      const initialPoolBalance = parseUnits("100", 6);
      const {
        outputs: [depositNote],
      } = await tree.createTransaction({
        keypair,
        depositAmount: initialPoolBalance,
        updateTree: true,
      });
      // await pool.setDepositsRoot(await tree.calculateRootHex());
      await usdc.transfer(ultralane, initialPoolBalance);

      const withdrawAddress = randomAddress();
      const withdrawAmount = parseUnits("40", 6);
      const tx = await tree.createTransaction({
        inputNotes: [depositNote],
        keypair,
        updateTree: true,
        depositAmount: withdrawAmount * -1n,
        withdrawAddress: Field.from(withdrawAddress),
      });
      const { proof, publicInputs } = await tx.prove();
      const updatedDepositRoot = await tree.calculateRootHex();
      expect(ultralane.transact(proof, publicInputs)).changeTokenBalances(
        usdc,
        [withdrawAddress, await ultralane.getAddress()],
        [withdrawAmount, initialPoolBalance - withdrawAmount]
      );
    });
  });

  describe("Collect", function () {
    it("Should collect", async function () {
      const { ultralane, usdc, keypair, owner, otherAccount } =
        await loadFixture(setup);

      const initCodeHash = await ultralane.INIT_CODE_HASH();

      const { address, salt } = await keypair.deriveStealthAddress(
        0,
        ultralane,
        initCodeHash
      );
      const stealthProof = await logtime(
        () => keypair.proveStealthAddressOwnership(0),
        "stealthProof"
      );

      const amt = parseUnits("100", 6);
      await usdc.connect(otherAccount).transfer(address, amt);

      const tree = new NoteMerkleTree(32);
      const note = new Note(amt, keypair, Field.random());
      tree.insert(await note.commitment());
      const noteProof = await note.prove();
      // const tx = await tree.createTransaction({
      //   depositAmount: amt,
      //   keypair,
      //   updateTree: true,
      // });
      // const noteProof = await logtime(() => tx.prove(), "noteProof");

      await expect(
        ultralane.collect(
          usdc,
          amt,
          salt.hex(),
          stealthProof.proof,
          (await note.commitment()).hex(),
          noteProof.proof
        )
      ).changeTokenBalances(
        usdc,
        [await ultralane.getAddress(), address],
        [amt, -1n * amt]
      );
    });
  });

  describe("Trustless withdraw", async function () {
    it("Should withdraw", async function () {
      const { ultralane, usdc, keypair, owner, otherAccount } =
        await loadFixture(setup);

      // make a deposit
      let depositAmount = parseUnits("100", 6);
      const tree = new NoteMerkleTree(16);
      const tx = await tree.createTransaction({
        inputNotes: [],
        keypair,
        updateTree: true,
        depositAmount,
      });
      const { proof, publicInputs } = await tx.prove();
      await usdc.approve(ultralane, depositAmount);
      await ultralane.transact(proof, publicInputs);

      const input = await tree.createInput(tx.outputs[0]);
      const inputProof = await input.prove(ZeroAddress);
      await expect(
        ultralane.trustlessWithdrawInit(
          inputProof.proof,
          inputProof.publicInputs
        )
      ).to.emit(ultralane, "TrustlessWithdrawInit");
    });
  });
});

function randomAddress() {
  return hexlify(randomBytes(20));
}
