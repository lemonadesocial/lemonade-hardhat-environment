import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import assert from 'assert';
import { ContractTransactionResponse } from 'ethers';
import { ethers, upgrades } from 'hardhat';
import { expect } from "chai";

import { deployAccessRegistry, getBalances, mintERC20, PAYMENT_ADMIN_ROLE } from "./helper";

const deployPointSystem = async (signer: SignerWithAddress) => {
  const { accessRegistry } = await deployAccessRegistry(signer);

  const LemonadePointSystem = await ethers.getContractFactory('LemonadePointSystem', signer);

  const accessRegistryAddress = await accessRegistry.getAddress();

  const pointSystem = await upgrades.deployProxy(LemonadePointSystem, []);

  const tx = await pointSystem.setAccessRegistry(accessRegistryAddress);

  await tx.wait();

  return { accessRegistry, pointSystem };
}

describe('LemonadePointSystem', function () {
  it('should deploy point system', async () => {
    const [signer] = await ethers.getSigners();

    await assert.doesNotReject(deployPointSystem(signer));
  });

  it('should allow operator to add points', async () => {
    const [signer, signer2, signer3] = await ethers.getSigners();

    const { accessRegistry, pointSystem } = await deployPointSystem(signer);

    //-- set signer2 as operator
    const tx1 = await accessRegistry.grantRole(PAYMENT_ADMIN_ROLE, signer2.address);
    await tx1.wait();

    //-- using signer2 to set points
    const points = 100n;
    const tx2 = await pointSystem.connect(signer2).addPoints([signer3.address], [points]);
    await tx2.wait();

    const response = await pointSystem.userPoints(signer3.address);
    assert.strictEqual(points, response);
  });

  it('should disallow non-operator to add points', async () => {
    const [signer, signer2, signer3] = await ethers.getSigners();

    const { accessRegistry, pointSystem } = await deployPointSystem(signer);

    //-- using signer2 to set points
    await expect(pointSystem.connect(signer2).addPoints([signer3.address], [100n]))
      .revertedWithCustomError(pointSystem, "Forbidden");
  });

  it('should receive funds', async () => {
    const [signer1, signer2] = await ethers.getSigners();

    const { pointSystem } = await deployPointSystem(signer1);

    const pointSystemAddress = await pointSystem.getAddress();

    //-- mint some erc20 to signer2
    const { token } = await mintERC20(signer1, signer2.address, "TEST", "TST", ethers.parseEther("100"));

    //-- send eth and erc20 to contract
    const tx1 = await signer2.sendTransaction({
      to: pointSystemAddress,
      value: ethers.parseEther("1"),
    });
    await tx1.wait();

    const tx2 = await token.connect(signer2).transfer(pointSystemAddress, ethers.parseEther("50"));
    await tx2.wait();

    const contractEthBalance = await ethers.provider.getBalance(pointSystemAddress);
    const contractErc20Balance = await token.balanceOf(pointSystemAddress);

    expect(contractEthBalance).to.equal(ethers.parseEther("1"));
    expect(contractErc20Balance).to.equal(ethers.parseEther("50"));
  });

  it('should withdraw funds', async () => {
    const [signer1, signer2, signer3] = await ethers.getSigners();

    const { pointSystem } = await deployPointSystem(signer1);

    const pointSystemAddress = await pointSystem.getAddress();

    //-- mint some erc20 to signer2
    const { token, address } = await mintERC20(signer1, signer2.address, "TEST", "TST", ethers.parseEther("100"));

    //-- send eth and erc20 to contract
    const tx1 = await signer2.sendTransaction({
      to: pointSystemAddress,
      value: ethers.parseEther("1"),
    });
    await tx1.wait();

    const tx2 = await token.connect(signer2).transfer(pointSystemAddress, ethers.parseEther("50"));
    await tx2.wait();

    //-- use signer1 to withdraw erc20
    const { balanceAfter: erc20After, balanceBefore: erc20Before } = await getBalances(signer3.address, address, async () => {
      const response: ContractTransactionResponse = await pointSystem
        .connect(signer1)
        .withdraw(signer3.address, address, ethers.parseEther("20"));

      const receipt = await response.wait();

      assert.ok(receipt);

      return receipt;
    });

    //-- use signer1 to withdraw native token
    const { balanceAfter: nativeAfter, balanceBefore: nativeBefore } = await getBalances(signer3.address, ethers.ZeroAddress, async () => {
      const response: ContractTransactionResponse = await pointSystem
        .connect(signer1)
        .withdraw(signer3.address, ethers.ZeroAddress, ethers.parseEther("1"));

      const receipt = await response.wait();

      assert.ok(receipt);

      return receipt;
    });

    assert.strictEqual(erc20After, erc20Before + ethers.parseEther("20"));
    assert.strictEqual(nativeAfter, nativeBefore + ethers.parseEther("1"));
  });

  it('should allow operator to set redeemables', async () => {
    const [signer, signer2] = await ethers.getSigners();

    const { accessRegistry, pointSystem } = await deployPointSystem(signer);

    //-- set signer2 as operator
    const tx1 = await accessRegistry.grantRole(PAYMENT_ADMIN_ROLE, signer2.address);
    await tx1.wait();

    const { address } = await mintERC20(signer, signer2.address, "TEST", "TST", ethers.parseEther("100"));

    //-- 10 points for 1 token
    const tx2 = await pointSystem.connect(signer2).setTokenRedeemable(address, ethers.parseEther("1"), 10n);
    await tx2.wait();

    const [[token, points, amount]] = await pointSystem.listTokenRedeemableSettings();

    assert.ok(
      token === address && points === 10n && amount === ethers.parseEther("1")
    );
  });

  it('should disallow non-operator to set redeemables', async () => {
    const [signer, signer2, signer3] = await ethers.getSigners();

    const { accessRegistry, pointSystem } = await deployPointSystem(signer);

    //-- set signer2 as operator
    const tx1 = await accessRegistry.grantRole(PAYMENT_ADMIN_ROLE, signer2.address);
    await tx1.wait();

    const { address } = await mintERC20(signer, signer2.address, "TEST", "TST", ethers.parseEther("100"));

    await expect(pointSystem.connect(signer3).setTokenRedeemable(address, ethers.parseEther("1"), 10n))
      .revertedWithCustomError(pointSystem, "Forbidden");
  });

  it('should rewrite existing redeemable', async () => {
    const [signer, signer2] = await ethers.getSigners();

    const { accessRegistry, pointSystem } = await deployPointSystem(signer);

    //-- set signer2 as operator
    const tx1 = await accessRegistry.grantRole(PAYMENT_ADMIN_ROLE, signer2.address);
    await tx1.wait();

    const { address } = await mintERC20(signer, signer2.address, "TEST", "TST", ethers.parseEther("100"));

    //-- first, set 10 points for 1 token
    const tx2 = await pointSystem.connect(signer2).setTokenRedeemable(address, ethers.parseEther("1"), 10n);
    await tx2.wait();

    //-- then set 10 points for 2 token
    const tx3 = await pointSystem.connect(signer2).setTokenRedeemable(address, ethers.parseEther("2"), 10n);
    await tx3.wait();

    const [[token, points, amount]] = await pointSystem.listTokenRedeemableSettings();

    assert.ok(
      token === address && points === 10n && amount === ethers.parseEther("2")
    );
  });

  it('should throw insufficient balance redeem', async () => {
    const [signer, signer2, signer3] = await ethers.getSigners();

    const { accessRegistry, pointSystem } = await deployPointSystem(signer);

    //-- set signer2 as operator
    const tx1 = await accessRegistry.grantRole(PAYMENT_ADMIN_ROLE, signer2.address);
    await tx1.wait();

    //-- using signer2 to set points
    const points = 100n;
    const tx2 = await pointSystem.connect(signer2).addPoints([signer3.address], [points]);
    await tx2.wait();

    //-- set 50 points for 1 token
    const tx3 = await pointSystem.connect(signer2).setTokenRedeemable(ethers.ZeroAddress, ethers.parseEther("1"), 50n);
    await tx3.wait();

    //-- try redeem 101 points
    await expect(pointSystem.connect(signer3).redeem(ethers.ZeroAddress, 101n))
      .revertedWithCustomError(pointSystem, "InsufficientPoint");
  });

  it('should redeem correctly', async () => {
    const [signer, signer2, signer3] = await ethers.getSigners();

    const { accessRegistry, pointSystem } = await deployPointSystem(signer);

    //-- set signer2 as operator
    const tx1 = await accessRegistry.grantRole(PAYMENT_ADMIN_ROLE, signer2.address);
    await tx1.wait();

    //-- using signer2 to set points
    const points = 100n;
    const tx2 = await pointSystem.connect(signer2).addPoints([signer3.address], [points]);
    await tx2.wait();

    //-- transfer some funds to contract
    const pointSystemAddress = await pointSystem.getAddress();
    const tx3 = await signer2.sendTransaction({
      to: pointSystemAddress,
      value: ethers.parseEther("10"),
    });
    await tx3.wait();

    //-- set 50 points for 1 token
    const tx4 = await pointSystem.connect(signer2).setTokenRedeemable(ethers.ZeroAddress, ethers.parseEther("1"), 50n);
    await tx4.wait();

    //-- try redeem 100 points
    const { balanceAfter, balanceBefore, fee } = await getBalances(signer3.address, ethers.ZeroAddress, async () => {
      const response: ContractTransactionResponse = await pointSystem
        .connect(signer3)
        .redeem(ethers.ZeroAddress, 100n);

      const receipt = await response.wait();

      assert.ok(receipt);

      return receipt;
    });

    //-- should receive 2 ETH
    assert.strictEqual(balanceAfter, balanceBefore + ethers.parseEther("2") - fee);
  });
});
