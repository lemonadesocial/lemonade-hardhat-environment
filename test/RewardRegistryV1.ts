import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import assert from 'assert';
import { expect } from 'chai';
import { ContractTransactionResponse } from 'ethers';
import { ethers, upgrades } from 'hardhat';

import { numberToBytes32, stringToBytes32 } from "./utils";

import { createSignature, deployAccessRegistry, deployConfigRegistry, getBalances, mintERC20 } from "./helper";

const deployRewardRegistry = async () => {
  const [signer] = await ethers.getSigners();

  const { accessRegistry } = await deployAccessRegistry(signer);

  const { configRegistry } = await deployConfigRegistry(signer, await accessRegistry.getAddress(), signer.address, 20000);

  const RewardRegistry = await ethers.getContractFactory('RewardRegistry', signer);

  const configRegistryAddress = await configRegistry.getAddress();

  const rewardRegistry = await upgrades.deployProxy(RewardRegistry, [configRegistryAddress]);

  return { rewardRegistry };
}

const salt = stringToBytes32("SALT");

const register = async (owners: SignerWithAddress[]) => {
  const { rewardRegistry } = await deployRewardRegistry();

  const createVault = async (signer: SignerWithAddress) => {
    const response: ContractTransactionResponse = await rewardRegistry.connect(signer).createVault(salt, []);

    const receipt = await response.wait();

    const event = receipt?.logs
      .map((log) => {
        try {
          return rewardRegistry.interface.parseLog(log);
        }
        catch (err) {
          return null;
        }
      })
      .find(event => event?.name === 'RewardVaultCreated');

    const vault = event?.args[0] as string;

    assert.ok(vault);

    return vault;
  }

  return { rewardRegistry, vaults: await Promise.all(owners.map((owner) => createVault(owner))) };
}


async function testWith(currencyResolver: () => Promise<string>) {
  it('should send funds to vault', async () => {
    const [signer1, signer2] = await ethers.getSigners();

    const { vaults: [vault] } = await register([signer2]);
    const currency = await currencyResolver();

    if (currency === ethers.ZeroAddress) {
      //-- send native
      const amount = 1000000000n;

      const { balanceBefore, balanceAfter } = await getBalances(vault, currency, async () => {
        const tx = await signer1.sendTransaction({
          to: vault,
          value: amount,
        });

        const receipt = await tx.wait();

        assert.ok(receipt);

        return receipt;
      });

      assert.strictEqual(balanceAfter, balanceBefore + amount);
    }
    else {
      //-- send ERC20
      const amount = 1000n;
      const contract = await ethers.getContractAt('IERC20', currency);

      const { balanceBefore, balanceAfter } = await getBalances(vault, currency, async () => {
        const tx = await contract.connect(signer2).transfer(vault, amount);

        const receipt = await tx.wait();

        assert.ok(receipt);

        return receipt;
      });

      assert.strictEqual(balanceAfter, balanceBefore + amount);
    }
  });

  it('should allow to withdraw funds', async () => {
    const [signer1, signer2] = await ethers.getSigners();

    const { vaults: [vault] } = await register([signer2]);
    const currency = await currencyResolver();

    const amount = 1000000000n;

    if (currency === ethers.ZeroAddress) {
      const tx = await signer2.sendTransaction({
        to: vault,
        value: amount,
      });

      await tx.wait();
    }
    else {
      const contract = await ethers.getContractAt('IERC20', currency);

      const tx = await contract.connect(signer2).transfer(vault, amount);

      await tx.wait();
    }

    const withdrawAmount = 5000000n;

    const { balanceBefore, balanceAfter } = await getBalances(signer1.address, currency, async () => {
      const rewardVault = await ethers.getContractAt('RewardVault', vault);

      const tx = await rewardVault.connect(signer2).withdraw(signer1.address, currency, withdrawAmount);

      const receipt = await tx.wait();

      assert.ok(receipt);

      return receipt;
    });

    assert.strictEqual(balanceAfter, balanceBefore + withdrawAmount);

  });
}

