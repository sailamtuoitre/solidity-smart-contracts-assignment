process.env.HARDHAT_NETWORK = "ganache";
const hre = require("hardhat");

async function main() {
  await hre.run("compile");
  const counter = await hre.ethers.deployContract("Counter");
  await counter.waitForDeployment();
  const address = await counter.getAddress();
  if (await hre.ethers.provider.getCode(address) === "0x") throw new Error("Deployment bytecode missing");
  await (await counter.increment()).wait();
  if (await counter.count() !== 1n) throw new Error("Transaction verification failed");
  console.log(`Counter deployed: ${address}`);
  console.log("Verified deployed bytecode and increment transaction: count = 1");
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
