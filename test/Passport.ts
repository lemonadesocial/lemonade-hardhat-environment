import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import BigNumber from 'bignumber.js';
import { expect } from 'chai';
import { Contract, Signer } from 'ethers';
import { ethers, upgrades } from 'hardhat';

import { expectBalances, expectEmittedEventWithArgs, toHex } from './utils';

const CALL_NETWORK = ethers.keccak256(ethers.toUtf8Bytes('development'));
const USERNAME_KEY = ethers.keccak256(ethers.toUtf8Bytes('username'));
const USERNAME_VALUE = ethers.toUtf8Bytes('chris');
const EMPTY_BYTES = ethers.toUtf8Bytes('');

describe('Passport', function () {
  async function deployPriceFeed(signer: Signer, decimals: number, rounds: { roundId: string, answer: string; timestamp: string | number }[]) {
    const PriceFeed = await ethers.getContractFactory('PriceFeedMock', signer);

    const priceFeed = await PriceFeed.deploy(
      decimals,
      rounds.map((round) => ([
        round.roundId,
        round.answer,
        round.timestamp,
        round.timestamp,
        round.roundId,
      ])),
    );

    return priceFeed;
  }

  async function deployFixture() {
    const signers = await ethers.getSigners();

    const BaseV1 = await ethers.getContractFactory('BaseV1');
    const baseV1 = await upgrades.deployProxy(BaseV1, [
      ethers.ZeroAddress,
      ethers.ZeroAddress,
      [],
      ethers.ZeroAddress,
      CALL_NETWORK,
      10,
    ]);

    const timestamp = Math.floor(Date.now() / 1000);
    const priceFeed1 = await deployPriceFeed(signers[0], 8, [ // ETH / USD
      { roundId: '0x0200000000005c42e1', answer: '0x25d7d45da8', timestamp: '0x64fdd249' },
      { roundId: '0x0200000000005c5bbc', answer: '0x2565572580', timestamp }
    ]);
    const priceFeed2 = await deployPriceFeed(signers[0], 8, [ // MATIC / USD
      { roundId: '0x0200000000005bddbd', answer: '0x03211620', timestamp: '0x64fdd27b' },
      { roundId: '0x0200000000005bf698', answer: '0x03122200', timestamp },
    ]);

    const PassportV1Call = await ethers.getContractFactory('PassportV1Call');
    const passportV1Call = await upgrades.deployProxy(PassportV1Call, [
      baseV1.target,
      'Passport',
      'PSP',
      ethers.parseEther('1'),
      priceFeed1.target,
      priceFeed2.target,
      5,
      signers[0].address,
      ethers.ZeroAddress
    ]);

    await baseV1.setCallAddress(passportV1Call.target);

    const CrowdfundV1 = await ethers.getContractFactory('CrowdfundV1');
    const crowdfundV1 = await upgrades.deployProxy(CrowdfundV1, [passportV1Call.target]);

    return { signers, baseV1, passportV1Call, crowdfundV1 };
  }

  let signers: HardhatEthersSigner[];
  let passportV1Call: Contract;
  let baseV1: Contract;
  let crowdfundV1: Contract;

  this.beforeAll(async function () {
    const fixture = await loadFixture(deployFixture);
    signers = fixture.signers;
    passportV1Call = fixture.passportV1Call;
    baseV1 = fixture.baseV1;
    crowdfundV1 = fixture.crowdfundV1;
  });

  describe('PassportV1', function () {
    it('should have price', async () => {
      const [_, price] = await passportV1Call.price();

      expect(ethers.formatEther(price)).to.equal('3117.507763975155279503');
    });

    it('should have price at', async () => {
      const [roundIds, price] = await passportV1Call.price();

      expect(await passportV1Call.priceAt(roundIds)).to.equal(price);
    });

    describe('signer 1', () => {
      it('should not withdraw without admin', async () => {
        const balance = await ethers.provider.getBalance(passportV1Call.target);

        await expect(passportV1Call.connect(signers[1]).withdraw(signers[1].address, balance))
          .to.be.revertedWith(/^AccessControl: account .* is missing role/);
      });

      it('should not assign without reservation', async () => {
        await expect(passportV1Call.connect(signers[1]).assign([[signers[2].address, 1]]))
          .to.be.revertedWithCustomError(passportV1Call, 'Forbidden');
      });

      it('should not claim without reservation', async () => {
        await expect(passportV1Call.connect(signers[1]).claim())
          .to.be.revertedWithCustomError(passportV1Call, 'Forbidden');
      });

      it('should not purchase with smaller value', async () => {
        const [roundIds, value] = await passportV1Call.price();

        await expect(passportV1Call.connect(signers[1])
          .purchase(
            roundIds,
            ethers.ZeroAddress,
            EMPTY_BYTES,
            { value: (value as bigint) - 1n },
          ))
          .to.be.revertedWithCustomError(passportV1Call, 'Forbidden');
      });

      it('should purchase', async () => {
        const [roundIds, value] = await passportV1Call.price();

        await expect(passportV1Call.connect(signers[1]).purchase(roundIds, ethers.ZeroAddress, EMPTY_BYTES, { value }))
          .to.emit(passportV1Call, 'Transfer').withArgs(ethers.ZeroAddress, signers[1].address, 1);
      });

      it('should have balance of', async () => {
        expect(await passportV1Call.balanceOf(signers[1].address)).to.eq(1);
      });

      it('should have owner of', async () => {
        expect(await passportV1Call.ownerOf(1)).to.eq(signers[1].address);
      });

      it('should have token', async () => {
        expect(await passportV1Call.token(signers[1].address)).to.eq(1);
      });

      it('should not purchase again', async () => {
        const [roundIds, value] = await passportV1Call.price();

        await expect(passportV1Call.connect(signers[1]).purchase(roundIds, ethers.ZeroAddress, EMPTY_BYTES, { value }))
          .to.be.revertedWithCustomError(passportV1Call, 'Forbidden');
      });
    });

    describe('signer 2', function () {
      it('should reserve', async () => {
        const [roundIds, value] = await passportV1Call.price();

        await expect(
          passportV1Call
            .connect(signers[2])
            .reserve(roundIds, [[signers[2].address, 2]], EMPTY_BYTES, { value: (value as bigint) * 2n })
        ).to.emit(passportV1Call, 'ExecuteReserve');
      });

      it('should claim', async () => {
        await expect(passportV1Call.connect(signers[2]).claim())
          .to.emit(passportV1Call, 'Transfer').withArgs(ethers.ZeroAddress, signers[2].address, 2);
      });

      it('should not claim again', async () => {
        await expect(passportV1Call.connect(signers[2]).claim())
          .to.be.revertedWithCustomError(passportV1Call, 'Forbidden');
      });

      it('should not purchase again', async () => {
        const [roundIds, value] = await passportV1Call.price();

        await expect(passportV1Call.connect(signers[2]).purchase(roundIds, ethers.ZeroAddress, EMPTY_BYTES, { value }))
          .to.be.revertedWithCustomError(passportV1Call, 'Forbidden');
      });

      it('should set property', async () => {
        await expect(passportV1Call.connect(signers[2]).setProperty(USERNAME_KEY, USERNAME_VALUE))
          .to.emit(passportV1Call, 'SetProperty').withArgs(2, USERNAME_KEY, ethers.hexlify(USERNAME_VALUE));
      });

      it('should have property', async () => {
        expect(await passportV1Call.property(2, USERNAME_KEY)).to.eq(ethers.hexlify(USERNAME_VALUE));
      });

      it('should assign to signer 3', async () => {
        await expect(passportV1Call.connect(signers[2]).assign([[signers[3].address, 1]]))
          .to.emit(passportV1Call, 'Assign');
      });
    });

    describe('signer 3', () => {
      it('should not set property without passport', async () => {
        await expect(passportV1Call.connect(signers[3]).setProperty(USERNAME_KEY, USERNAME_VALUE))
          .to.be.revertedWithCustomError(passportV1Call, 'Forbidden');
      });

      it('should claim', async () => {
        await expect(passportV1Call.connect(signers[3]).claim())
          .to.emit(passportV1Call, 'Transfer').withArgs(ethers.ZeroAddress, signers[3].address, 3);
      });

      it('should set property batch', async () => {
        const tx = await passportV1Call.connect(signers[3]).setPropertyBatch([[USERNAME_KEY, USERNAME_VALUE]]);

        await expectEmittedEventWithArgs(
          passportV1Call,
          tx,
          'SetPropertyBatch',
          { tokenId: 3 },
        );
      });

      it('should have property', async () => {
        expect(await passportV1Call.property(3, USERNAME_KEY)).to.eq(ethers.hexlify(USERNAME_VALUE));
      });
    });

    describe('signer 4', () => {
      it('should purchase with invalid referral without cashback', async () => {
        const verify = await expectBalances([signers[0].address, signers[4].address, signers[5].address], passportV1Call);

        const [roundIds, value] = await passportV1Call.price();

        const tx = await passportV1Call.connect(signers[4]).purchase(roundIds, signers[5].address, EMPTY_BYTES, { value });

        await expect(tx)
          .to.emit(passportV1Call, 'Transfer').withArgs(ethers.ZeroAddress, signers[4].address, 4);

        const receipt = await tx.wait();

        await verify([
          (n) => n.plus(value),
          (n) => n.minus(value).minus(new BigNumber(receipt.gasUsed).multipliedBy(receipt.gasPrice)),
          (n) => n,
        ]);
      });
    });

    describe('signer 5', () => {
      it('should reserve without passport without cashback', async () => {
        const verify = await expectBalances([signers[0].address, signers[5].address], passportV1Call);

        const [roundIds, value] = await passportV1Call.price();

        const tx = await passportV1Call.connect(signers[5]).reserve(roundIds, [[signers[5].address, 1]], EMPTY_BYTES, { value });

        await expect(tx)
          .to.emit(passportV1Call, 'ExecuteReserve');

        const receipt = await tx.wait();

        await verify([
          (n) => n.plus(value),
          (n) => n.minus(value).minus(new BigNumber(receipt.gasUsed).multipliedBy(receipt.gasPrice)),
        ]);
      });

      it('should purchase with referral with cashback', async () => {
        const verify = await expectBalances([signers[0].address, signers[4].address, signers[5].address], passportV1Call);

        const [roundIds, value] = await passportV1Call.price();

        const tx = await passportV1Call.connect(signers[5]).purchase(roundIds, signers[4].address, EMPTY_BYTES, { value });

        await expect(tx)
          .to.emit(passportV1Call, 'Transfer').withArgs(ethers.ZeroAddress, signers[5].address, 5);

        const receipt = await tx.wait();

        const cashback = new BigNumber(value).multipliedBy(5).div(100).toFixed(0);
        await verify([
          (n) => n.plus(value).minus(cashback).minus(cashback),
          (n) => n.plus(cashback),
          (n) => n.minus(value).minus(new BigNumber(receipt.gasUsed).multipliedBy(receipt.gasPrice)).plus(cashback),
        ]);
      });

      it('should reserve with cashback with passport', async () => {
        const verify = await expectBalances([signers[0].address, signers[5].address], passportV1Call);

        const [roundIds, value] = await passportV1Call.price();

        const tx = await passportV1Call.connect(signers[5]).reserve(roundIds, [[signers[5].address, 1]], EMPTY_BYTES, { value });

        await expect(tx)
          .to.emit(passportV1Call, 'ExecuteReserve');

        const receipt = await tx.wait();

        const cashback = new BigNumber(value).multipliedBy(5).div(100).toFixed(0);
        await verify([
          (n) => n.plus(value).minus(cashback),
          (n) => n.minus(value).minus(new BigNumber(receipt.gasUsed).multipliedBy(receipt.gasPrice)).plus(cashback),
        ]);
      });
    });

    describe('signer 0', () => {
      it('should withdraw', async () => {
        const verify = await expectBalances([passportV1Call.target, signers[1].address], passportV1Call);

        const balance = await ethers.provider.getBalance(passportV1Call.target);

        await passportV1Call.connect(signers[0]).withdraw(signers[1].address, balance);

        await verify([
          (n) => n.minus(balance.toString()),
          (n) => n.plus(balance.toString()),
        ]);
      });
    });
  });

  describe('BaseV1', () => {
    it('should have total supply', async () => {
      expect(await baseV1.totalSupply()).to.eq(5);
    });

    it('should have total reservations', async () => {
      expect(await baseV1.totalReservations()).to.eq(2);
    });

    describe('signer 1', () => {
      it('should not grant without admin', async () => {
        await expect(baseV1.connect(signers[1]).grant([[signers[1].address, 1]]))
          .to.be.revertedWith(/^AccessControl: account .* is missing role/);
      });

      it('should have balance of', async () => {
        expect(await baseV1.balanceOf(signers[1].address)).to.eq(1);
      });

      it('should have network of', async () => {
        expect(await baseV1.networkOf(1)).to.eq(CALL_NETWORK);
      });

      it('should have owner of', async () => {
        expect(await baseV1.ownerOf(1)).to.eq(signers[1].address);
      });

      it('should have token', async () => {
        expect(await baseV1.token(signers[1].address)).to.eq(1);
      });
    });

    describe('signer 5', () => {
      it('should assign to signer 6', async () => {
        await expect(baseV1.connect(signers[5]).assign([[signers[6].address, 2]]))
          .to.emit(baseV1, 'Assign');
      });

      it('should have no reservations', async () => {
        expect(await baseV1.reservations(signers[5].address)).to.eq(0);
      });

      it('should have referrals', async () => {
        expect(await baseV1.referrals(signers[5].address)).to.eq(2);
      });
    });

    describe('signer 6', () => {
      it('should have reservations', async () => {
        expect(await baseV1.reservations(signers[6].address)).to.eq(2);
      });

      it('should claim', async () => {
        await expect(baseV1.connect(signers[6]).claim(CALL_NETWORK))
          .to.emit(baseV1, 'Mint').withArgs(CALL_NETWORK, signers[6].address, 6);
      });

      it('should have balance of', async () => {
        expect(await baseV1.balanceOf(signers[6].address)).to.eq(1);
      });

      it('should have network of', async () => {
        expect(await baseV1.networkOf(6)).to.eq(CALL_NETWORK);
      });

      it('should have owner of', async () => {
        expect(await baseV1.ownerOf(6)).to.eq(signers[6].address);
      });

      it('should have token', async () => {
        expect(await baseV1.token(signers[6].address)).to.eq(6);
      });
    });

    describe('signer 0', () => {
      it('should grant signer 7', async () => {
        await baseV1.connect(signers[0]).grant([[signers[7].address, 1]]);

        expect(await baseV1.reservations(signers[7].address)).to.eq(1);
      });
    });
  });

  describe('Combined', () => {
    describe('signer 7', () => {
      it('should claim', async () => {
        await expect(baseV1.connect(signers[7]).claim(CALL_NETWORK))
          .to.emit(baseV1, 'Mint').withArgs(CALL_NETWORK, signers[7].address, 7)
          .to.emit(passportV1Call, 'Transfer').withArgs(ethers.ZeroAddress, signers[7].address, 7);
      });
    });
  });

  describe('CrowdfundV1', () => {
    describe('executable', () => {
      describe('signer 8', () => {
        it('should create', async () => {
          const tx = await crowdfundV1.connect(signers[8]).create('title', 'description', [[signers[10].address, 1]]);
          await expectEmittedEventWithArgs(crowdfundV1, tx, 'Create', { campaignId: 0 });
        });

        it('should have state', async () => {
          expect(await crowdfundV1.state(0)).to.equal(0);
        });

        it('should not execute without fund', async () => {
          const [roundIds] = await crowdfundV1.goal(0);

          await expect(crowdfundV1.connect(signers[8]).execute(0, roundIds))
            .to.be.revertedWithCustomError(crowdfundV1, 'Forbidden');
        });

        it('should fund', async () => {
          const [_, price] = await passportV1Call.price();

          await expect(crowdfundV1.connect(signers[8]).fund(0, { value: toHex(new BigNumber(price).plus(100)) }))
            .to.emit(crowdfundV1, 'Fund');
        });
      });

      describe('signer 9', () => {
        it('should execute and refund additional', async () => {
          const verify = await expectBalances([signers[0].address, signers[8].address], crowdfundV1);

          const [roundIds, amount] = await crowdfundV1.goal(0);

          await expect(crowdfundV1.connect(signers[9]).execute(0, roundIds))
            .to.emit(passportV1Call, 'ExecuteReserve')
            .to.emit(crowdfundV1, 'StateChanged').withArgs(0, 2);

          await verify([
            (n) => n.plus(amount),
            (n) => n.plus(100),
          ]);
        });

        it('should have state', async () => {
          expect(await crowdfundV1.state(0)).to.equal(2);
        });
      });
    });

    describe('refundable', async () => {
      describe('signer 1', () => {
        it('should create', async () => {
          const tx = await crowdfundV1.connect(signers[1]).create('title', 'description', [[signers[10].address, 1]]);
          await expectEmittedEventWithArgs(crowdfundV1, tx, 'Create', { campaignId: 1 });
        });
      });

      describe('signer 2', () => {
        it('should fund', async () => {
          const [_, price] = await passportV1Call.price();

          await expect(crowdfundV1.connect(signers[2]).fund(1, { value: price }))
            .to.emit(crowdfundV1, 'Fund');
        });
      });

      describe('signer 3', () => {
        it('should fund', async () => {
          const [_, price] = await passportV1Call.price();

          await expect(crowdfundV1.connect(signers[3]).fund(1, { value: price }))
            .to.emit(crowdfundV1, 'Fund');
        });

        it('should not refund without creator', async () => {
          await expect(crowdfundV1.connect(signers[3]).refund(1))
            .to.be.revertedWithCustomError(crowdfundV1, 'Forbidden');
        });
      });

      describe('signer 1', async () => {
        it('should refund', async () => {
          const verify = await expectBalances([signers[2].address, signers[3].address], crowdfundV1);

          await crowdfundV1.connect(signers[1]).refund(1);

          const [_, price] = await passportV1Call.price();

          await verify([
            (n) => n.plus(price),
            (n) => n.plus(price),
          ]);
        });

        it('should have state', async () => {
          expect(await crowdfundV1.state(1)).to.equal(3);
        });

        it('should not refund again', async () => {
          await expect(crowdfundV1.connect(signers[1]).refund(1))
            .to.be.revertedWithCustomError(crowdfundV1, 'Forbidden');
        });
      });
    });
  });
});
