// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LemonadeMarketplaceV1.sol";
import "./unique/ICollection.sol";
import "./unique/LibPartAdapter.sol";

contract LemonadeMarketplaceV1Unique is LemonadeMarketplaceV1 {
    constructor(
        address feeAccount,
        uint96 feeValue
    ) LemonadeMarketplaceV1(feeAccount, feeValue) {}

    function getRaribleV2Royalties(
        address tokenContract,
        uint256 tokenId
    ) public view override returns (bool, LibPart.Part[] memory) {
        if (!isCollection(tokenContract)) {
            return
                LemonadeMarketplaceV1.getRaribleV2Royalties(
                    tokenContract,
                    tokenId
                );
        }

        try
            ICollection(tokenContract).property(tokenId, ROYALTIES_PROPERTY)
        returns (bytes memory data) {
            return (true, LibPartAdapter.decode(data));
        } catch {
            return (false, new LibPart.Part[](0));
        }
    }

    function isCollection(address addr) private pure returns (bool) {
        return
            uint160(addr) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000 ==
            0x0017c4e6453cc49aaaaeaca894e6d9683e00000000;
    }
}
