import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import assert from 'assert';
import { ContractTransactionResponse } from 'ethers';
import { ethers, upgrades } from 'hardhat';

import { toId } from "./utils";

import { deployAccessRegistry, deployConfigRegistry, getBalances, mintERC20 } from "./helper";

const deployRewardRegistry = async () => {
  const [signer] = await ethers.getSigners();

  const { accessRegistry } = await deployAccessRegistry(signer);

  const { configRegistry } = await deployConfigRegistry(signer, await accessRegistry.getAddress(), signer.address, 20000);

  const RewardRegistry = await ethers.getContractFactory('RewardRegistry', signer);

  const configRegistryAddress = await configRegistry.getAddress();

  const rewardRegistry = await upgrades.deployProxy(RewardRegistry, [configRegistryAddress]);

  return { rewardRegistry };
}

const salt = toId("SALT");

const register = async (owners: SignerWithAddress[]) => {
  const { rewardRegistry } = await deployRewardRegistry();

  const createVault = async (signer: SignerWithAddress) => {
    const response: ContractTransactionResponse = await rewardRegistry.connect(signer).createVault(salt);

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
    const [signer1, signer2] = await ethers.getSigners();
    const { vaults: [vault1, vault2], rewardRegistry } = await register([signer1, signer2]);

    const currency = await mintERC20(signer1, signer2.address, "TEST", "TST", 1000000000000n);

    const reward1 = toId("TICKET:type1");
    const reward2 = toId("TICKET:type2");

    const rewardVault1 = await ethers.getContractAt("RewardVault", vault1);
    const rewardVault2 = await ethers.getContractAt("RewardVault", vault2);

    await rewardVault1.connect(signer1).setRewards(
      [reward1],
      [[ethers.ZeroAddress, 1000000000]],
    );

    await rewardVault2.connect(signer2).setRewards(
      [reward1, reward2],
      [[ethers.ZeroAddress, 1000000000], [currency, 1000000000]],
    );

    const rewards = await rewardRegistry.checkRewards([reward1, reward2]);

    console.log("rewaeds", rewards);
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
