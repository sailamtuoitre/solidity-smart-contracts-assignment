process.env.HARDHAT_NETWORK = "ganache";
const hre = require("hardhat");
const assert = require("node:assert/strict");

async function main() {
  await hre.run("compile");
  const storage = await hre.ethers.deployContract("Storage");
  await storage.waitForDeployment();
  const address = await storage.getAddress();
  assert.notEqual(await hre.ethers.provider.getCode(address), "0x");
  console.log(`Storage deployed: ${address}`);
  assert.equal(await storage.retrieve(), 0n);
  console.log("Initial value: 0");
  for (const value of [42n, 123n, 0n, hre.ethers.MaxUint256]) {
    const receipt = await (await storage.store(value)).wait();
    assert.equal(receipt.status, 1);
    assert.equal(await storage.retrieve(), value);
    console.log(`Verified store(${value}): ${receipt.hash}`);
  }
  const [, other] = await hre.ethers.getSigners();
  await (await storage.connect(other).store(7n)).wait();
  assert.equal(await storage.retrieve(), 7n);
  console.log("Verified second account write; final value: 7");
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
