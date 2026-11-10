const { JsonRpcProvider } = require("ethers");

async function main() {
  const provider = new JsonRpcProvider("http://127.0.0.1:7545", undefined, { staticNetwork: true });
  try {
    const network = await provider.getNetwork();
    if (network.chainId !== 1337n) throw new Error(`Expected chain ID 1337, received ${network.chainId}`);
    const accounts = await provider.send("eth_accounts", []);
    if (!accounts.length) throw new Error("Ganache has no accounts");
    console.log(`Connected: http://127.0.0.1:7545 | chain ID ${network.chainId} | ${accounts.length} accounts | block ${await provider.getBlockNumber()}`);
  } finally {
    provider.destroy();
  }
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; });
