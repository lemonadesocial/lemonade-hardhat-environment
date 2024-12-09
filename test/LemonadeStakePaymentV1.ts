import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import assert from 'assert';
import BigNumber from "bignumber.js";
import { Contract, ContractTransactionResponse } from 'ethers';
import { ethers, upgrades } from 'hardhat';

import { toId } from "./utils";

const deployAccessRegistry = async (signer: SignerWithAddress) => {
  const AccessRegistry = await ethers.getContractFactory('AccessRegistry', signer);
  const accessRegistry = await AccessRegistry.deploy();

  const PAYMENT_ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes('PAYMENT_ADMIN_ROLE'));

  await accessRegistry.grantRole(PAYMENT_ADMIN_ROLE, signer.address);
  return { accessRegistry };
}

const deployConfigRegistry = async (signer: SignerWithAddress, ...args: unknown[]) => {
  const PaymentConfigRegistry = await ethers.getContractFactory('PaymentConfigRegistry', signer);

  const configRegistry = await upgrades.deployProxy(PaymentConfigRegistry, args);

  return { configRegistry };
}

const deployStake = async (signer: SignerWithAddress) => {
  const { accessRegistry } = await deployAccessRegistry(signer);

  const { configRegistry } = await deployConfigRegistry(signer, await accessRegistry.getAddress(), signer.address, 20000);

  const LemonadeStakePayment = await ethers.getContractFactory('LemonadeStakePayment', signer);

  const configRegistryAddress = await configRegistry.getAddress();

  const stakePayment = await upgrades.deployProxy(LemonadeStakePayment, [configRegistryAddress]);

  return { configRegistry, stakePayment };
}

const register = async (ppm: number) => {
  const [signer, signer2] = await ethers.getSigners();

  const { configRegistry, stakePayment } = await deployStake(signer);

  const payee = signer2.address;

  const response: ContractTransactionResponse = await stakePayment.connect(signer).register(payee, ppm);

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

  const id = event?.args[0] as bigint | undefined;

  assert.ok(id);

  return { configRegistry, stakePayment, id, signer, signer2 };
}

const stake = async (
  id: bigint,
  configRegistry: Contract,
  stakePayment: Contract,
  paymentId: string,
) => {
  const [_, signer2] = await ethers.getSigners();

  const eventId = "abc";
  const currency = ethers.ZeroAddress;
  const amount = 1000000000;

  const feePPM: bigint = await configRegistry.feePPM();
  const total = new BigNumber(feePPM.toString()).plus(1000000).multipliedBy(amount).div(1000000).toNumber();

  const feeCollected = new Promise<[string, bigint]>(
    (resolve) => configRegistry.once('FeeCollected', (eventId, token, amount) => {
      resolve([eventId, amount]);
    })
  );

  const response: ContractTransactionResponse = await stakePayment.connect(signer2).stake(
    id,
    eventId,
    paymentId,
    currency,
    total,
    { value: total, gasLimit: 1000000 },
  );

  const receipt = await response.wait();

  const feeInfo = await feeCollected;

  return { receipt, feeInfo, total, feePPM, eventId, paymentId, currency, amount, address: signer2.address };
}

const createSignature = (signer: SignerWithAddress, type: string, paymentIds: string[]) => {
  const data = [toId(type), ...paymentIds.map(toId)];

  let encoded = "0x";

  for (let i = 0; i < data.length; i++) {
    encoded = ethers.solidityPacked(["bytes", "bytes32"], [encoded, data[i]]);
  }

  return signer.signMessage(
    ethers.getBytes(encoded)
  );
}

