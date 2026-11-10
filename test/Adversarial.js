const assert = require('node:assert/strict');
const { ethers } = require('hardhat');
describe('Bank adversarial callbacks', function () {
  it('blocks nested withdrawal and rolls back a rejected ETH payout', async () => {
    const bank = await ethers.deployContract('SimpleBank'); await bank.waitForDeployment();
    const probe = await ethers.deployContract('BankProbe',[await bank.getAddress()]); await probe.waitForDeployment();
    const address = await probe.getAddress();
    await (await probe.deposit({value:100})).wait();
    await assert.rejects(async () => { await (await probe.withdraw(10,true)).wait(); });
    assert.equal(await bank.balances(address),100n);
    await (await probe.withdraw(10,false)).wait();
    assert.equal(await probe.nestedSucceeded(),false);
    assert.equal(await bank.balances(address),90n);
  });
});
