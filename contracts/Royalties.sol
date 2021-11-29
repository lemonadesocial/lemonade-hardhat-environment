// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC2981.sol";
import "./rarible/impl/RoyaltiesV2Impl.sol";
import "./rarible/LibPart.sol";
import "./rarible/RoyaltiesV2.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract Royalties is ERC165, IERC2981, RoyaltiesV2Impl {
    function royaltyInfo(uint256 tokenId, uint256 price)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory royalties_ = royalties[tokenId];
        uint256 length = royalties_.length;

        if (length == 0) {
            return (address(0), 0);
        }

        uint256 totalValue;
        for (uint256 i; i < length; i++) {
            totalValue += royalties_[i].value;
        }
        return (royalties_[0].account, (price * totalValue) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(RoyaltiesV2).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
