import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import "@nomicfoundation/hardhat-chai-matchers";
import hre from "hardhat";
import { Field, hash } from "@ultralane/sdk";
import { toBeHex, zeroPadValue } from "ethers";

describe("Poseidon2", function () {
  async function setup() {
    const poseidon2 = await hre.ethers.deployContract("Poseidon2Test");
    return { poseidon2 };
  }

  for (let i = 0; i < 10; i++) {
    const input = Field.random();
    it("hash_1 " + input.hex(), async function () {
      const { poseidon2 } = await loadFixture(setup);
      const expected = await hash([input]);
      const actual = await poseidon2.hash_1(input.hex());
      expect(zeroPadValue(toBeHex(actual), 32)).to.equal(expected.hex());
      //   console.log(await poseidon2.hash_1_twice.estimateGas(input.hex()));
    });
  }

  for (let i = 0; i < 10; i++) {
    const input1 = Field.random();
    const input2 = Field.random();
    it(`hash_2 ${input1.hex()} ${input2.hex()}`, async function () {
      const { poseidon2 } = await loadFixture(setup);
      const expected = await hash([input1, input2]);
      const actual = await poseidon2.hash_2(input1.hex(), input2.hex());
      expect(zeroPadValue(toBeHex(actual), 32)).to.equal(expected.hex());
      //   console.log(
      //     await poseidon2.hash_2.estimateGas(input1.hex(), input2.hex()),
      //   );
    });
  }

  for (let i = 0; i < 10; i++) {
    const input1 = Field.random();
    const input2 = Field.random();
    const input3 = Field.random();
    it(`hash_3 ${input1.hex()} ${input2.hex()} ${input3.hex()}`, async function () {
      const { poseidon2 } = await loadFixture(setup);
      const expected = await hash([input1, input2, input3]);
      const actual = await poseidon2.hash_3(
        input1.hex(),
        input2.hex(),
        input3.hex()
      );
      expect(zeroPadValue(toBeHex(actual), 32)).to.equal(expected.hex());
      //   console.log(
      //     await poseidon2.hash_3.estimateGas(
      //       input1.hex(),
      //       input2.hex(),
      //       input3.hex(),
      //     ),
      //   );
    });
  }
});
