import { BigNumber } from "ethers";
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from 'ethereum-waffle';
import { type SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import assert from 'assert';

interface TxResponse {
  hash: string;
}

const deployFactory = async (signer: SignerWithAddress, ...args: unknown[]) => {
  const LemonadeEscrowFactoryV1 = await ethers.getContractFactory('LemonadeEscrowFactoryV1', signer);
  const escrowFactoryV1 = await LemonadeEscrowFactoryV1.deploy(signer.address, ...args);

  return { escrowFactoryV1 };
}

const deployEscrow = (...args: unknown[]) => async () => {
  const [signer] = await ethers.getSigners();

  const { escrowFactoryV1 } = await deployFactory(signer, ethers.constants.AddressZero, 0);

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

  return { signer, escrowContract };
}

describe('LemonadeEscrowV1', () => {
  it('should deploy factory with fee', async () => {
    const [signer, feeCollector] = await ethers.getSigners();

    const feeAmount = ethers.utils.parseEther(Math.random().toFixed(2));

    const { escrowFactoryV1 } = await deployFactory(signer, feeCollector.address, feeAmount);

    //-- create escrow from this factory and check if feeCollector has been credited
    const balanceBefore = await feeCollector.getBalance();

    await escrowFactoryV1.connect(signer).createEscrow(signer.address, [], [signer.address], [1], 90, [], { value: feeAmount });

    const balanceAfter = await feeCollector.getBalance();

    assert.ok(balanceBefore.add(feeAmount).eq(balanceAfter));
  });

  it('should create escrow contract', async () => {
    const [signer] = await ethers.getSigners();

    const { escrowContract } = await loadFixture(deployEscrow(signer.address, [], [signer.address], [1], 90, []));

    const payees = await escrowContract.connect(signer).totalPayees();

    assert.ok(escrowContract);
    assert.ok(BigNumber.from(1).eq(payees));
  });

  it('should revert for invalid host refund percent', async () => {
    const [signer] = await ethers.getSigners();

    await expect(loadFixture(deployEscrow(signer.address, [], [signer.address], [1], 101, [])))
      .revertedWith('InvalidHostRefundPercent');
  });

  it('should revert for invalid refund percent', async () => {
    const [signer] = await ethers.getSigners();

    const policies = [
      [Math.trunc(Date.now() / 1000), 101],
      [Math.trunc(Date.now() / 1000 + 1), 90],
    ];

    await expect(loadFixture(deployEscrow(signer.address, [], [signer.address], [1], 0, policies)))
      .revertedWith('InvalidRefundPercent');
  });

  it('should revert for invalid refund policies', async () => {
    const [signer] = await ethers.getSigners();

    const policies = [
      [Math.trunc(Date.now() / 1000), 50],
      [Math.trunc(Date.now() / 1000 + 1), 60],
    ];

    await expect(loadFixture(deployEscrow(signer.address, [], [signer.address], [1], 0, policies)))
      .revertedWith('InvalidRefundPolicies');
  });

  it('should throw for amount not matched', async () => {
    const [signer1, signer2] = await ethers.getSigners();

    const { escrowContract } = await loadFixture(deployEscrow(signer1.address, [], [signer1.address], [1], 100, []));

    //-- the custom error could not be parsed by hardhat for some unknown reasons parsing custom error
    await expect(escrowContract.connect(signer2).deposit(1, ethers.constants.AddressZero, 1000, { value: 100 }))
      .revertedWith('');
  });

  it('should deposit', async () => {
    const [signer1, signer2] = await ethers.getSigners();

    const { escrowContract } = await loadFixture(deployEscrow(signer1.address, [], [signer1.address], [1], 100, []));

    const depositAmount = ethers.utils.parseEther('1');

    const tx1 = await escrowContract.connect(signer2).deposit(
      1, ethers.constants.AddressZero, depositAmount,
      { value: depositAmount },
    );

    await escrowContract.connect(signer2).deposit(
      2, ethers.constants.AddressZero, depositAmount,
      { value: depositAmount },
    );

    const allDeposits = await escrowContract.getDeposits([1, 2]);

    assert.ok(allDeposits.length === 2 && allDeposits[0].length === 1 && allDeposits[1].length === 1);

    await expect(tx1)
      .emit(escrowContract, 'GuestDeposit')
      .withArgs(signer2.address, 1, ethers.constants.AddressZero, depositAmount);
  });

  it('should refund correct amount after cancel by guest', async () => {
    const [signer1, signer2] = await ethers.getSigners();

    const policies = [
      [Math.trunc(Date.now() / 1000 - 86400), 50],
      [Math.trunc(Date.now() / 1000 + 86400), 30],
    ];

    const { signer, escrowContract } = await loadFixture(deployEscrow(signer1.address, [], [signer1.address], [1], 0, policies));

    const depositAmount1 = ethers.utils.parseEther(Math.random().toFixed(1));
    const depositAmount2 = ethers.utils.parseEther(Math.random().toFixed(1));
    const refundedAmount = depositAmount1.add(depositAmount2).mul(policies[1][1]).div(100); //-- should return with policies[1] percent
    const paymentId = 1;

    const tx1: TxResponse = await escrowContract.connect(signer2).deposit(
      paymentId, ethers.constants.AddressZero, depositAmount1,
      { value: depositAmount1 },
    );
    await ethers.provider.waitForTransaction(tx1.hash);

    const tx2: TxResponse = await escrowContract.connect(signer2).deposit(
      paymentId, ethers.constants.AddressZero, depositAmount2,
      { value: depositAmount2 },
    );
    await ethers.provider.waitForTransaction(tx2.hash);

    const afterDepositBalance = await signer2.getBalance();

    const signature = await signer.signMessage(
      ethers.utils.arrayify(
        escrowContract.interface._abiCoder.encode(['uint256'], [paymentId])
      )
    );

    const tx3: TxResponse = await escrowContract.connect(signer2).cancelByGuest(paymentId, signature);
    const receipt = await ethers.provider.waitForTransaction(tx3.hash);

    const afterCancelBalance = await signer2.getBalance();

    const gasFee = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice);
    const difference = afterDepositBalance.add(refundedAmount).sub(afterCancelBalance);

    assert.ok(difference.eq(gasFee));
  });

  it('should refund correct amount after cancel by host', async () => {
    const [signer1, signer2] = await ethers.getSigners();

    const hostRefundPercent = Math.trunc(Math.random() * 100);

    const { signer, escrowContract } = await loadFixture(deployEscrow(signer1.address, [], [signer1.address], [1], hostRefundPercent, []));

    const depositAmount = ethers.utils.parseEther(Math.random().toFixed(2));
    const refundedAmount = depositAmount.mul(hostRefundPercent).div(100);
    const paymentId = 1;

    const tx1: TxResponse = await escrowContract.connect(signer2).deposit(
      paymentId, ethers.constants.AddressZero, depositAmount,
      { value: depositAmount },
    );
    await ethers.provider.waitForTransaction(tx1.hash);

    const afterDepositBalance = await signer2.getBalance();

    const tx2: TxResponse = await escrowContract.connect(signer1).cancel(paymentId);
    await ethers.provider.waitForTransaction(tx2.hash);

    const signature = await signer.signMessage(
      ethers.utils.arrayify(
        escrowContract.interface._abiCoder.encode(['uint256'], [paymentId])
      )
    );

    const tx3: TxResponse = await escrowContract.connect(signer2).claimRefund(paymentId, signature);
    const receipt = await ethers.provider.waitForTransaction(tx3.hash);

    const afterClaimBalance = await signer2.getBalance();

    const gasFee = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice);
    const difference = afterDepositBalance.add(refundedAmount).sub(afterClaimBalance);

    assert.ok(difference.eq(gasFee));
  });

  it('should update escrow contract', async () => {
    const [signer] = await ethers.getSigners();

    const [delegate1, delegate2, delegate3] = [ethers.Wallet.createRandom(), ethers.Wallet.createRandom(), ethers.Wallet.createRandom()];

    const { escrowContract } = await loadFixture(
      deployEscrow(signer.address, [delegate1.address, delegate2.address, delegate3.address], [signer.address], [1], 90, [[Math.trunc(Date.now() / 1000 - 86400), 50]])
    );

    const updatedDelegates = [delegate1.address, delegate3.address]; //-- remove delegate2
    const updatedPayees = [signer.address, delegate2.address] //-- add delegate2 as payee
    const updatedShares = [1, 2];
    const updatedRefund = 80;
    const updatedPolicies = [
      [Math.trunc(Date.now() / 1000 - 86400), 50],
      [Math.trunc(Date.now() / 1000 + 86400), 30],
    ];

    const contract = escrowContract.connect(signer);

    const tx: TxResponse = await contract.updateEscrow(updatedDelegates, updatedPayees, updatedShares, updatedRefund, updatedPolicies);
    await ethers.provider.waitForTransaction(tx.hash);

    //-- check updated values
    const delegateRoleId = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ESCROW_DELEGATE_ROLE"));
    const roleMemberCount = await contract.getRoleMemberCount(delegateRoleId);
    const payeesCount = await contract.totalPayees();

    const newDelegates = await Promise.all(
      Array.from(Array(Number(roleMemberCount)).keys()).map((_, index) => contract.getRoleMember(delegateRoleId, index))
    );

    const newPayees = await Promise.all(
      Array.from(Array(Number(payeesCount)).keys()).map((_, index) => contract.payee(index))
    );

    const newShares = await Promise.all(
      updatedPayees.map((payee) => contract.shares(payee))
    );

    const [newRefund, newPolicies] = await Promise.all([
      contract.hostRefundPercent(),
      contract.getRefundPolicies()
    ]);

    assert.deepStrictEqual([signer.address, ...updatedDelegates], newDelegates);
    assert.deepStrictEqual(updatedPayees, newPayees);
    assert.deepStrictEqual(updatedShares, newShares.map(Number));
    assert.deepStrictEqual(updatedRefund, Number(newRefund));
    assert.deepStrictEqual(updatedPolicies, newPolicies.map(([timestamp, percent]: [BigNumber, number]) => [Number(timestamp), percent]));
  });
});
