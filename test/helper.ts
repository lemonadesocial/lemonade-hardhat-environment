import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { TransactionReceipt } from "ethers";
import { ethers, upgrades } from "hardhat";

import { toId } from "./utils";

export async function mintERC20(signer: SignerWithAddress, destination: string, name: string, symbol: string, amount: bigint) {
  const MyERC20Token = await ethers.getContractFactory("ERC20Mint", signer);

  const token = await MyERC20Token.deploy(name, symbol, destination, amount);

  return token.getAddress();
}

export async function deployAccessRegistry(signer: SignerWithAddress) {
  const AccessRegistry = await ethers.getContractFactory('AccessRegistry', signer);
  const accessRegistry = await AccessRegistry.deploy();

  const PAYMENT_ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes('PAYMENT_ADMIN_ROLE'));

  await accessRegistry.grantRole(PAYMENT_ADMIN_ROLE, signer.address);
  return { accessRegistry };
}

export async function deployConfigRegistry(signer: SignerWithAddress, ...args: unknown[]) {
  const PaymentConfigRegistry = await ethers.getContractFactory('PaymentConfigRegistry', signer);

  const configRegistry = await upgrades.deployProxy(PaymentConfigRegistry, args);

  return { configRegistry };
}

export async function getBalances(wallet: string, currency: string, op: () => Promise<TransactionReceipt>) {
  const isNative = currency === ethers.ZeroAddress;

  const getBalance = async () => {
    return isNative
      ? await ethers.provider.getBalance(wallet)
      : await ethers.getContractAt("ERC20", currency).then((erc20) => erc20.balanceOf(wallet));
  }

  const balanceBefore: bigint = await getBalance();
  const receipt = await op();
  const balanceAfter: bigint = await getBalance();

  return { balanceBefore, balanceAfter, fee: isNative ? receipt.gasPrice * receipt.gasUsed : 0n };
}

export function createSignature(signer: SignerWithAddress, args: string[]) {
  const data = args.map(toId);

  let encoded = "0x";

  for (let i = 0; i < data.length; i++) {
    encoded = ethers.solidityPacked(["bytes", "bytes32"], [encoded, data[i]]);
  }

  return signer.signMessage(
    ethers.getBytes(encoded)
  );
}
