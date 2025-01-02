import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers } from "hardhat";

export async function mintERC20(signer: SignerWithAddress, destination: string, name: string, symbol: string, amount: bigint) {
  const MyERC20Token = await ethers.getContractFactory("ERC20Mint", signer);

  const token = await MyERC20Token.deploy(name, symbol, destination, amount);
  
  return token.getAddress();
}
