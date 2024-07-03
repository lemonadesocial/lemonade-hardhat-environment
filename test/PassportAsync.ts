import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import BigNumber from 'bignumber.js';
import { expect } from 'chai';
import { Contract } from "ethers";
import { ethers, upgrades } from 'hardhat';

import { expectBalances, expectEmittedEventWithArgs, toHex } from './utils';

const CALL_NETWORK = ethers.keccak256(ethers.toUtf8Bytes('development'));

describe('PassportAsync', () => {
  async function deployFixture() {
    const signers = await ethers.getSigners();

    const BaseV1 = await ethers.getContractFactory('BaseV1');
    const baseV1 = await upgrades.deployProxy(BaseV1, [
      ethers.ZeroAddress,
      ethers.ZeroAddress,
      [],
      ethers.ZeroAddress,
      CALL_NETWORK,
      1,
    ]);

    const baseV1Address = await baseV1.getAddress();

    const PassportV1Call = await ethers.getContractFactory('PassportV1AsyncMock');
    const passportV1Call = await upgrades.deployProxy(PassportV1Call, [
      baseV1Address,
      'Passport',
      'PSP',
      ethers.parseEther('1'),
      ethers.ZeroAddress,
      ethers.ZeroAddress,
      5,
      signers[0].address,
      ethers.ZeroAddress,
    ]);

    const passportV1CallAddress = await passportV1Call.getAddress();

    await baseV1.setCallAddress(passportV1CallAddress);

    const CrowdfundV1 = await ethers.getContractFactory('CrowdfundV1');
    const crowdfundV1 = await upgrades.deployProxy(CrowdfundV1, [passportV1CallAddress]);

    const crowdfundV1Address = await crowdfundV1.getAddress();
    const crowdfundV1Target = crowdfundV1.target;

    return { signers, baseV1, passportV1Call, crowdfundV1, baseV1Address, passportV1CallAddress, crowdfundV1Address, crowdfundV1Target };
  }

  describe('PassportV1', () => {
    describe('signer 0', () => {
      it('should reserve and refund without supply', async () => {
        const { signers, passportV1Call } = await loadFixture(deployFixture);

        const verify = await expectBalances([signers[0].address], passportV1Call);

        const [roundIds, price] = await passportV1Call.price();

        const tx = await passportV1Call
          .connect(signers[0])
          .reserve(
            roundIds,
            [[signers[0].address, 2]],
            ethers.toUtf8Bytes(''),
            { value: toHex(new BigNumber(price.toString()).multipliedBy(2)) },
          );

        await expectEmittedEventWithArgs(passportV1Call, tx, 'ExecuteReserve', { success: false });

        const receipt = await tx.wait();

        await verify([
          (n) => n.minus(new BigNumber(receipt.gasUsed.toString()).multipliedBy(receipt.gasPrice.toString())),
        ]);
      });
    });
  });

  describe('CrowdloanV1', () => {
    let signers: HardhatEthersSigner[];
    let crowdfundV1: Contract;
    let passportV1Call: Contract;

    before(async function () {
      const fixture = await loadFixture(deployFixture);
      signers = fixture.signers;
      crowdfundV1 = fixture.crowdfundV1;
      passportV1Call = fixture.passportV1Call;
    });

    describe('signer 0', () => {
      it('should create', async () => {
        const tx = await crowdfundV1.connect(signers[0]).create('title', 'description', [[signers[0].address, 2]]);

        await expectEmittedEventWithArgs(crowdfundV1, tx, 'Create', { campaignId: 0 });
      });
    });

    describe('signer 1', () => {
      it('should fund', async () => {
        const [_, value] = await passportV1Call.price();

        await expect(crowdfundV1.connect(signers[1]).fund(0, { value }))
          .to.emit(crowdfundV1, 'Fund');
      });
    });

    describe('signer 2', () => {
      it('should fund', async () => {
        const [_, value] = await passportV1Call.price();

        await expect(crowdfundV1.connect(signers[2]).fund(0, { value }))
          .to.emit(crowdfundV1, 'Fund');
      });
    });

    describe('signer 3', () => {
      it('should execute and refund without supply', async () => {
        const verify = await expectBalances([signers[1].address, signers[2].address], crowdfundV1);

        const [roundIds, amount] = await crowdfundV1.goal(0);

        const tx = await crowdfundV1.connect(signers[3]).execute(0, roundIds);

        await expectEmittedEventWithArgs(passportV1Call, tx, 'ExecuteReserve', { success: false });

        await expect(tx)
          .to.emit(crowdfundV1, 'StateChanged').withArgs(0, 3);

        await verify([
          (n) => n.plus(new BigNumber(amount).div(2)),
          (n) => n.plus(new BigNumber(amount).div(2)),
        ]);
      });
    });
  });
});
