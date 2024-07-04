import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import assert from 'assert';
import BigNumber from "bignumber.js";
import { ContractTransactionResponse } from 'ethers';
import { ethers, upgrades } from 'hardhat';

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

const deployRelay = async (signer: SignerWithAddress) => {
  const { accessRegistry } = await deployAccessRegistry(signer);

  const { configRegistry } = await deployConfigRegistry(signer, await accessRegistry.getAddress(), signer.address, 20000);

  const LemonadeRelayPayment = await ethers.getContractFactory('LemonadeRelayPayment', signer);

  const configRegistryAddress = await configRegistry.getAddress();

  const relayPayment = await upgrades.deployProxy(LemonadeRelayPayment, [configRegistryAddress]);

  return { configRegistry, relayPayment };
}

describe('LemonadeRelayPaymentV1', () => {
  async function register() {
    const [signer, signer2] = await ethers.getSigners();

    const { configRegistry, relayPayment } = await deployRelay(signer);

    const payee = signer2.address;

    const response: ContractTransactionResponse = await relayPayment.connect(signer).register([payee], [1]);

    const receipt = await response.wait();

    const event = receipt?.logs
      .map((log) => {
        try {
          return relayPayment.interface.parseLog(log);
        }
        catch (err) {
          return null;
        }
      })
      .find(event => event?.name === 'OnRegister');

    const splitter = event?.args[0] as string | undefined;

    return { configRegistry, relayPayment, splitter, payee };
  }

  it('should allow register splitter', async () => {
    const { splitter } = await register();

    assert.ok(splitter);
  });

  it('should accept payment', async () => {
    const { splitter, relayPayment, configRegistry, payee } = await register();

    assert.ok(splitter);

    const [_, signer2] = await ethers.getSigners();

    const value = 1000000000;
    const feePPM: bigint = await configRegistry.feePPM();
    const eventId = Math.random().toString();
    const paymentId = Math.random().toString();
    const total = new BigNumber(feePPM.toString()).plus(1000000).multipliedBy(value).div(1000000).toNumber();

    const feeCollected = new Promise<[string, bigint]>(
      (resolve) => configRegistry.once('FeeCollected', (eventId, token, amount) => {
        resolve([eventId, amount]);
      })
    );

    const response: ContractTransactionResponse = await relayPayment.connect(signer2).pay(
      splitter,
      eventId,
      paymentId,
      ethers.ZeroAddress,
      total,
      { value: total, gasLimit: 1000000 },
    );

    await response.wait();

    const splitterContract = await ethers.getContractAt('PaymentSplitter', splitter);

    const [payment, feeInfo, [pending]] = await Promise.all([
      relayPayment.getPayment(paymentId),
      feeCollected,
      splitterContract['pending(address[],address)']([ethers.ZeroAddress], payee),
    ]);

    assert.ok(
      response.hash
      && feeInfo[0] === eventId
      && new BigNumber(feePPM.toString()).multipliedBy(value).div(1000000).eq(feeInfo[1].toString())
      && new BigNumber(pending.toString()).plus(feeInfo[1].toString()).eq(total)
    );

    assert.ok(
      payment.currency === ethers.ZeroAddress
      && new BigNumber(payment.amount.toString()).eq(total),
    );
  });
});
