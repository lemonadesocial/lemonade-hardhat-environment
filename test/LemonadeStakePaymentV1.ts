import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import assert from 'assert';
import BigNumber from "bignumber.js";
import { Contract, ContractTransactionResponse } from 'ethers';
import { ethers, upgrades } from 'hardhat';

import { stringToBytes32 } from "./utils";

import { createSignature, deployAccessRegistry, deployConfigRegistry, getBalances, mintERC20 } from "./helper";

const deployStake = async (signer: SignerWithAddress) => {
  const { accessRegistry } = await deployAccessRegistry(signer);

  const { configRegistry } = await deployConfigRegistry(signer, await accessRegistry.getAddress(), signer.address, 20000);

  const LemonadeStakePayment = await ethers.getContractFactory('LemonadeStakePayment', signer);

  const configRegistryAddress = await configRegistry.getAddress();

  const stakePayment = await upgrades.deployProxy(LemonadeStakePayment, []);

  const tx = await stakePayment.setConfigRegistry(configRegistryAddress);

  await tx.wait();

  return { configRegistry, stakePayment };
}

const salt = stringToBytes32("SALT");

const register = async (ppm: bigint) => {
  const [signer, signer2] = await ethers.getSigners();

  const { configRegistry, stakePayment } = await deployStake(signer);

  const payee = signer2.address;

  const response: ContractTransactionResponse = await stakePayment.connect(signer).register(salt, payee, ppm);

  const receipt = await response.wait();

  const event = receipt?.logs
    .map((log) => {
      try {
        return stakePayment.interface.parseLog(log);
      }
      catch (err) {
        return null;
      }
    })
    .find(event => event?.name === 'VaultRegistered');

  const vault = event?.args[0] as string;

  assert.ok(vault);

  return { configRegistry, stakePayment, vault, signer, signer2 };
}

const stake = async (
  vault: string,
  configRegistry: Contract,
  stakePayment: Contract,
  paymentId: string,
  currency: string,
) => {
  const [_, signer2] = await ethers.getSigners();

  const eventId = "abc";
  const amount = 1000000000;

  const feePPM: bigint = await configRegistry.feePPM();
  const total = new BigNumber(feePPM.toString()).plus(1000000).multipliedBy(amount).div(1000000).toNumber();

  const feeCollected = new Promise<[string, string, bigint]>(
    (resolve) => configRegistry.once('FeeCollected', (eventId, token, amount) => {
      resolve([eventId, token, amount]);
    })
  );

  const isNative = currency === ethers.ZeroAddress;

  if (!isNative) {
    const stakeContractAddress = await stakePayment.getAddress();

    const erc20 = await ethers.getContractAt("ERC20", currency, signer2);

    const tx = await erc20.approve(stakeContractAddress, total);

    await tx.wait();
  }

  const response: ContractTransactionResponse = await stakePayment.connect(signer2).stake(
    vault,
    eventId,
    paymentId,
    currency,
    total,
    { value: isNative ? total : 0, gasLimit: 1000000 },
  );

  const receipt = await response.wait();

  const feeInfo = await feeCollected;

  return { receipt, feeInfo, total, feePPM, eventId, paymentId, currency, amount, guest: signer2.address };
}

