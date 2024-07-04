import { Contract, ContractTransactionResponse, TransactionReceipt } from 'ethers';
import { ethers } from 'hardhat';
import { expect } from 'chai';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';
import BigNumber from 'bignumber.js';

const ERC20_INITIAL_SUPPLY = ethers.parseEther('100');
const ERC20_NAME = 'Lemons';
const ERC20_SYMBOL = 'LEM';
const ERC721_NAME = 'Non-Fungible Lemon';
const ERC721_SYMBOL = 'NFL';
const FEE_ACCOUNT = '0x951292004e8a18955Cb1095CB72Ca6B01d68336E';
const FEE_VALUE = '200';
const MINT_TOKEN_URI = 'ipfs://QmcjpRmXZQsnnusxhWwWqDMgxe9dSbLRTo1WbxAzMTy2NM';
const ORDER_OPEN_TO = (Math.floor(Date.now() / 1000) + 24 * 60).toString();
const ORDER_PRICE = ethers.parseEther('0.5').toString();

enum OrderKind {
  Direct = 0,
  Auction = 1,
}

describe('LemonadeMarketplaceV1', () => {
  let erc20Mint: Contract;
  let erc721Lemonade: Contract;
  let lemonadeMarketplace: Contract;
  let signers: SignerWithAddress[];
  let marketPlaceContract: string;

  beforeEach(async () => {
    const ERC20Mint = await ethers.getContractFactory('ERC20Mint');
    const ERC721Lemonade = await ethers.getContractFactory('ERC721LemonadeV1');
    const LemonadeMarketplace = await ethers.getContractFactory('LemonadeMarketplaceV1');

    signers = await ethers.getSigners();
    erc20Mint = await ERC20Mint.deploy(ERC20_NAME, ERC20_SYMBOL, signers[0].address, ERC20_INITIAL_SUPPLY);
    erc721Lemonade = await ERC721Lemonade.deploy(ERC721_NAME, ERC721_SYMBOL);
    lemonadeMarketplace = await LemonadeMarketplace.deploy(FEE_ACCOUNT, FEE_VALUE);

    marketPlaceContract = await lemonadeMarketplace.getAddress();

    const transferAmount = new BigNumber(ERC20_INITIAL_SUPPLY.toString()).dividedBy(signers.length).toString();

    for (const signer of signers.slice(1)) {
      await erc20Mint.transfer(signer.address, transferAmount);
    }
  });

  const getReceiptLogs = (contract: Contract, receipt: TransactionReceipt) => {
    return receipt.logs.flatMap((log) => {
      const parsedLog = contract.interface.parseLog(log);
      return parsedLog ? [parsedLog] : [];
    });
  }

  const mintToCaller = async (signer: SignerWithAddress) => {
    const tx: ContractTransactionResponse = await erc721Lemonade.connect(signer).mintToCaller(MINT_TOKEN_URI);

    const receipt = await tx.wait();

    const logs = receipt && getReceiptLogs(erc721Lemonade, receipt);

    return logs?.find((log) => log.name === 'Transfer')?.args[2];
  };

  const createOrder = async (
    kind: OrderKind,
    openTo: string,
    tokenId: bigint,
    signer: SignerWithAddress,
  ) => {
    const tokenContract = await erc721Lemonade.getAddress();
    const currency = await erc20Mint.getAddress();

    const args = { // ordered
      kind,
      openFrom: '0',
      openTo,
      currency,
      price: ORDER_PRICE,
      tokenContract,
      tokenId,
    };

    await erc721Lemonade.connect(signer).setApprovalForAll(marketPlaceContract, true);

    const tx: ContractTransactionResponse = await lemonadeMarketplace.connect(signer).createOrder(...Object.values(args));
    const receipt = await tx.wait();

    const logs = receipt && getReceiptLogs(lemonadeMarketplace, receipt);

    const order = { // ordered
      orderId: logs?.find((log)=> log.name === 'OrderCreated')?.args[0],
      kind: args.kind,
      openFrom: args.openFrom,
      openTo: args.openTo,
      maker: signer.address,
      currency: args.currency,
      price: args.price,
      tokenContract: args.tokenContract,
      tokenId: args.tokenId,
    };

    await expect(tx).to.emit(erc721Lemonade, 'Transfer').withArgs(signer.address, marketPlaceContract, tokenId);
    await expect(tx).to.emit(lemonadeMarketplace, 'OrderCreated').withArgs(...Object.values(order));

    return order;
  };

  it('should create direct order and then cancel', async () => {
    const { orderId, tokenId } = await createOrder(OrderKind.Direct, '0', await mintToCaller(signers[0]), signers[0]);

    const before = await lemonadeMarketplace.order(orderId);
    expect(before[1], 'order must be open before cancel').to.equal(true);

    const tx = await lemonadeMarketplace.connect(signers[0]).cancelOrder(orderId);
    await expect(tx).to.emit(erc721Lemonade, 'Transfer').withArgs(marketPlaceContract, signers[0].address, tokenId);
    await expect(tx).to.emit(lemonadeMarketplace, 'OrderCancelled').withArgs(orderId);

    const after = await lemonadeMarketplace.order(orderId);
    expect(after[1], 'order must not be open after cancel').to.equal(false);
  });

  it('should create direct order and then fill', async () => {
    const { orderId, price, tokenId } = await createOrder(OrderKind.Direct, '0', await mintToCaller(signers[0]), signers[0]);
    const feeAmount = new BigNumber(price.toString()).multipliedBy(FEE_VALUE).div(10000);

    await erc20Mint.connect(signers[1]).approve(marketPlaceContract, price);

    const tx = await lemonadeMarketplace.connect(signers[1]).fillOrder(orderId, price);
    await expect(tx).to.emit(erc20Mint, 'Transfer').withArgs(signers[1].address, FEE_ACCOUNT, feeAmount);
    await expect(tx).to.emit(erc20Mint, 'Transfer').withArgs(signers[1].address, signers[0].address, new BigNumber(price.toString()).minus(feeAmount));
    await expect(tx).to.emit(erc721Lemonade, 'Transfer').withArgs(marketPlaceContract, signers[1].address, tokenId);
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
    const increment = ethers.parseEther('0.0001');
    let lastBidAmount: BigNumber | undefined;
    let lastBidder: SignerWithAddress | undefined;

    for (const [i, bidder] of bidders.entries()) {
      const oddness = Number(i % 2 !== 0);
      const bidAmount = new BigNumber(increment.toString()).multipliedBy(oddness).plus(lastBidAmount || ORDER_PRICE);

      await erc20Mint.connect(bidder).approve(marketPlaceContract, bidAmount.toString());

      const txPromise = lemonadeMarketplace.connect(bidder).bidOrder(orderId, bidAmount.toString());

      if (i === 0 || oddness) {
        if (lastBidder) {
          await expect(txPromise).to.emit(erc20Mint, 'Transfer').withArgs(marketPlaceContract, lastBidder.address, lastBidAmount);
        }

        await expect(txPromise).to.emit(erc20Mint, 'Transfer').withArgs(bidder.address, marketPlaceContract, bidAmount);
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
    const feeAmount = new BigNumber(bidAmount).multipliedBy(FEE_VALUE).div(10000);

    const tx = await lemonadeMarketplace.connect(signers[0]).fillOrder(orderId, '0');
    await expect(tx).emit(erc20Mint, 'Transfer').withArgs(marketPlaceContract, signers[0].address, new BigNumber(bidAmount).minus(feeAmount));
    await expect(tx).emit(erc721Lemonade, 'Transfer').withArgs(marketPlaceContract, bidder.address, tokenId);
    await expect(tx).emit(lemonadeMarketplace, 'OrderFilled').withArgs(orderId, bidder.address, bidAmount);
  });
});
