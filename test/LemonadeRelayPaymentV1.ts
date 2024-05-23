import { ethers, upgrades } from 'hardhat';
import { assert } from 'chai';
import { loadFixture } from 'ethereum-waffle';
import { type SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

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

  return { relayPayment };
}

describe('LemonadeRelayPaymentV1', () => {
  async function register() {
    const [signer, signer2] = await ethers.getSigners();

    const { relayPayment } = await loadFixture(deployRelay(signer));

    const response: TxResponse = await relayPayment.connect(signer).register([signer2.address], [1]);

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

    return { relayPayment, splitter };
  }

  it('should allow register splitter', async () => {
    const { splitter } = await register();

    assert.isNotNull(splitter);
  });

  it('should accept payment', async () => {
    const { splitter, relayPayment } = await register();

    assert.ok(splitter);

    const [_, signer2] = await ethers.getSigners();

    const value = 1000000000;

    const response: TxResponse = await relayPayment.connect(signer2).pay(
      splitter,
      ethers.utils.id("1"),
      ethers.constants.AddressZero,
      value,
      { value, gasLimit: 1000000 },
    );

    await ethers.provider.waitForTransaction(response.hash, 1);

    assert.ok(response.hash);
  });
});
