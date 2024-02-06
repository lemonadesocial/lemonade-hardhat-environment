import { ethers } from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from 'ethereum-waffle';
import assert from 'assert';

interface TxResponse {
  hash: string;
}

const deployFactory = async () => {
  const [signer] = await ethers.getSigners();

  const LemonadeEscrowFactoryV1 = await ethers.getContractFactory('LemonadeEscrowFactoryV1', signer);
  const escrowFactoryV1 = await LemonadeEscrowFactoryV1.deploy();

  return { signer, escrowFactoryV1 }
}

const deployEscrow = (...args: unknown[]) => async () => {
  const { signer, escrowFactoryV1 } = await deployFactory();

  const response: { hash: string } = await escrowFactoryV1.connect(signer).createEscrow(...args);

  const receipt = await ethers.provider.waitForTransaction(response.hash, 1);

  const event = receipt.logs
    .map((log) => {
      try {
        return escrowFactoryV1.interface.parseLog(log);
      }
      catch (err) {
        return null;
      }
    })
    .find(event => event?.name === 'EscrowCreated');

  const escrowAddress = event?.args[0];

  assert.ok(escrowAddress);

  const escrowContract = await ethers.getContractAt('LemonadeEscrowV1', escrowAddress);

  return { escrowContract };
}

describe('LemonadeEscrowV1', () => {
  it('should create escrow contract', async () => {
    const [signer] = await ethers.getSigners();

    const { escrowContract } = await loadFixture(deployEscrow(signer.address, [], [signer.address], [1], 90, []));

    assert.ok(escrowContract);
  });

  it('should revert for invalid host refund percent', async () => {
    const [signer] = await ethers.getSigners();

    await expect(loadFixture(deployEscrow(signer.address, [], [signer.address], [1], 101, [])))
      .revertedWith('Invalid hostRefundPercent');
  });

  it('should revert for invalid refund percent', async () => {
    const [signer] = await ethers.getSigners();

    const policies = [
      [Math.trunc(Date.now() / 1000), 101],
      [Math.trunc(Date.now() / 1000 + 1), 90],
    ];

    await expect(loadFixture(deployEscrow(signer.address, [], [signer.address], [1], 0, policies)))
      .revertedWith('Invalid refund percent');
  });

  it('should revert for invalid refund policies', async () => {
    const [signer] = await ethers.getSigners();

    const policies = [
      [Math.trunc(Date.now() / 1000), 50],
      [Math.trunc(Date.now() / 1000 + 1), 60],
    ];

    await expect(loadFixture(deployEscrow(signer.address, [], [signer.address], [1], 0, policies)))
      .revertedWith('Invalid refund policy order & percent');
  });

  it('should throw for amount not matched', async () => {
    const [signer1, signer2] = await ethers.getSigners();

    const { escrowContract } = await loadFixture(deployEscrow(signer1.address, [], [signer1.address], [1], 100, []));

    await expect(escrowContract.connect(signer2).deposit(1, ethers.constants.AddressZero, 1000))
      .revertedWith('Amount not matched');
  });

  it('should deposit', async () => {
    const [signer1, signer2] = await ethers.getSigners();

    const { escrowContract } = await loadFixture(deployEscrow(signer1.address, [], [signer1.address], [1], 100, []));

    const depositAmount = ethers.utils.parseEther('1');

    const tx = await escrowContract.connect(signer2).deposit(
      1, ethers.constants.AddressZero, depositAmount,
      { value: depositAmount },
    );

    await expect(tx)
      .emit(escrowContract, 'GuestDeposit')
      .withArgs(signer2.address, 1, ethers.constants.AddressZero, depositAmount);
  });

  it('should refund correct amount after cancel by guest', async () => {
    const [signer1, signer2] = await ethers.getSigners();

    const policies = [
      [Math.trunc(Date.now() / 1000 - 86400), 50],
      [Math.trunc(Date.now() / 1000 + 86400), 30],
    ];

    const { escrowContract } = await loadFixture(deployEscrow(signer1.address, [], [signer1.address], [1], 0, policies));

    const depositAmount = ethers.utils.parseEther('1');
    const refundedAmount = depositAmount.mul(policies[1][1]).div(100); //-- should return with pocilies[1] percent

    const tx1: TxResponse = await escrowContract.connect(signer2).deposit(
      1, ethers.constants.AddressZero, depositAmount,
      { value: depositAmount },
    );
    await ethers.provider.waitForTransaction(tx1.hash);

    const afterDepositBalance = await signer2.getBalance();

    const tx2: TxResponse = await escrowContract.connect(signer2).cancelByGuest(1);
    const receipt = await ethers.provider.waitForTransaction(tx2.hash);

    const afterCancelBalance = await signer2.getBalance();

    const gasFee = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice);
    const difference = afterDepositBalance.add(refundedAmount).sub(afterCancelBalance);

    assert.ok(difference.eq(gasFee));
  });
});
