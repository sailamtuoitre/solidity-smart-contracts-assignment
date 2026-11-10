const assert = require("node:assert/strict");
const { ethers } = require("hardhat");

describe("Counter", function () {
  it("starts at zero and persists consecutive increments", async function () {
    const counter = await ethers.deployContract("Counter");
    await counter.waitForDeployment();
    assert.equal(await counter.count(), 0n);
    await (await counter.increment()).wait();
    await (await counter.increment()).wait();
    assert.equal(await counter.count(), 2n);
  });
});
