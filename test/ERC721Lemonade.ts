import { Contract } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const CHILD_CHAIN_MANAGER = '0xb5505a6d998549090530911180f38aC5130101c6';
const MINT_TOKEN_URI = 'tokenURI';

describe('ERC721Lemonade', () => {
  let erc721Lemonade: Contract;
  let signer: SignerWithAddress;

  beforeEach(async () => {
    const ERC721Lemonade = await ethers.getContractFactory('ERC721Lemonade');
    const signers = await ethers.getSigners();

    erc721Lemonade = await ERC721Lemonade.deploy(ERC721_NAME, ERC721_SYMBOL, CHILD_CHAIN_MANAGER);
    signer = signers[0];
  });

  it('should mint to caller', async () => {
    await expect(erc721Lemonade.connect(signer).mintToCaller(MINT_TOKEN_URI))
      .to.emit(erc721Lemonade, 'Transfer').withArgs(ethers.constants.AddressZero, signer.address, 0);

    expect(await erc721Lemonade.ownerOf(0), 'owner must match caller')
      .to.equal(signer.address);
  });

  it('should mint to caller with token URI', async () => {
    await erc721Lemonade.connect(signer).mintToCaller(MINT_TOKEN_URI);

    expect(await erc721Lemonade.tokenURI(0), 'tokenURI must match')
      .to.equal(MINT_TOKEN_URI);
  });
});
