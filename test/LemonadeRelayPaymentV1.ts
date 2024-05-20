import { ethers, upgrades } from 'hardhat';
import { expect } from 'chai';
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

const deployRelay = (signer: SignerWithAddress, feeVault: string) => async () => {
  const { accessRegistry } = await deployAccessRegistry(signer);

  const { configRegistry } = await deployConfigRegistry(signer, accessRegistry.address, signer.address, feeVault, 20000);

  const LemonadeRelayPayment = await ethers.getContractFactory('LemonadeRelayPayment', signer);

  const relayPayment = await upgrades.deployProxy(LemonadeRelayPayment, [configRegistry.address]);

  return { relayPayment };
}

describe('LemonadeRelayPaymentV1', () => {
  it('should allow register splitter', async () => {
    const [signer, signer2] = await ethers.getSigners();

    const { relayPayment } = await loadFixture(deployRelay(signer, signer.address));

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

    const splitterAddress = event?.args[0];

    expect(splitterAddress).to.not.be.null;
  });
});
