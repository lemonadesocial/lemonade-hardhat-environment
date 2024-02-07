import { ethers, upgrades } from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from 'ethereum-waffle';

import { expectBalances } from './utils';

const CALL_NETWORK = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('development'));

describe('PassportAsync', () => {
  async function deployFixture() {
    const signers = await ethers.getSigners();

    const BaseV1 = await ethers.getContractFactory('BaseV1');
    const baseV1 = await upgrades.deployProxy(BaseV1, [
      ethers.constants.AddressZero,
      ethers.constants.AddressZero,
      [],
      ethers.constants.AddressZero,
      CALL_NETWORK,
      1,
    ]);

    const PassportV1Call = await ethers.getContractFactory('PassportV1AsyncMock');
    const passportV1Call = await upgrades.deployProxy(PassportV1Call, [
      baseV1.address,
      'Passport',
      'PSP',
      ethers.utils.parseEther('1'),
      ethers.constants.AddressZero,
      ethers.constants.AddressZero,
      5,
      signers[0].address,
      ethers.constants.AddressZero
    ]);

    await baseV1.setCallAddress(passportV1Call.address);

    const CrowdfundV1 = await ethers.getContractFactory('CrowdfundV1');
    const crowdfundV1 = await upgrades.deployProxy(CrowdfundV1, [passportV1Call.address]);

    return { signers, baseV1, passportV1Call, crowdfundV1 };
  }

  describe('PassportV1', () => {
    describe('signer 0', () => {
      it('should reserve and refund without supply', async () => {
        const { signers, passportV1Call } = await loadFixture(deployFixture);

        const verify = await expectBalances([signers[0].address], passportV1Call);

        const [roundIds, price] = await passportV1Call.price();

        const tx = await passportV1Call.connect(signers[0]).reserve(roundIds, [[signers[0].address, 2]], [], { value: price.mul(2) });

        await expect(tx)
          .to.emit(passportV1Call, 'ExecuteReserve').withNamedArgs({ success: false });

        const receipt = await tx.wait();

        await verify([
          (n) => n.sub(receipt.gasUsed.mul(receipt.effectiveGasPrice)),
        ]);
      });
    });
  });

  describe('CrowdloanV1', () => {
    describe('signer 0', () => {
      it('should create', async () => {
        const { signers, crowdfundV1 } = await loadFixture(deployFixture);

        await expect(crowdfundV1.connect(signers[0]).create('title', 'description', [[signers[0].address, 2]]))
          .to.emit(crowdfundV1, 'Create').withNamedArgs({ campaignId: 0 });
      });
    });

    describe('signer 1', () => {
      it('should fund', async () => {
        const { signers, passportV1Call, crowdfundV1 } = await loadFixture(deployFixture);

        const [_, value] = await passportV1Call.price();

        await expect(crowdfundV1.connect(signers[1]).fund(0, { value }))
          .to.emit(crowdfundV1, 'Fund');
      });
    });

    describe('signer 2', () => {
      it('should fund', async () => {
        const { signers, passportV1Call, crowdfundV1 } = await loadFixture(deployFixture);

        const [_, value] = await passportV1Call.price();

        await expect(crowdfundV1.connect(signers[2]).fund(0, { value }))
          .to.emit(crowdfundV1, 'Fund');
      });
    });

    describe('signer 3', () => {
      it('should execute and refund without supply', async () => {
        const { signers, passportV1Call, crowdfundV1 } = await loadFixture(deployFixture);

        const verify = await expectBalances([signers[1].address, signers[2].address], crowdfundV1);

        const [roundIds, amount] = await crowdfundV1.goal(0);

        await expect(crowdfundV1.connect(signers[3]).execute(0, roundIds))
          .to.emit(passportV1Call, 'ExecuteReserve').withNamedArgs({ success: false })
          .to.emit(crowdfundV1, 'StateChanged').withArgs(0, 3);

        await verify([
          (n) => n.add(amount.div(2)),
          (n) => n.add(amount.div(2)),
        ]);
      });
    });
  });
});