const setRewards = async () => {
  const [signer1, signer2] = await ethers.getSigners();
  const { vaults: [vault1, vault2], rewardRegistry } = await register([signer1, signer2]);

  const currency = await mintERC20(signer1, signer1.address, "TEST", "TST", ethers.parseEther("1"));

  const reward1 = stringToBytes32("TICKET:type1");
  const reward2 = stringToBytes32("TICKET:type2");

  const rewardVault1 = await ethers.getContractAt("RewardVault", vault1);
  const rewardVault2 = await ethers.getContractAt("RewardVault", vault2);

  const amount1 = 1000000000000n
  const amount2 = 3000000000000n

  const currencyContract = await ethers.getContractAt('IERC20', currency);

  await Promise.all([
    //-- set rewards
    rewardVault1.connect(signer1).setRewards(
      [reward1, reward1],
      [[ethers.ZeroAddress, amount1], [currency, amount1]],
    ),
    rewardVault2.connect(signer2).setRewards(
      [reward1, reward2],
      [[ethers.ZeroAddress, amount2], [currency, 1000000000n]],
    ),
    //-- funds the vaults
    signer1.sendTransaction({ to: vault1, value: ethers.parseEther("1") }),
    signer1.sendTransaction({ to: vault2, value: ethers.parseEther("1") }),
    currencyContract.connect(signer1).transfer(vault1, ethers.parseEther("1")),
  ].map((thenable) => thenable.then((tx) => tx.wait())));

  return {
    reward1, reward2, amount1, amount2,
    signer1, signer2, currencyContract, rewardRegistry,
  };
}

const claimRefunds = async (args: Awaited<ReturnType<typeof setRewards>>) => {
  const {
    reward1,
    amount1, amount2,
    signer1, signer2,
    currencyContract, rewardRegistry,
  } = args;

  const claimId = "ticket_purchase:1";
  const rewardIds = [reward1];
  const counts = [1n];

  const signature = await createSignature(
    signer1,
    [...["REWARD", claimId].map(stringToBytes32), ...rewardIds, ...counts.map(numberToBytes32)],
  );

  const erc20BalanceBefore = await currencyContract.balanceOf(signer2.address);

  const { balanceBefore, balanceAfter, fee } = await getBalances(signer2.address, ethers.ZeroAddress, async () => {
    const tx = await rewardRegistry
      .connect(signer2)
      .claimRewards(stringToBytes32(claimId), rewardIds, counts, signature);

    const receipt = await tx.wait();

    assert.ok(receipt);

    return receipt;
  });

  const erc20BalanceAfter = await currencyContract.balanceOf(signer2.address);

  assert.ok(erc20BalanceBefore === 0n && erc20BalanceAfter === amount1);
  assert.ok(balanceAfter === balanceBefore + amount1 + amount2 - fee);
}

describe('LemonadeRewardV1', function () {
  it('should allow create vault', async () => {
    const [signer] = await ethers.getSigners();

    const { vaults: [vault] } = await register([signer]);

    const rewardVault = await ethers.getContractAt("RewardVault", vault);

    //-- listRewards should work and return empty array
    const rewards = await rewardVault.listRewards(salt);

    assert.strictEqual(rewards.length, 0);
  });

  it('should allow setRewards', async () => {
    const { rewardRegistry, reward1, reward2 } = await setRewards();

    const rewards = await rewardRegistry.checkRewards([reward1, reward2]);

    assert.ok(rewards.length === 2);

    const [r1, r2] = rewards;

    assert.ok(
      r1.length === 2 //-- both vault1 & vault2
      && r2.length === 1 //-- only vault1
      && r1[0][1].length === 2 //-- vault1 has 2 reward settings for reward1
      && r1[1][1].length === 1 //-- vault2 has 1 reward settings for reward1
    );
  });

  it('should allow claimRewards', async () => {
    const args = await setRewards();

    await claimRefunds(args);
  });

  it('should prevent claimRewards with same claimId', async () => {
    const args = await setRewards();

    await claimRefunds(args);

    await expect(claimRefunds(args)).to.revertedWithCustomError(args.rewardRegistry, "AlreadyClaimed");
  });

  describe('Native currency', function () {
    testWith(() => Promise.resolve(ethers.ZeroAddress));
  });

  describe('ERC20 currency', function () {
    testWith(async () => {
      const [signer1, signer2] = await ethers.getSigners();

      return await mintERC20(signer1, signer2.address, "TEST", "TST", 1000000000000n);
    });
  });
});
