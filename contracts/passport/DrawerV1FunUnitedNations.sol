// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DrawerV1.sol";
import "./IPassportV1.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DrawerV1FunUnitedNations is DrawerV1 {
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
                                '<?xml version="1.0" encoding="utf-8"?><svg viewBox="0 0 720 440" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:bx="https://boxy-svg.com"><defs><clipPath id="clip0_898_14247"><rect width="720" height="440" fill="white"/></clipPath><linearGradient id="paint0_linear_898_14247" x1="360.001" y1="3.9995" x2="360.001" y2="375.999" gradientUnits="userSpaceOnUse"><stop stop-color="#272727"/><stop offset="1"/></linearGradient><linearGradient id="paint1_linear_898_14247" x1="168" y1="134" x2="168" y2="330" gradientUnits="userSpaceOnUse"><stop stop-color="#1B1B1B"/><stop offset="1" stop-color="#060606"/></linearGradient><linearGradient id="paint2_linear_898_14247" x1="168" y1="134" x2="168" y2="330" gradientUnits="userSpaceOnUse"><stop stop-color="#1B1B1B"/><stop offset="1" stop-color="#060606"/></linearGradient><linearGradient id="paint3_linear_898_14247" x1="168" y1="134" x2="168" y2="330" gradientUnits="userSpaceOnUse"><stop stop-color="#1B1B1B"/><stop offset="1" stop-color="#060606"/></linearGradient><linearGradient id="paint4_linear_898_14247" x1="168" y1="134" x2="168" y2="330" gradientUnits="userSpaceOnUse"><stop stop-color="#1B1B1B"/><stop offset="1" stop-color="#060606"/></linearGradient><symbol id="symbol-0" viewBox="0 0 7.1996 12" bx:pinned="true"><path fill-rule="evenodd" clip-rule="evenodd" d="M23.7998 390H26.1999V392.4H28.5999V394.8H26.1998L26.1999 392.4H23.7998V390ZM30.9999 394.802H28.5997V397.2H26.1998V399.6H23.7998V402H26.1999L26.1998 399.6H28.5999L28.5997 397.2L30.9999 397.202V394.802Z" fill="black" fill-opacity="0.36" clip-path="url(#clip2_898_14247)" transform="matrix(1, 0, 0, 1, -23.80030059814453, -390)"/></symbol><clipPath id="clip2_898_14247"><rect width="7.2" height="12" fill="white" transform="translate(23.8003 390)"/></clipPath><style bx:fonts="Coda">@import url(https://fonts.googleapis.com/css2?family=Coda%3Aital%2Cwght%400%2C400%3B0%2C800&amp;display=swap);</style><style bx:fonts="Roboto Mono">@import url(https://fonts.googleapis.com/css2?family=Roboto+Mono%3Aital%2Cwght%400%2C100%3B0%2C200%3B0%2C300%3B0%2C400%3B0%2C500%3B0%2C600%3B0%2C700%3B1%2C100%3B1%2C200%3B1%2C300%3B1%2C400%3B1%2C500%3B1%2C600%3B1%2C700&amp;display=swap);</style></defs><g clip-path="url(#clip0_898_14247)" transform="matrix(1, 0, 0, 1, 3.552713678800501e-15, 3.552713678800501e-15)"><path d="M690 0H30C13.4315 0 0 13.4315 0 30V410C0 426.569 13.4315 440 30 440H690C706.569 440 720 426.569 720 410V30C720 13.4315 706.569 0 690 0Z" fill="#BCFB24"><title>BG</title></path><path d="M4 30C4 15.64 15.642 4 30 4H690C704.36 4 716 15.64 716 30V364C716 370.628 710.628 376 704 376H16C9.374 376 4 370.628 4 364V30Z" fill="url(#paint0_linear_898_14247)"><title>Top</title></path><text fill="#BCFB24" style="white-space: pre" font-family="Coda" font-size="30" font-weight="800" letter-spacing="0em"><title>Nation</title><tspan x="194.207" y="83.3145">FUN UNITED NATIONS</tspan></text><rect x="70" y="134" width="180" height="180" fill="white" fill-opacity="0.06"><title>Photo</title></rect><g><title>Overlay</title><path d="M82 134H70V146C70 139.373 75.3726 134 82 134Z" fill="url(#paint1_linear_898_14247)"/><path d="M238 134C244.627 134 250 139.373 250 146V134H238Z" fill="url(#paint2_linear_898_14247)"/><path d="M250 302C250 308.627 244.627 314 238 314H250V302Z" fill="url(#paint3_linear_898_14247)"/><path d="M82 314C75.3726 314 70 308.627 70 302V314H82Z" fill="url(#paint4_linear_898_14247)"/></g><path d="M64 142C64 134.268 70.268 128 78 128" stroke="white" stroke-width="2"><title>Corner</title></path><path d="M242 128C249.732 128 256 134.268 256 142" stroke="white" stroke-width="2"><title>Corner</title></path><path d="M256 306V308C256 314.628 250.628 320 244 320" stroke="white" stroke-width="2"><title>Corner</title></path><path d="M78 320C70.268 320 64 313.732 64 306" stroke="white" stroke-width="2"><title>Corner</title></path><path d="M564.004 134H316.004C309.376 134 304.004 139.373 304.004 146V170C304.004 176.627 309.376 182 316.004 182H564.004C570.631 182 576.004 176.627 576.004 170V146C576.004 139.373 570.631 134 564.004 134Z" fill="#BCFB24"><title>Username BG</title></path><text style="fill: rgb(0, 0, 0); font-family: Coda; font-size: 18px; font-weight: 800; white-space: pre;" x="316.004" y="163.923"><title>Username</title>', _username(passport, tokenId), '</text><text style="fill: rgb(188, 251, 36); font-family: \'Roboto Mono\'; font-size: 12px; font-weight: 700; white-space: pre;" x="304.004" y="224.025"><title>Number</title>Passport no.</text><text fill="white" style="white-space: pre" font-family="Coda" font-size="18" font-weight="800" letter-spacing="0em"><title>Value</title><tspan x="304.004" y="247.777">', _padStart(tokenId.toString(), 8, "0"), '</tspan></text><text style="fill: rgb(188, 251, 36); font-family: \'Roboto Mono\'; font-size: 12px; font-weight: 700; white-space: pre;" x="454.002" y="224.025"><title>Updated</title>Last updated</text><text fill="white" style="white-space: pre" font-family="Coda" font-size="18" font-weight="800" letter-spacing="0em"><title>Date</title><tspan x="454.002" y="247.777">', _updatedAt(passport, tokenId), '</tspan></text><text style="fill: rgb(188, 251, 36); font-family: \'Roboto Mono\'; font-size: 12px; font-weight: 700; white-space: pre;" x="304.004" y="284.025"><title>Mint</title>Date of mint</text><text fill="white" style="white-space: pre" font-family="Coda" font-size="18" font-weight="800" letter-spacing="0em"><title>Date</title><tspan x="304.004" y="307.777">', _createdAt(passport, tokenId), '</tspan></text><text style="fill: rgb(188, 251, 36); font-family: \'Roboto Mono\'; font-size: 12px; font-weight: 700; white-space: pre;" x="454.002" y="284.025"><title>Expiry</title>Date of expiry</text><text fill="white" style="white-space: pre" font-family="Coda" font-size="18" font-weight="800" letter-spacing="0em"><title>Date</title><tspan x="454.002" y="307.777">', _expiresAt(passport, tokenId), '</tspan></text><text transform="matrix(0 -1 1 0 634.888 260)" fill="#BCFB24" style="white-space: pre" font-family="Coda" font-size="18" font-weight="800" letter-spacing="0em"><title>Citizen</title><tspan x="0.482422" y="18.8887">CITIZEN</tspan></text><mask id="mask0_898_14247" style="mask-type:luminance" maskUnits="userSpaceOnUse" x="4" y="376" width="712" height="60"><path d="M716 376H4V436H716V376Z" fill="white"/></mask><g mask="url(#mask0_898_14247)"><title>Bottom</title><text style="fill: rgb(0, 0, 0); font-family: \'Roboto Mono\'; font-size: 16px; font-weight: 700; white-space: pre;" x="100.794" y="401.351"><title>Tagline</title>When life gives you lemons</text><text fill="black" style="white-space: pre" font-family="Roboto Mono" font-size="16" font-weight="bold" letter-spacing="0em" y="1"><title>Hash</title><tspan x="488.486" y="425.351" style="font-size: 16px; word-spacing: 0px;">#makelemonade</tspan></text><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 23.800001, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 4.6, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 81.400002, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 43, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 62.200001, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 362.600006, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 708.200012, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 381.800018, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 401, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 420.200012, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 439.399994, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 458.600006, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 477.800018, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 497, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 516.200012, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 535.400024, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 554.600037, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 573.799988, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 593, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 612.200012, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 631.400024, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 650.600037, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 669.799988, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 689, 390)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 9, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 469.799988, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 28.199999, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 373.799988, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 47.399998, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 66.599998, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 85.799995, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 105, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 124.199997, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 143.399994, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 162.599991, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 181.799988, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 201, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 220.199997, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 239.399994, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 258.600006, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 277.799988, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 297, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 316.199982, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 335.399994, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 354.599976, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 393, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 412.199982, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 431.399994, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 450.599976, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 627, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 703.799988, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 646.200012, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 665.400024, 414)" xlink:href="#symbol-0"/><use width="7.2" height="12" transform="matrix(1, 0, 0, 1, 684.599976, 414)" xlink:href="#symbol-0"/></g></g></svg>'
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
