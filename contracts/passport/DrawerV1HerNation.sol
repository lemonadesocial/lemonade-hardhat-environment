// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DrawerV1.sol";
import "./IPassportV1.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DrawerV1HerNation is DrawerV1 {
    using StringsUpgradeable for uint256;

    function tokenURI(
        IPassportV1 passport,
        uint256 tokenId
    )
        public
        view
        override
        whenMinted(passport, tokenId)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64Upgradeable.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Citizen #',
                                tokenId.toString(),
                                '","image":"',
                                _image(passport, tokenId),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _expiresAt(
        IPassportV1 passport,
        uint256 tokenId
    ) internal view returns (string memory) {
        uint256 timestamp = passport.createdAt(tokenId);

        (uint256 year, uint256 month, uint256 day) = DateTime.timestampToDate(
            timestamp
        );

        return _date(year + 10, month, day);
    }

    function _image(
        IPassportV1 passport,
        uint256 tokenId
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64Upgradeable.encode(
                        bytes(
                            abi.encodePacked(
                                '<?xml version="1.0" encoding="utf-8"?><svg viewBox="0 0 720 440" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:bx="https://boxy-svg.com"><defs><linearGradient id="paint0_linear_939_14995" x1="360" y1="0" x2="360" y2="440" gradientUnits="userSpaceOnUse"><stop stop-color="#FEE0B4"/><stop offset="1" stop-color="#FFF2E2"/></linearGradient><linearGradient id="paint1_linear_939_14995" x1="360" y1="4" x2="360" y2="436" gradientUnits="userSpaceOnUse"><stop stop-color="#FEE0B4"/><stop offset="1" stop-color="#F47D63"/></linearGradient><style bx:fonts="Poppins">@import url(https://fonts.googleapis.com/css2?family=Poppins%3Aital%2Cwght%400%2C100%3B0%2C200%3B0%2C300%3B0%2C400%3B0%2C500%3B0%2C600%3B0%2C700%3B0%2C800%3B0%2C900%3B1%2C100%3B1%2C200%3B1%2C300%3B1%2C400%3B1%2C500%3B1%2C600%3B1%2C700%3B1%2C800%3B1%2C900&amp;display=swap);</style><style bx:fonts="Inter">@import url(https://fonts.googleapis.com/css2?family=Inter%3Aital%2Cwght%400%2C100%3B0%2C200%3B0%2C300%3B0%2C400%3B0%2C500%3B0%2C600%3B0%2C700%3B0%2C800%3B0%2C900&amp;display=swap);</style></defs><rect width="720" height="440" rx="72" fill="url(#paint0_linear_939_14995)" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"/><rect x="4" y="4" width="712" height="432" rx="68" fill="url(#paint1_linear_939_14995)" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"/><text style="fill: rgb(0, 0, 0); font-family: Poppins; font-size: 36px; font-weight: 900; white-space: pre; text-anchor: middle;" x="360" y="91.6" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)">HER NATION</text><rect x="64" y="154" width="192.007" height="192" rx="96" fill="white" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"/><path d="M64 168V168C64 160.268 70.268 154 78 154V154" stroke="black" stroke-width="2" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"/><path d="M242 154V154C249.732 154 256 160.268 256 168V168" stroke="black" stroke-width="2" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"/><path d="M256 332L256 334C256 340.627 250.627 346 244 346V346" stroke="black" stroke-width="2" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"/><path d="M78 346V346C70.268 346 64 339.732 64 332V332" stroke="black" stroke-width="2" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"/><rect x="316.005" y="154" width="250" height="60" rx="30" fill="black" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"/><text fill="white" style="white-space: pre" font-family="Poppins" font-size="18" font-weight="900" letter-spacing="0em" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"><tspan x="340.005" y="190.3">',
                                _username(passport, tokenId),
                                '</tspan></text><text style="fill: rgb(0, 0, 0); font-family: Inter; font-size: 12px; white-space: pre;" x="316.005" y="251.864" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)">Passport no.</text><text fill="black" style="white-space: pre" font-family="Poppins" font-size="18" font-weight="900" letter-spacing="0em" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"><tspan x="316.005" y="276.8">',
                                _padStart(tokenId.toString(), 8, "0"),
                                '</tspan></text><text fill="black" style="white-space: pre" font-family="Inter" font-size="12" letter-spacing="0em" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"><tspan x="454.002" y="251.864">Last updated</tspan></text><text fill="black" style="white-space: pre" font-family="Poppins" font-size="18" font-weight="900" letter-spacing="0em" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"><tspan x="454.002" y="276.8">',
                                _updatedAt(passport, tokenId),
                                '</tspan></text><text fill="black" style="white-space: pre" font-family="Inter" font-size="12" letter-spacing="0em" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"><tspan x="316.005" y="311.864">Date of mint</tspan></text><text fill="black" style="white-space: pre" font-family="Poppins" font-size="18" font-weight="900" letter-spacing="0em" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"><tspan x="316.005" y="336.8">',
                                _createdAt(passport, tokenId),
                                '</tspan></text><text fill="black" style="white-space: pre" font-family="Inter" font-size="12" letter-spacing="0em" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"><tspan x="454.002" y="311.864">Date of expiry</tspan></text><text fill="black" style="white-space: pre" font-family="Poppins" font-size="18" font-weight="900" letter-spacing="0em" transform="matrix(1, 0, 0, 1, 7.105427357601002e-15, 7.105427357601002e-15)"><tspan x="454.002" y="336.8">',
                                _expiresAt(passport, tokenId),
                                '</tspan></text><text transform="matrix(0, -1, 1, 0, 634, 310.1933898925781)" fill="black" style="white-space: pre; text-anchor: middle;" font-family="Poppins" font-size="18" font-weight="900" letter-spacing="0em"><tspan x="60.193" y="19.8" style="font-size: 18px; word-spacing: 0px;">CITIZEN</tspan></text></svg>'
                            )
                        )
                    )
                )
            );
    }

    function _date(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    day.toString(),
                    "/",
                    month.toString(),
                    "/",
                    year.toString()
                )
            );
    }
}
