import { BigNumber, BigNumberish, Contract, ContractTransaction } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

const CHILD_CHAIN_MANAGER = '0xb5505a6d998549090530911180f38aC5130101c6';
const ERC20_INITIAL_SUPPLY = ethers.utils.parseEther('100');
const ERC20_NAME = 'Lemons';
const ERC20_SYMBOL = 'LEM';
const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const FEE_ACCOUNT = '0x951292004e8a18955Cb1095CB72Ca6B01d68336E';
const FEE_VALUE = '200';
const MINT_TOKEN_URI = 'ipfs://QmcjpRmXZQsnnusxhWwWqDMgxe9dSbLRTo1WbxAzMTy2NM';
const ORDER_OPEN_TO =  (Math.floor(Date.now() / 1000) + 24 * 60).toString();
const ORDER_PRICE = ethers.utils.parseEther('0.5');
const TRUSTED_FORWARDER = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';

enum OrderKind {
  Direct = 0,
  Auction = 1,
}

describe('LemonadeMarketplace', () => {
  let erc20Mint: Contract;
  let erc721Lemonade: Contract;
  let lemonadeMarketplace: Contract;
  let signers: SignerWithAddress[];

  beforeEach(async () => {
    const ERC20Mint = await ethers.getContractFactory('ERC20Mint');
    const ERC721Lemonade = await ethers.getContractFactory('ERC721Lemonade');
    const LemonadeMarketplace = await ethers.getContractFactory('LemonadeMarketplace');

    signers = await ethers.getSigners();
    erc20Mint = await ERC20Mint.deploy(ERC20_NAME, ERC20_SYMBOL, signers[0].address, ERC20_INITIAL_SUPPLY);
    erc721Lemonade = await ERC721Lemonade.deploy(ERC721_NAME, ERC721_SYMBOL, TRUSTED_FORWARDER, CHILD_CHAIN_MANAGER);
    lemonadeMarketplace = await LemonadeMarketplace.deploy(FEE_ACCOUNT, FEE_VALUE, TRUSTED_FORWARDER);

    const transferAmount = ERC20_INITIAL_SUPPLY.div(signers.length);

    for (const signer of signers.slice(1)) {
      await erc20Mint.transfer(signer.address, transferAmount);
    }
  });

  const mintToCaller = async (signer: SignerWithAddress) => {
    const tx: ContractTransaction = await erc721Lemonade.connect(signer).mintToCaller(MINT_TOKEN_URI);
    const receipt = await tx.wait();

    return receipt.events?.map(({ args }) => args?.tokenId).find(Boolean);
  };

  const createOrder = async (
    kind: OrderKind,
    openTo: string,
    tokenId: BigNumberish,
    signer: SignerWithAddress,
  ) => {
    const args = { // ordered
      kind,
      openFrom: '0',
      openTo,
      currency: erc20Mint.address,
      price: ORDER_PRICE,
      tokenContract: erc721Lemonade.address,
      tokenId,
    };

    await erc721Lemonade.connect(signer).setApprovalForAll(lemonadeMarketplace.address, true);

    const tx: ContractTransaction = await lemonadeMarketplace.connect(signer).createOrder(...Object.values(args));
    const receipt = await tx.wait();

    const order = { // ordered
      orderId: receipt.events?.map(({ args }) => args?.orderId).find(Boolean),
      kind: args.kind,
      openFrom: args.openFrom,
      openTo: args.openTo,
      maker: signer.address,
      currency: args.currency,
      price: args.price,
      tokenContract: args.tokenContract,
      tokenId: args.tokenId,
    };

    await expect(tx).to.emit(erc721Lemonade, 'Transfer').withArgs(signer.address, lemonadeMarketplace.address, tokenId);
    await expect(tx).to.emit(lemonadeMarketplace, 'OrderCreated').withArgs(...Object.values(order));

    return order;
  };

  it('should create direct order and then cancel', async () => {
    const { orderId, tokenId } = await createOrder(OrderKind.Direct, '0', await mintToCaller(signers[0]), signers[0]);

    const before = await lemonadeMarketplace.order(orderId);
    expect(before[1], 'order must be open before cancel')
      .to.equal(true);

    const tx = await lemonadeMarketplace.connect(signers[0]).cancelOrder(orderId);
    await expect(tx).to.emit(erc721Lemonade, 'Transfer').withArgs(lemonadeMarketplace.address, signers[0].address, tokenId)
    await expect(tx).to.emit(lemonadeMarketplace, 'OrderCancelled').withArgs(orderId);

    const after = await lemonadeMarketplace.order(orderId);
    expect(after[1], 'order must not be open after cancel')
      .to.equal(false);
  });

  it('should create direct order and then fill', async () => {
    const { orderId, price, tokenId } = await createOrder(OrderKind.Direct, '0', await mintToCaller(signers[0]), signers[0]);
    const feeAmount = price.mul(FEE_VALUE).div(10000);

    await erc20Mint.connect(signers[1]).approve(lemonadeMarketplace.address, price);

    const tx = await lemonadeMarketplace.connect(signers[1]).fillOrder(orderId, price);
    await expect(tx).to.emit(erc20Mint, 'Transfer').withArgs(signers[1].address, FEE_ACCOUNT, feeAmount);
    await expect(tx).to.emit(erc20Mint, 'Transfer').withArgs(signers[1].address, signers[0].address, price.sub(feeAmount));
    await expect(tx).to.emit(erc721Lemonade, 'Transfer').withArgs(lemonadeMarketplace.address, signers[1].address, tokenId);
    await expect(tx).to.emit(lemonadeMarketplace, 'OrderFilled').withArgs(orderId, signers[1].address, price);
  });

  it('should create direct order and then fail to fill due to unmet price', async () => {
    const { orderId } = await createOrder(OrderKind.Direct, '0', await mintToCaller(signers[0]), signers[0]);

    await expect(lemonadeMarketplace.connect(signers[1]).fillOrder(orderId, '0'))
      .to.revertedWith('LemonadeMarketplace: must match price to fill direct order');
  });

  it('should fail to create auction order due to open for more than 30 days', async () => {
    const openTo = (Math.floor(Date.now() / 1000) + 31 * 24 * 60 * 60).toString();

    await expect(createOrder(OrderKind.Auction, openTo, await mintToCaller(signers[0]), signers[0]))
      .to.revertedWith('LemonadeMarketplace: order of kind auction must not be open for more than 30 days');
  });

  it('should create auction order and then fail to fill due to missing bid', async () => {
    const { orderId } = await createOrder(OrderKind.Auction, ORDER_OPEN_TO, await mintToCaller(signers[0]), signers[0]);

    await expect(lemonadeMarketplace.connect(signers[0]).fillOrder(orderId, '0'))
      .to.revertedWith('LemonadeMarketplace: order must have bid to fill auction order');
  });

  const createBids = async (orderId: string, times: number) => {
    const bidders = signers.slice(1, 1 + times);
    const increment = ethers.utils.parseEther('0.0001');
    let lastBidAmount: BigNumber | undefined;
    let lastBidder: SignerWithAddress | undefined;

    for (const [i, bidder] of bidders.entries()) {
      const oddness = Number(i % 2 !== 0);
      const bidAmount = increment.mul(oddness).add(lastBidAmount || ORDER_PRICE);

      await erc20Mint.connect(bidder).approve(lemonadeMarketplace.address, bidAmount);

      const txPromise = lemonadeMarketplace.connect(bidder).bidOrder(orderId, bidAmount);

      if (i === 0 || oddness) {
        if (lastBidder) {
          await expect(txPromise).to.emit(erc20Mint, 'Transfer').withArgs(lemonadeMarketplace.address, lastBidder.address, lastBidAmount);
        }

        await expect(txPromise).to.emit(erc20Mint, 'Transfer').withArgs(bidder.address, lemonadeMarketplace.address, bidAmount);
        await expect(txPromise).to.emit(lemonadeMarketplace, 'OrderBid').withArgs(orderId, bidder.address, bidAmount);

        lastBidder = bidder;
        lastBidAmount = bidAmount;
      } else {
        await expect(txPromise).to.revertedWith('LemonadeMarketplace: must surpass bid to bid');
      }
    }

    expect(lastBidder).to.not.undefined;
    expect(lastBidAmount).to.not.undefined;

    return { bidder: lastBidder!, bidAmount: lastBidAmount! };
  };

  it('should create auction order and then bid 5 times', async () => {
    const { orderId } = await createOrder(OrderKind.Auction, ORDER_OPEN_TO, await mintToCaller(signers[0]), signers[0]);

    await createBids(orderId, 5);
  });

  it('should create auction order and then bid 1 time and then fail to cancel due to a bid', async () => {
    const { orderId } = await createOrder(OrderKind.Auction, ORDER_OPEN_TO, await mintToCaller(signers[0]), signers[0]);

    await createBids(orderId, 1);

    await expect(lemonadeMarketplace.connect(signers[0]).cancelOrder(orderId))
      .revertedWith('LemonadeMarketplace: order must have no bid to cancel');
  });

  it('should create auction order and then bid 3 times and then fill', async () => {
    const { orderId, tokenId } = await createOrder(OrderKind.Auction, ORDER_OPEN_TO, await mintToCaller(signers[0]), signers[0]);

    const { bidder, bidAmount } = await createBids(orderId, 5);
    const feeAmount = bidAmount.mul(FEE_VALUE).div(10000);

    const tx = await lemonadeMarketplace.connect(signers[0]).fillOrder(orderId, '0');
    await expect(tx).emit(erc20Mint, 'Transfer').withArgs(lemonadeMarketplace.address, signers[0].address, bidAmount.sub(feeAmount));
    await expect(tx).emit(erc721Lemonade, 'Transfer').withArgs(lemonadeMarketplace.address, bidder.address, tokenId);
    await expect(tx).emit(lemonadeMarketplace, 'OrderFilled').withArgs(orderId, bidder.address, bidAmount);
  });
});