async function testWith(currencyResolver: () => Promise<string>) {
  it('should accept stake', async () => {
    const ppm = 900000;
    const { vault, stakePayment, configRegistry } = await register(ppm);
    const currency = await currencyResolver();

    const { paymentId, guest, amount } = await stake(vault, configRegistry, stakePayment, "1", currency);

    const [stakeInfo] = await stakePayment.getStakings([paymentId]);

    assert.strictEqual(stakeInfo[0], guest);
    assert.strictEqual(stakeInfo[1], currency);
    assert.strictEqual(stakeInfo[2], BigInt(amount));
    assert.strictEqual(stakeInfo[3], BigInt(amount * ppm / 1000000));
  });

  it('should throw for already stake payment', async () => {
    const percent = 90;
    const { vault, stakePayment, configRegistry } = await register(percent);
    const currency = await currencyResolver();

    await stake(vault, configRegistry, stakePayment, "1", currency);
    await assert.rejects(stake(vault, configRegistry, stakePayment, "1"));
  });

  it('should refund correctly', async () => {
    const ppm = 900000;
    const [_, signer2] = await ethers.getSigners()
    const { vault, stakePayment, configRegistry, signer } = await register(ppm);
    const currency = await currencyResolver();

    const { paymentId, amount } = await stake(vault, configRegistry, stakePayment, "3", currency);

    const expectedRefund = BigInt(amount * ppm / 1000000);

    //-- generate refund signature
    const signature = await createSignature(signer, ["STAKE_REFUND", paymentId].map(stringToBytes32));

    const { balanceBefore, balanceAfter, fee } = await getBalances(
      signer2.address,
      currency,
      async () => {
        const response: ContractTransactionResponse = await stakePayment.connect(signer2).refund(paymentId, signature);

        const receipt = await response.wait();

        assert.ok(receipt);

        return receipt;
      }
    );

    assert.strictEqual(balanceAfter, balanceBefore - fee + expectedRefund);
  });

  it('should not refund twice', async () => {
    const ppm = 900000;
    const [_, signer2] = await ethers.getSigners()
    const { vault, stakePayment, configRegistry, signer } = await register(ppm);
    const currency = await currencyResolver();

    const { paymentId } = await stake(vault, configRegistry, stakePayment, "3", currency);

    //-- generate refund signature
    const signature = await createSignature(signer, ["STAKE_REFUND", paymentId].map(stringToBytes32));

    await stakePayment.connect(signer2).refund(paymentId, signature);
    await assert.rejects(stakePayment.connect(signer2).refund(paymentId, signature));
  });

  it('should slash multiple payments', async () => {
    const ppm = 900000;
    const { vault, stakePayment, configRegistry, signer, signer2 } = await register(ppm);
    const currency = await currencyResolver();

    const stake1 = await stake(vault, configRegistry, stakePayment, "5", currency);
    const stake2 = await stake(vault, configRegistry, stakePayment, "6", currency);

    const expectedSlashAmount = BigInt(stake1.amount + stake2.amount);

    //-- generate slash signature
    const signature = await createSignature(signer, ["STAKE_SLASH", stake1.paymentId, stake2.paymentId].map(stringToBytes32));

    //-- signer 2 is expecting the slash amount
    const { balanceBefore, balanceAfter } = await getBalances(
      signer2.address,
      currency,
      async () => {
        const response: ContractTransactionResponse = await stakePayment.connect(signer).slash(
          vault,
          [stake1.paymentId, stake2.paymentId],
          signature,
        );

        const receipt = await response.wait();

        assert.ok(receipt);

        return receipt;
      }
    );

    assert.strictEqual(balanceAfter, balanceBefore + expectedSlashAmount);
  });

  it('should not slash twice', async () => {
    const ppm = 900000;
    const { vault, stakePayment, configRegistry, signer } = await register(ppm);
    const currency = await currencyResolver();

    const { paymentId } = await stake(vault, configRegistry, stakePayment, "5", currency);

    const signature = await createSignature(signer, ["STAKE_SLASH", paymentId].map(stringToBytes32));

    await stakePayment.connect(signer).slash(
      vault,
      [paymentId],
      signature,
    );

    await assert.rejects(stakePayment.connect(signer).slash(
      vault,
      [paymentId],
      signature,
    ));
  });
}

describe('LemonadeRelayPaymentV1', function () {
  it('should allow register config', async () => {
    const ppm = 800000n;
    const { vault } = await register(ppm);

    const stakeVault = await ethers.getContractAt("StakeVault", vault);

    const refundPPM = await stakeVault.refundPPM();

    assert.strictEqual(refundPPM, ppm);
  });

  describe('Native currency', function () {
    testWith(() => Promise.resolve(ethers.ZeroAddress));
  });

  describe('ERC20 currency', function () {
    testWith(async () => {
      const [signer1, signer2] = await ethers.getSigners();

      const { address } = await mintERC20(signer1, signer2.address, "TEST", "TST", 1000000000000n);
      return address;
    });
  });
});
