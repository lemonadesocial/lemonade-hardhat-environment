import { BigNumber } from 'ethers';
import { ethers, upgrades } from 'hardhat';
import { loadFixture } from 'ethereum-waffle';
import { type SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import assert from 'assert';

interface TxResponse {
  hash: string;
}

const deployAccessRegistry = async (signer: SignerWithAddress) => {
  const AccessRegistry = await ethers.getContractFactory('AccessRegistry', signer);
  const accessRegistry = await AccessRegistry.deploy();

  const PAYMENT_ADMIN_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('PAYMENT_ADMIN_ROLE'));

  await accessRegistry.grantRole(PAYMENT_ADMIN_ROLE, signer.address);

  return { accessRegistry };
}

const deployConfigRegistry = async (signer: SignerWithAddress, ...args: unknown[]) => {
  const PaymentConfigRegistry = await ethers.getContractFactory('PaymentConfigRegistry', signer);

  const configRegistry = await upgrades.deployProxy(PaymentConfigRegistry, args);

  return { configRegistry };
}

const deployRelay = (signer: SignerWithAddress) => async () => {
  const { accessRegistry } = await deployAccessRegistry(signer);

  const { configRegistry } = await deployConfigRegistry(signer, accessRegistry.address, signer.address, 20000);

  const LemonadeRelayPayment = await ethers.getContractFactory('LemonadeRelayPayment', signer);

  const relayPayment = await upgrades.deployProxy(LemonadeRelayPayment, [configRegistry.address]);

  return { configRegistry, relayPayment };
}

describe('LemonadeRelayPaymentV1', () => {
  async function register() {
    const [signer, signer2] = await ethers.getSigners();

    const { configRegistry, relayPayment } = await loadFixture(deployRelay(signer));

    const payee = signer2.address;

    const response: TxResponse = await relayPayment.connect(signer).register([payee], [1]);

    const receipt = await ethers.provider.waitForTransaction(response.hash, 1);

    const event = receipt.logs
      .map((log) => {
        try {
          return relayPayment.interface.parseLog(log);
        }
        catch (err) {
          return null;
        }
      })
      .find(event => event?.eventFragment.name === 'OnRegister');

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
    const feePPM: BigNumber = await configRegistry.feePPM();
    const eventId = Math.random().toString();
    const paymentId = Math.random().toString();
    const total = feePPM.add(1000000).mul(value).div(1000000);

    const feeCollected = new Promise<[string, BigNumber]>(
      (resolve) => configRegistry.once('FeeCollected', (eventId, token, amount) => {
        resolve([eventId, amount]);
      })
    );

    const response: TxResponse = await relayPayment.connect(signer2).pay(
      splitter,
      eventId,
      paymentId,
      ethers.constants.AddressZero,
      total,
      { value: total.toString(), gasLimit: 1000000 },
    );

    await ethers.provider.waitForTransaction(response.hash, 1);

    const splitterContract = await ethers.getContractAt('PaymentSplitter', splitter);

    const [payment, feeInfo, [pending]] = await Promise.all([
      relayPayment.getPayment(paymentId),
      feeCollected,
      splitterContract['pending(address[],address)']([ethers.constants.AddressZero], payee),
    ]);

    assert.ok(
      response.hash
      && feeInfo[0] === eventId
      && feePPM.mul(value).div(1000000).eq(feeInfo[1])
      && BigNumber.from(pending).add(feeInfo[1]).eq(total)
    );

    assert.ok(
      payment.currency === ethers.constants.AddressZero
      && total.eq(payment.amount),
    );
  });
});
