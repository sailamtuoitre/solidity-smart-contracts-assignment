const assert = require("node:assert/strict");
const { ethers } = require("hardhat");

describe("Storage", function () {
  let storage;
  beforeEach(async function () {
    storage = await ethers.deployContract("Storage");
    await storage.waitForDeployment();
  });

  it("starts at zero", async function () {
    assert.equal(await storage.retrieve(), 0n);
  });

  it("persists writes, overwrites, zero and the uint256 maximum", async function () {
    for (const value of [42n, 123n, 0n, ethers.MaxUint256]) {
      await (await storage.store(value)).wait();
      assert.equal(await storage.retrieve(), value);
    }
  });

  it("allows another account to overwrite the value", async function () {
    const [, other] = await ethers.getSigners();
    await (await storage.store(42n)).wait();
    await (await storage.connect(other).store(7n)).wait();
    assert.equal(await storage.retrieve(), 7n);
  });
});
