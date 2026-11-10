const assert = require('node:assert/strict');
const { ethers, network } = require('hardhat');
const E = ethers.parseEther;
async function deploy(name, args = [], options = {}) {
  const c = await ethers.deployContract(name, args, options); await c.waitForDeployment(); return c;
}
async function tx(p) { return (await p).wait(); }
async function rejects(p) { await assert.rejects(async () => { const r = await p; if (r.wait) await r.wait(); }); }
async function advance(n = 4000) { await network.provider.send('evm_increaseTime', [n]); await network.provider.send('evm_mine'); }
let a,b,c,d, snapshot;
before(async function () {
  [a,b,c,d] = await ethers.getSigners();
  snapshot = await network.provider.send('evm_snapshot');
});
after(async function () { await network.provider.send('evm_revert',[snapshot]); });

describe('Assignment contracts', function () {
  this.timeout(180000);
  it('Greeting: constructor and updates from another account', async () => {
    const x = await deploy('Greeting',['Hello']); assert.equal(await x.greeting(),'Hello');
    await tx(x.connect(b).setGreeting('Xin chao')); assert.equal(await x.greeting(),'Xin chao');
  });
  it('Counter: decrement, reset and lower/upper bounds', async () => {
    const x=await deploy('Counter'); await rejects(x.decrement());
    await tx(x.increment()); await tx(x.decrement()); assert.equal(await x.count(),0n);
    for(let i=0;i<100;i++) await tx(x.increment());
    await rejects(x.increment()); assert.equal(await x.count(),100n);
    await tx(x.reset()); assert.equal(await x.count(),0n);
  });
  it('Ownable and ProtectedVault: ownership transfer and protected withdrawals', async () => {
    const x=await deploy('ProtectedVault'); assert.equal(await x.owner(),a.address);
    await tx(x.connect(b).deposit({value:1000}));
    await rejects(x.connect(b).withdraw(b.address,1)); await rejects(x.transferOwnership(ethers.ZeroAddress));
    await tx(x.transferOwnership(b.address)); await rejects(x.withdraw(a.address,1));
    await tx(x.connect(b).withdraw(b.address,400)); assert.equal(await x.contractBalance(),600n);
    await rejects(x.connect(b).withdraw(b.address,601));
  });
  it('SimpleBank: independent balances, overdraft and zero deposit', async () => {
    const x=await deploy('SimpleBank'); await rejects(x.deposit());
    await tx(x.deposit({value:1000})); await tx(x.connect(b).deposit({value:200}));
    await rejects(x.connect(b).withdraw(201)); await rejects(x.withdraw(0));
    await tx(x.withdraw(400)); assert.equal(await x.balances(a.address),600n);
    assert.equal(await x.balances(b.address),200n);
  });
  it('Voting: authorization, duplicate/invalid vote, tie and winner', async () => {
    const x=await deploy('Voting',[['A','B']]);
    await rejects(x.connect(b).vote(0)); await rejects(x.connect(b).authorize(c.address));
    await tx(x.authorize(b.address)); await rejects(x.connect(b).vote(2));
    await tx(x.connect(b).vote(1)); await rejects(x.connect(b).vote(0));
    assert.equal(await x.totalVotes(1),1n); assert.equal(await x.winnerName(),'B');
    await tx(x.vote(0)); assert.equal(await x.winnerName(),'A');
    await rejects(deploy('Voting',[[]]));
  });
  it('MyToken: transfer, allowance consumption, infinite allowance and zero address', async () => {
    const x=await deploy('MyToken',['Token','T',1000]);
    assert.equal(await x.totalSupply(),1000n); await tx(x.transfer(b.address,100));
    await rejects(x.connect(b).transfer(c.address,101)); await rejects(x.transfer(ethers.ZeroAddress,1));
    await tx(x.approve(b.address,50)); await tx(x.connect(b).transferFrom(a.address,c.address,30));
    assert.equal(await x.allowance(a.address,b.address),20n);
    await rejects(x.connect(b).transferFrom(a.address,c.address,21));
    await tx(x.approve(b.address,ethers.MaxUint256)); await tx(x.connect(b).transferFrom(a.address,c.address,1));
    assert.equal(await x.allowance(a.address,b.address),ethers.MaxUint256);
    assert.equal(await x.balanceOf(c.address),31n);
    await tx(x.transfer(c.address,0));
  });
  it('Crowdfunding: successful campaign, time guard, owner and double claim', async () => {
    const x=await deploy('Crowdfunding',[1000,3600]); await rejects(x.contribute());
    await tx(x.connect(b).contribute({value:1000})); await rejects(x.claimFunds());
    await advance(); await rejects(x.connect(b).claimFunds()); await rejects(x.contribute({value:1}));
    await tx(x.claimFunds()); assert.equal(await x.claimed(),true); await rejects(x.claimFunds()); await rejects(x.connect(b).refund());
  });
  it('Crowdfunding: failed campaign refunds once', async () => {
    const x=await deploy('Crowdfunding',[1000,3600]); await tx(x.connect(b).contribute({value:100}));
    await rejects(x.connect(b).refund()); await advance(); await rejects(x.claimFunds());
    await tx(x.connect(b).refund()); assert.equal(await x.contributions(b.address),0n); await rejects(x.connect(b).refund());
  });
  it('Lottery: fees, manager restriction, minimum, payout and round reset', async () => {
    const x=await deploy('Lottery',[100,2]); await rejects(x.enter({value:100}));
    await rejects(x.connect(b).enter({value:99})); await tx(x.connect(b).enter({value:100}));
    await rejects(x.pickWinner()); await tx(x.connect(c).enter({value:100}));
    await rejects(x.connect(b).pickWinner()); const r=await tx(x.pickWinner());
    const ev=r.logs.map(l=>{try{return x.interface.parseLog(l);}catch{return null;}}).find(l=>l?.name==='WinnerSelected');
    assert.ok([b.address,c.address].includes(ev.args.winner)); assert.equal(ev.args.amount,200n);
    assert.equal(await x.playersCount(),0n); await rejects(x.pickWinner());
  });
  it('TimeLockVault: beneficiary, extension, premature withdrawal and empty vault', async () => {
    const x=await deploy('TimeLockVault',[b.address,3600]); await tx(x.deposit({value:100}));
    const old=await x.unlockTime(); await rejects(x.withdraw()); await rejects(x.connect(b).withdraw());
    await rejects(x.extendLock(10)); await tx(x.connect(b).extendLock(100)); assert.equal(await x.unlockTime(),old+100n);
    await advance(); await tx(x.connect(b).withdraw()); assert.equal(await x.timeRemaining(),0n); await rejects(x.connect(b).withdraw());
  });
  it('Escrow: delivery, refund and both dispute resolutions guard roles/states', async () => {
    for(const route of ['delivery','refund','seller','buyer']) {
      const x=await deploy('Escrow',[b.address,c.address],{value:100});
      await rejects(x.connect(d).confirmDelivery()); await rejects(x.resolveToSeller());
      if(route==='delivery') await tx(x.confirmDelivery());
      else if(route==='refund') await tx(x.connect(b).refundBuyer());
      else { await tx(x.raiseDispute()); await rejects(x.confirmDelivery()); await rejects(x.connect(b).resolveToSeller());
        await tx(route==='seller'?x.connect(c).resolveToSeller():x.connect(c).resolveToBuyer()); }
      assert.equal(await x.state(),route==='delivery'||route==='seller'?2n:3n);
      await rejects(x.raiseDispute()); await rejects(x.connect(b).refundBuyer());
    }
  });
  it('SimpleNFT: mint, authorization, metadata, operator and approval clearing', async () => {
    const x=await deploy('SimpleNFT',['NFT','N']); await rejects(x.connect(b).mint(b.address,'uri'));
    await tx(x.mint(a.address,'ipfs://one')); assert.equal(await x.tokenURI(1),'ipfs://one');
    await rejects(x.connect(b).transferFrom(a.address,b.address,1));
    await tx(x.approve(b.address,1)); await tx(x.connect(b).transferFrom(a.address,c.address,1));
    assert.equal(await x.ownerOf(1),c.address); assert.equal(await x.getApproved(1),ethers.ZeroAddress);
    await tx(x.connect(c).setApprovalForAll(b.address,true));
    await tx(x.connect(b)['safeTransferFrom(address,address,uint256)'](c.address,a.address,1));
    assert.equal(await x.balanceOf(a.address),1n); await rejects(x.ownerOf(99));
    assert.equal(await x.supportsInterface('0x80ac58cd'),true);
    const bad=await deploy('Storage'); await rejects(x['safeTransferFrom(address,address,uint256)'](a.address,await bad.getAddress(),1));
    assert.equal(await x.ownerOf(1),a.address);
  });
  it('EnglishAuction: custody, bid guards, loser refund, winner and seller proceeds', async () => {
    const n=await deploy('SimpleNFT',['NFT','N']); await tx(n.mint(a.address,'uri'));
    const x=await deploy('EnglishAuction',[await n.getAddress(),1,100,3600]);
    await rejects(x.bid({value:100})); await rejects(x.start()); await tx(n.approve(await x.getAddress(),1));
    await tx(x.start()); assert.equal(await n.ownerOf(1),await x.getAddress());
    await rejects(x.bid({value:100})); await tx(x.connect(b).bid({value:100}));
    await rejects(x.connect(c).bid({value:100})); await tx(x.connect(c).bid({value:200}));
    await tx(x.connect(b).withdraw()); await rejects(x.connect(b).withdraw()); await rejects(x.end());
    await advance(); await rejects(x.connect(b).bid({value:300})); await tx(x.end());
    assert.equal(await n.ownerOf(1),c.address); assert.equal(await x.pendingReturns(a.address),200n);
    await tx(x.withdraw()); await rejects(x.end());
  });
  it('EnglishAuction: no bids returns NFT to seller', async () => {
    const n=await deploy('SimpleNFT',['NFT','N']); await tx(n.mint(a.address,''));
    const x=await deploy('EnglishAuction',[await n.getAddress(),1,100,3600]);
    await tx(n.approve(await x.getAddress(),1)); await tx(x.start()); await advance(); await tx(x.end());
    assert.equal(await n.ownerOf(1),a.address);
  });
  it('MultisigWallet: confirmations, revocation, calldata, failure rollback and replay', async () => {
    await rejects(deploy('MultisigWallet',[[a.address,a.address],2]));
    const x=await deploy('MultisigWallet',[[a.address,b.address,c.address],2]); const s=await deploy('Storage');
    await tx(a.sendTransaction({to:await x.getAddress(),value:100}));
    await rejects(x.connect(d).submitTransaction(d.address,10,'0x'));
    await tx(x.submitTransaction(await s.getAddress(),0,s.interface.encodeFunctionData('store',[42])));
    await tx(x.confirmTransaction(0)); await rejects(x.confirmTransaction(0)); await rejects(x.executeTransaction(0));
    await tx(x.connect(b).confirmTransaction(0)); await tx(x.connect(b).revokeConfirmation(0)); await rejects(x.executeTransaction(0));
    await tx(x.connect(c).confirmTransaction(0)); await tx(x.executeTransaction(0));
    assert.equal(await s.retrieve(),42n); await rejects(x.executeTransaction(0));
    await tx(x.submitTransaction(d.address,101,'0x')); await tx(x.confirmTransaction(1)); await tx(x.connect(b).confirmTransaction(1));
    await rejects(x.executeTransaction(1)); assert.equal((await x.transactions(1)).executed,false);
    await tx(x.submitTransaction(d.address,100,'0x')); await tx(x.confirmTransaction(2)); await tx(x.connect(b).confirmTransaction(2));
    await tx(x.executeTransaction(2)); assert.equal((await x.transactions(2)).executed,true);
  });
  it('StakingRewards: prefunding, pro-rata rewards, principal and period rollover', async () => {
    const stake=await deploy('MyToken',['Stake','S',E('10000')]); const reward=await deploy('MyToken',['Reward','R',E('10000')]);
    const x=await deploy('StakingRewards',[await stake.getAddress(),await reward.getAddress()]); const addr=await x.getAddress();
    await rejects(deploy('StakingRewards',[await stake.getAddress(),await stake.getAddress()]));
    await rejects(x.connect(b).fundRewards(100,100)); await rejects(x.stake(0));
    await tx(stake.transfer(b.address,E('100'))); await tx(stake.approve(addr,E('100'))); await tx(stake.connect(b).approve(addr,E('100')));
    await tx(x.stake(E('100'))); await tx(x.connect(b).stake(E('100')));
    await tx(reward.approve(addr,E('2000'))); await tx(x.fundRewards(E('1000'),1000));
    await rejects(x.fundRewards(E('1000'),1000)); await advance(1001);
    assert.equal(await x.earned(a.address),E('500')); assert.equal(await x.earned(b.address),E('500'));
    await tx(x.claimReward()); await tx(x.connect(b).claimReward()); await rejects(x.claimReward());
    assert.equal(await reward.balanceOf(b.address),E('500')); await rejects(x.connect(c).withdraw(1));
    await tx(x.withdraw(E('100'))); await tx(x.connect(b).withdraw(E('100'))); assert.equal(await x.totalStaked(),0n);
    await tx(x.fundRewards(E('1000'),1000)); await advance(1001); assert.equal(await x.earned(b.address),0n);
  });
});