describe('LemonadeRelayPaymentV1', () => {
  it('should allow register config', async () => {
    const ppm = 800000;
    const { id, stakePayment } = await register(ppm);

    const config = await stakePayment.configs(id);

    assert.ok(config[2] === BigInt(ppm));
  });

  it('should accept stake', async () => {
    const ppm = 900000;
    const { id, stakePayment, configRegistry } = await register(ppm);

    const { paymentId, address, amount, total } = await stake(id, configRegistry, stakePayment, "1");

    const [stakeInfo] = await stakePayment.getStakings([paymentId]);

    assert.strictEqual(stakeInfo[0], id);
    assert.strictEqual(stakeInfo[1], address);
    assert.strictEqual(stakeInfo[2], ethers.ZeroAddress);
    assert.strictEqual(stakeInfo[3], BigInt(total));
    assert.strictEqual(stakeInfo[4], BigInt(amount));
  });

  it('should throw for already stake payment', async () => {
    const percent = 90;
    const { id, stakePayment, configRegistry } = await register(percent);

    await stake(id, configRegistry, stakePayment, "1");
    await assert.rejects(stake(id, configRegistry, stakePayment, "1"));
  });

  it('should refund correctly', async () => {
    const ppm = 900000;
    const [_, signer2] = await ethers.getSigners()
    const { id, stakePayment, configRegistry, signer } = await register(ppm);

    const { paymentId, amount } = await stake(id, configRegistry, stakePayment, "3");

    const expectedRefund = BigInt(amount * ppm / 1000000);

    //-- const generate refund signature
    const signature = await createSignature(signer, "STAKE_REFUND", [paymentId]);

    const balanceBefore = await ethers.provider.getBalance(signer2.address);

    const response: ContractTransactionResponse = await stakePayment.connect(signer2).refund(paymentId, signature);

    const receipt = await response.wait();

    assert.ok(receipt);

    const balanceAfter = await ethers.provider.getBalance(signer2.address);
    const gasFee = receipt.gasPrice * receipt.gasUsed;

    assert.strictEqual(balanceAfter, balanceBefore - gasFee + expectedRefund);
  });

  it('should not refund twice', async () => {
    const ppm = 900000;
    const [_, signer2] = await ethers.getSigners()
    const { id, stakePayment, configRegistry, signer } = await register(ppm);

    const { paymentId } = await stake(id, configRegistry, stakePayment, "3");

    //-- const generate refund signature
    const signature = await createSignature(signer, "STAKE_REFUND", [paymentId]);

    await stakePayment.connect(signer2).refund(paymentId, signature);
    await assert.rejects(stakePayment.connect(signer2).refund(paymentId, signature));
  });

  it('should slash multiple payments', async () => {
    const ppm = 900000;
    const { id, stakePayment, configRegistry, signer, signer2 } = await register(ppm);

    const stake1 = await stake(id, configRegistry, stakePayment, "5");
    const stake2 = await stake(id, configRegistry, stakePayment, "6");

    const expectedRefund = BigInt(stake1.amount + stake2.amount);

    //-- const generate refund signature
    const signature = await createSignature(signer, "STAKE_SLASH", [stake1.paymentId, stake2.paymentId]);

    const balanceBefore = await ethers.provider.getBalance(signer2.address);

    const response: ContractTransactionResponse = await stakePayment.connect(signer).slash(
      id,
      [stake1.paymentId, stake2.paymentId],
      signature,
    );

    const receipt = await response.wait();

    assert.ok(receipt);

    const balanceAfter = await ethers.provider.getBalance(signer2.address);

    assert.strictEqual(balanceAfter, balanceBefore + expectedRefund);
  });

  it('should not slash twice', async () => {
    const ppm = 900000;
    const { id, stakePayment, configRegistry, signer } = await register(ppm);

    const { paymentId } = await stake(id, configRegistry, stakePayment, "5");

    const signature = await createSignature(signer, "STAKE_SLASH", [paymentId]);

    await stakePayment.connect(signer).slash(
      id,
      [paymentId],
      signature,
    );

    await assert.rejects(stakePayment.connect(signer).slash(
      id,
      [paymentId],
      signature,
    ));
  });
});
