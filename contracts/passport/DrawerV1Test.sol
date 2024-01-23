// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DrawerV1.sol";
import "./IPassportV1.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DrawerV1Test is DrawerV1 {
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
                                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 657 409.5" xmlns:v="https://vecta.io/nano"><style><![CDATA[.N,.M,.c,.R,.e,.T,.AB,.AC,.AE,.AF{isolation:isolate}.AC,.AE{letter-spacing:0}.M{letter-spacing:.3em}.AF{letter-spacing:0}.AB{letter-spacing:0}.AK{stroke:#e5e5e5}.AL{stroke:gray}.AM{fill:none}.AN{fill:#cbcbcb}.AO{fill:gray}.AP{fill:#989898}.AQ{stroke-linecap:round}.AR{stroke-linejoin:round}.AS{stroke-miterlimit:10}.AT{font-family:Agdasima}.AU{font-weight:700}.AV{stroke-width:2}.AW{font-family:Bungee-Regular,Bungee}.AX{font-size:17px}.AY{fill:#e5e5e5}.AZ{fill:#dcd9c1}.Aa{stroke:#4d4d4d}.Ab{fill:#aaaaa9}.Ac{stroke-width:.5}.Ad{stroke:#b2b2b2}]]></style><defs><style>@import url(\'https://fonts.googleapis.com/css2?family=Bungee&amp;family=Agdasima\'); </style><symbol id="A" viewBox="0 0 27 27"><circle cx="13.5" cy="13.5" r="12.2" fill="#b2b2b2"/><path d="M3 14.5l21.3-4.1" stroke="#cbcbcb" class="AM AQ AS AV"/><path d="M13.5 0C6 0 0 6 0 13.5S6 27 13.5 27 27 21 27 13.5 21 0 13.5 0zm0 2.6a10.86 10.86 0 0 1 10.4 7.8L2.8 14.5h-.1v-1.1C2.6 7.5 7.5 2.6 13.5 2.6h0zm0 21.8c-5 0-9.3-3.5-10.5-8.1h.1l21.2-4.1v1.4a10.93 10.93 0 0 1-10.9 10.9h0z" fill="#4d4d4d"/></symbol><symbol id="B" viewBox="0 0 21 21"><circle cx="10.5" cy="10.5" r="9.5" transform="matrix(.159881 -.987136 .987136 .159881 -1.5 19.2)" fill="#b2b2b2"/><path d="M2.3 11.3l16.6-3.2" stroke="#cbcbcb" class="AM AQ AS AV"/><path d="M10.5 0a10.5 10.5 0 1 0 0 21 10.5 10.5 0 1 0 0-21zm0 2c3.8 0 7.1 2.6 8.1 6.1L2.2 11.3h-.1v-.8C2 5.8 5.8 2 10.5 2h0zm0 16.9c-3.9 0-7.2-2.7-8.2-6.3h.1l16.5-3.2v1.1c0 4.7-3.8 8.5-8.5 8.5h0z" fill="#4d4d4d"/></symbol><symbol id="C" viewBox="0 0 14.8 19.9"><rect width="14.8" height="19.9" rx="2.6" fill="#666"/></symbol><path id="D" d="M577.8 171.2l-6.1 14.6 6.5-15.6"/><path id="E" d="M576.8 170.8l-6 14.6 6.5-15.6"/></defs><rect x="5.5" y="5.5" width="646" height="392.5" rx="14.5" class="AN"/><path d="M637 7c7.2 0 13 5.8 13 13v363.5c0 7.2-5.8 13-13 13H20c-7.2 0-13-5.8-13-13V20c0-7.2 5.8-13 13-13h617m0-3H20C11.2 4 4 11.2 4 20v363.5c0 8.8 7.2 16 16 16h617c8.8 0 16-7.2 16-16V20c0-8.8-7.2-16-16-16h0z" class="AY"/><path d="m637,4c8.8,0,16,7.2,16,16v363.5c0,8.8-7.2,16-16,16H20c-8.8,0-16-7.2-16-16V20c0-8.8,7.2-16,16-16h617m0-4H20C9,0,0,9,0,20v363.5c0,11,9,20,20,20h617c11,0,20-9,20-20V20c0-11-9-20-20-20h0Z" class="AO"/><g class="AM AQ AR AV"><use xlink:href="#D" class="AK"/><use xlink:href="#E" class="AL"/><use xlink:href="#D" x="6" class="AK"/><use xlink:href="#E" x="6" class="AL"/><use xlink:href="#D" x="12" class="AK"/><use xlink:href="#E" x="12" class="AL"/><use xlink:href="#D" x="18" class="AK"/><use xlink:href="#E" x="18" class="AL"/><use xlink:href="#D" x="24" class="AK"/><use xlink:href="#E" x="24" class="AL"/><use xlink:href="#D" x="30" class="AK"/><use xlink:href="#E" x="30" class="AL"/><use xlink:href="#D" x="36" class="AK"/><use xlink:href="#E" x="36" class="AL"/><use xlink:href="#D" x="42" class="AK"/><use xlink:href="#E" x="42" class="AL"/><use xlink:href="#D" x="48" class="AK"/><use xlink:href="#E" x="48" class="AL"/></g><text class="M N AO AT AU" transform="matrix(0 1 -1 0 617 238.8)" font-size="22"><tspan x="0" y="0">CITIZEN</tspan></text><path d="M103 405c-1.5 0-2.8-.7-3.6-1.9s-1.1-2.6-.6-4l25.3-77.7c1.1-3.2 4-5.4 7.4-5.4h401.8c3.6 0 6.8 2.6 7.6 6.1l16.8 77.4c.3 1.3 0 2.7-.9 3.8s-2.1 1.7-3.5 1.7H103z" class="AN"/><path d="M533.3 317.5c2.9 0 5.5 2.1 6.2 5l16.8 77.4c.2.9 0 1.8-.6 2.5s-1.4 1.1-2.3 1.1H103c-1 0-1.9-.5-2.4-1.2-.6-.8-.7-1.8-.4-2.7l25.3-77.7c.8-2.6 3.2-4.3 6-4.3h401.8m0-3H131.5c-4 0-7.6 2.6-8.8 6.4l-25.3 77.7c-1.3 3.9 1.6 7.9 5.7 7.9h450.3c3.8 0 6.7-3.5 5.9-7.3l-16.8-77.4c-.9-4.3-4.7-7.3-9.1-7.3h0z" class="AY"/><path d="m533.3,314.5c4.4,0,8.2,3,9.1,7.3l16.8,77.4c.8,3.7-2,7.3-5.9,7.3H103c-4.1,0-7-4-5.7-7.9l25.3-77.7c1.2-3.8,4.8-6.4,8.8-6.4h401.8m0-3H131.5c-5.3,0-10,3.4-11.7,8.5l-25.3,77.7c-.9,2.8-.4,5.7,1.3,8.1s4.4,3.7,7.3,3.7h450.3c2.7,0,5.3-1.2,7-3.4,1.7-2.1,2.4-4.9,1.8-7.6l-16.8-77.4c-1.2-5.6-6.3-9.7-12-9.7h0Z" class="AP"/><circle cx="163.6" cy="171.5" r="123.5" fill="#2d2d2d"/><circle cx="163.6" cy="171.5" r="123.5" stroke="#000" stroke-width="6" class="AM AR"/><path d="M163.6 48c68.2 0 123.5 55.3 123.5 123.5S231.8 295 163.6 295 40.1 239.7 40.1 171.5 95.4 48 163.6 48m0-1c-33.3 0-64.5 13-88 36.5s-36.5 54.8-36.5 88 13 64.5 36.5 88 54.8 36.5 88 36.5 64.5-13 88-36.5 36.5-54.8 36.5-88-13-64.5-36.5-88-54.8-36.5-88-36.5h0z" fill="#726f76"/><circle cx="53.1" cy="323" r="30" class="AN"/><path d="m53.1,294.5c15.7,0,28.5,12.8,28.5,28.5s-12.8,28.5-28.5,28.5-28.5-12.8-28.5-28.5,12.8-28.5,28.5-28.5m0-3c-17.4,0-31.5,14.1-31.5,31.5s14.1,31.5,31.5,31.5,31.5-14.1,31.5-31.5-14.1-31.5-31.5-31.5h0Z" class="AY"/><path d="M53.1 291.5c17.4 0 31.5 14.1 31.5 31.5s-14.1 31.5-31.5 31.5-31.5-14.1-31.5-31.5 14.1-31.5 31.5-31.5m0-3c-19 0-34.5 15.5-34.5 34.5s15.5 34.5 34.5 34.5S87.6 342 87.6 323s-15.5-34.5-34.5-34.5h0z" class="AO"/><circle cx="163.1" cy="171" r="48.5" fill="#a59d5e"/><path d="m163.1,126c24.9,0,45,20.1,45,45s-20.1,45-45,45-45-20.1-45-45,20.1-45,45-45m0-7c-28.7,0-52,23.3-52,52s23.3,52,52,52,52-23.3,52-52-23.3-52-52-52h0Z"/><path d="M163.1 111.5c32.9 0 59.5 26.6 59.5 59.5s-26.6 59.5-59.5 59.5-59.5-26.6-59.5-59.5 26.6-59.5 59.5-59.5m0-1c-33.4 0-60.5 27.1-60.5 60.5s27.1 60.5 60.5 60.5 60.5-27.1 60.5-60.5-27.1-60.5-60.5-60.5h0zm0-7.6c37.6 0 68.1 30.5 68.1 68.1s-30.5 68.1-68.1 68.1S95 208.6 95 171s30.5-68.1 68.1-68.1m0-1c-18.9 0-36.2 7.6-48.9 20.3-12.7 12.6-20.3 29.9-20.3 48.9s7.6 36.2 20.3 48.9c12.7 12.6 29.9 20.3 48.9 20.3s36.2-7.6 48.9-20.3c12.6-12.6 20.3-29.9 20.3-48.9s-7.6-36.2-20.3-48.9c-12.6-12.7-29.9-20.3-48.9-20.3h0zm0-7.6c42.4 0 76.7 34.3 76.7 76.7s-34.4 76.7-76.7 76.7-76.7-34.4-76.7-76.7 34.3-76.7 76.7-76.7m0-1c-21.1 0-40.6 8.4-54.9 22.8s-22.8 33.8-22.8 55 8.4 40.6 22.8 54.9c14.3 14.4 33.8 22.8 54.9 22.8s40.6-8.4 54.9-22.8 22.8-33.8 22.8-54.9-8.4-40.6-22.8-54.9-33.8-22.8-54.9-22.8h0zm0-7.6c47.1 0 85.3 38.2 85.3 85.3s-38.2 85.4-85.4 85.4-85.3-38.2-85.3-85.4 38.2-85.3 85.3-85.3m0-1c-23.3 0-45 9.2-61.1 25.3s-25.3 37.7-25.3 61.1 9.2 45 25.3 61.1 37.7 25.3 61.1 25.3 45-9.2 61.1-25.3 25.3-37.7 25.3-61.1-9.2-45-25.3-61.1-37.7-25.3-61.1-25.3h0zm.1-7.7c51.9 0 94 42.1 94 94s-42.1 94-94 94-94-42.1-94-94 42.1-94 94-94m0-1c-25.6 0-49.4 10.1-67.1 27.8s-27.8 41.6-27.8 67.1S78.3 220.3 96 238s41.6 27.8 67.1 27.8 49.4-10.1 67.1-27.8 27.8-41.6 27.8-67.1-10.1-49.4-27.8-67.1S188.6 76 163.1 76h0zm0-7.6c56.7 0 102.6 45.9 102.6 102.6s-45.9 102.6-102.6 102.6S60.5 227.7 60.5 171 106.4 68.4 163.1 68.4m0-1c-27.8 0-53.8 10.9-73.2 30.3-19.5 19.4-30.3 45.4-30.3 73.2s10.9 53.8 30.3 73.2c19.5 19.5 45.5 30.3 73.2 30.3s53.8-10.9 73.2-30.3 30.3-45.4 30.3-73.2-10.9-53.8-30.3-73.2-45.4-30.3-73.2-30.3h0zm0-7.6c61.4 0 111.2 49.8 111.2 111.2s-49.8 111.2-111.2 111.2S51.9 232.4 51.9 171 101.7 59.8 163.1 59.8m0-1c-30 0-58.2 11.7-79.3 32.9S50.9 141 50.9 171s11.7 58.2 32.9 79.3 49.3 32.9 79.3 32.9 58.2-11.7 79.3-32.9c21.2-21.1 32.9-49.3 32.9-79.3s-11.7-58.2-32.9-79.3c-21.1-21.2-49.3-32.9-79.3-32.9h0z" fill="#726f76"/><circle cx="163.1" cy="171" r="6.5"/><rect x="213.1" y="351.5" width="247.5" height="41" rx="8" class="AP"/><path d="m452.6,352.5c3.9,0,7,3.1,7,7v25c0,3.9-3.1,7-7,7h-231.5c-3.9,0-7-3.1-7-7v-25c0-3.9,3.1-7,7-7h231.5m0-2h-231.5c-4.9,0-9,4-9,9v25c0,5,4.1,9,9,9h231.5c5,0,9-4,9-9v-25c0-5-4-9-9-9h0Z" fill="#666"/><rect x="320.1" y="77.5" width="302.5" height="68" rx="11.7" class="AP"/><path d="M610.9 78.5c5.9 0 10.7 4.8 10.7 10.7v44.6c0 5.9-4.8 10.7-10.7 10.7H331.8c-5.9 0-10.7-4.8-10.7-10.7V89.2c0-5.9 4.8-10.7 10.7-10.7h279.1m0-2H331.8c-7 0-12.7 5.7-12.7 12.7v44.6c0 7 5.7 12.7 12.7 12.7h279.1c7 0 12.7-5.7 12.7-12.7V89.2c0-7-5.7-12.7-12.7-12.7h0z" fill="#666"/><path d="M324.4 161.5h225.9c2.4 0 4.3 1.9 4.3 4.3v24.4c0 2.4-1.9 4.3-4.3 4.3H324.4c-2.4 0-4.3-1.9-4.3-4.3v-24.4c0-2.4 1.9-4.3 4.3-4.3h0z" fill="#a59d5e"/><path d="m550.3,162.5c1.8,0,3.3,1.5,3.3,3.3v24.4c0,1.8-1.5,3.3-3.3,3.3h-225.9c-1.8,0-3.3-1.5-3.3-3.3v-24.4c0-1.8,1.5-3.3,3.3-3.3h225.9m0-2h-225.9c-2.9,0-5.3,2.4-5.3,5.3v24.4c0,2.9,2.4,5.3,5.3,5.3h225.9c2.9,0,5.3-2.4,5.3-5.3v-24.4c0-2.9-2.4-5.3-5.3-5.3h0Z" fill="#666"/><text class="c N AW AZ" font-size="20"><tspan x="229" y="378">',
                                _padStart(tokenId.toString(), 8, "0"),
                                '</tspan></text><text class="e N AW AX AZ"><tspan x="338" y="130">',
                                _createdAt(passport, tokenId),
                                '</tspan></text><text class="AB N AO AT AU AX"><tspan x="56" y="31">VINYL NATION</tspan></text><text class="AC N AN AT AU" font-size="15"><tspan x="338" y="107">DATE OF MINT:</tspan></text><text class="e N AW AX AZ"><tspan x="491" y="130">',
                                _updatedAt(passport, tokenId),
                                '</tspan></text><text class="AC N AN AT AU" font-size="15"><tspan x="491" y="107">LAST UPDATED:</tspan></text><text class="AE N AO AT AU" font-size="15"><tspan x="223" y="343">/// PASSPORT NO:</tspan><tspan x="328" y="63">/////</tspan></text><text class="AF N AW AX" fill="#fff"><tspan x="336" y="185">',
                                _username(passport, tokenId),
                                '</tspan></text><rect x="39.6" y="295.6" width="17" height="26" rx="3" transform="matrix(.094108 -.995562 .995562 .094108 -263.7 327.1)"/><path d="M59.4 335.2h-.3l-26.9-2.6c-1.6-.2-2.9-1.6-2.7-3.3l1.6-16.9c.1-1.5 1.4-2.7 3-2.7h.3l26.9 2.6c1.7.2 2.9 1.6 2.7 3.3l-1.6 16.9c-.2 1.5-1.4 2.7-3 2.7h0z" class="AN"/><path d="M34.1 310.8h.2l26.9 2.6c1.1.1 1.9 1.1 1.8 2.2l-1.6 16.9c0 1-1 1.8-2 1.8h-.2l-26.9-2.6c-1.1-.1-1.9-1.1-1.8-2.2l1.6-16.9c0-1 1-1.8 2-1.8m0-2h0a4.02 4.02 0 0 0-4 3.6l-1.6 16.9c-.2 2.2 1.4 4.1 3.6 4.4l26.9 2.6h.4a4.02 4.02 0 0 0 4-3.6l1.6-16.9c0-1.1-.2-2.1-.9-2.9s-1.6-1.3-2.7-1.4l-26.9-2.6h-.4 0z" class="AO"/><path d="M48.4 305.1l3.5-36.9.6-16.9v-7.2L49 170.5c-.1-3.9.8-7.7 2.7-11.1l6.6-12" stroke-width="5" stroke="#000" class="AM AQ AR"/><path d="M55.3 294.7h-.2l-10.7-1c-1.4-.1-2.5-1.4-2.3-2.8l2.5-26.7c.1-1.4 1.2-2.4 2.6-2.4h.2l10.7 1c.7 0 1.3.4 1.8.9s.7 1.2.6 1.9L58 292.3c-.1 1.3-1.2 2.4-2.6 2.4h0z" class="AN"/><path d="M47.1 262.8h.2l10.7 1c.9 0 1.5.9 1.5 1.8L57 292.3c0 .8-.8 1.5-1.6 1.5h-.2l-10.7-1c-.9 0-1.5-.9-1.5-1.8l2.5-26.7c0-.8.8-1.5 1.6-1.5m0-2h0c-1.9 0-3.4 1.4-3.6 3.3L41 290.8c-.2 2 1.3 3.7 3.2 3.9l10.7 1h.3c1.9 0 3.4-1.4 3.6-3.3l2.5-26.7c0-1-.2-1.9-.8-2.6s-1.5-1.2-2.4-1.3l-10.7-1h-.3 0z" class="AO"/><path d="M60 157.9c-.6 0-1.2-.2-1.7-.6l-6.8-5.6c-.5-.4-.9-1.1-1-1.8s.1-1.4.6-1.9l8.5-10.2c.5-.6 1.2-1 2-1s1.2.2 1.7.6l6.8 5.6c.5.4.9 1.1.9 1.8s-.1 1.4-.6 1.9l-8.5 10.2c-.5.6-1.2 1-2 1h0z" class="AN"/><path d="M61.7 138.3c.3 0 .5 0 .7.3l6.8 5.6c.5.4.6 1.1.2 1.6L60.9 156c-.2.3-.5.4-.9.4s-.5 0-.7-.3l-6.8-5.6c-.5-.4-.5-1.1-.2-1.6l8.5-10.2c.2-.3.5-.4.9-.4m0-3h0c-1.2 0-2.4.6-3.2 1.5L50 147c-1.5 1.8-1.2 4.4.5 5.8l6.8 5.6c.7.6 1.7.9 2.6.9s2.4-.6 3.2-1.5l8.5-10.2c.7-.9 1-1.9.9-3 0-1.1-.6-2.1-1.5-2.8l-6.8-5.6c-.7-.6-1.7-.9-2.6-.9h0z" class="AO"/><rect x="59.4" y="130.8" width="17.3" height="17" rx="2.6" transform="matrix(.637424 -.770513 .770513 .637424 -82.6 102.9)"/><path d="m79.4,140.6c-.8,0-1.6-.3-2.2-.8l-11.1-9.2c-1.5-1.2-1.7-3.4-.5-4.9l22.6-27.3c.7-.8,1.7-1.3,2.7-1.3s1.6.3,2.2.8l11.1,9.2c1.5,1.2,1.7,3.4.5,4.9l-22.6,27.3c-.7.8-1.7,1.3-2.7,1.3h0Z" class="AN"/><path d="M90.9 98.2c.6 0 1.1.2 1.6.6l11.1 9.2c1.1.9 1.2 2.5.3 3.5l-22.6 27.3c-.5.6-1.2.9-1.9.9s-1.1-.2-1.6-.6l-11.1-9.2c-1.1-.9-1.2-2.5-.3-3.5L89 99.1c.5-.6 1.2-.9 1.9-.9m0-2h0c-1.3 0-2.6.6-3.5 1.6l-22.6 27.3c-1.6 1.9-1.3 4.8.6 6.3l11.1 9.2c.8.7 1.8 1 2.9 1s2.6-.6 3.5-1.6l22.6-27.3c1.6-1.9 1.3-4.8-.6-6.3l-11.1-9.2c-.8-.7-1.8-1-2.9-1h0z" class="AO"/><use width="27" height="27" xlink:href="#A" x="13" y="13.3"/><use width="27" height="27" xlink:href="#A" x="616.7" y="13.3"/><use width="27" height="27" xlink:href="#A" x="617.2" y="363.3"/><use width="27" height="27" xlink:href="#A" x="13" y="363.3"/><use width="21" height="21" xlink:href="#B" x="503" y="332.3"/><use width="21" height="21" xlink:href="#B" x="520.8" y="372.3"/><use width="21" height="21" xlink:href="#B" x="116.1" y="372.3"/><use width="21" height="21" xlink:href="#B" x="134.1" y="332.3"/><g stroke-linecap="square" class="AM AR AV"><path d="M626 210.7H323.1" class="AK"/><path d="M626 209.7H323.1" class="AL"/><path d="M607 62.7H376" class="AK"/><path d="M607 61.7H376" class="AL"/><path d="M607 53.7H376" class="AK"/><path d="M607 52.7H376" class="AL"/></g><g class="AS Aa"><rect x="381.4" y="231.3" width="3.6" height="58.1" rx="1.3" class="AP"/><path d="m389.5,268.6c0-.7-.6-1.3-1.3-1.3h-10.5c-.7,0-1.3.6-1.3,1.3v6.2h13.1v-6.2h0Z" class="Ab"/><path d="m376.4,274.8v6.3c0,.7.6,1.3,1.3,1.3h10.5c.7,0,1.3-.6,1.3-1.3v-6.3h-13.1,0Z" class="AP"/></g><g class="AM AQ AR Ac"><path d="M388 277.3h-9.9m9.9 2h-9.9" stroke="#666"/><path d="M388 268.3h-9.9" class="Ad"/></g><g class="AS Aa"><rect x="358.4" y="231.3" width="3.6" height="58.1" rx="1.3" class="AP"/><path d="m366.5,243.6c0-.7-.6-1.3-1.3-1.3h-10.5c-.7,0-1.3.6-1.3,1.3v6.2h13.1v-6.2h0Z" class="Ab"/><path d="m353.4,249.8v6.3c0,.7.6,1.3,1.3,1.3h10.5c.7,0,1.3-.6,1.3-1.3v-6.3h-13.1,0Z" class="AP"/></g><g class="AM AQ AR Ac"><path d="M365 252.3h-9.9m9.9 2h-9.9" stroke="#666"/><path d="M365 243.3h-9.9" class="Ad"/></g><g class="AS Aa"><rect x="335.4" y="231.3" width="3.6" height="58.1" rx="1.3" class="AP"/><path d="m343.5,264.6c0-.7-.6-1.3-1.3-1.3h-10.5c-.7,0-1.3.6-1.3,1.3v6.2h13.1v-6.2h0Z" class="Ab"/><path d="m330.4,270.8v6.3c0,.7.6,1.3,1.3,1.3h10.5c.7,0,1.3-.6,1.3-1.3v-6.3h-13.1,0Z" class="AP"/></g><g class="AM AQ AR Ac"><path d="M342 273.3h-9.9m9.9 2h-9.9" stroke="#666"/><path d="M342 264.3h-9.9" class="Ad"/></g><use width="14.8" height="19.9" xlink:href="#C" x="416" y="265.4"/><use width="14.8" height="19.9" xlink:href="#C" x="438.7" y="265.4"/><use width="14.8" height="19.9" xlink:href="#C" x="461.4" y="265.4"/><use width="14.8" height="19.9" xlink:href="#C" x="506.9" y="265.4"/><use width="14.8" height="19.9" xlink:href="#C" x="529.7" y="265.4"/><use width="14.8" height="19.9" xlink:href="#C" x="575.2" y="265.4"/><use width="14.8" height="19.9" xlink:href="#C" x="484.2" y="265.4"/><use width="14.8" height="19.9" xlink:href="#C" x="552.4" y="265.4"/><use width="14.8" height="19.9" xlink:href="#C" x="416" y="236.1"/><use width="14.8" height="19.9" xlink:href="#C" x="438.7" y="236.1"/><use width="14.8" height="19.9" xlink:href="#C" x="461.4" y="236.1"/><use width="14.8" height="19.9" xlink:href="#C" x="506.9" y="236.1"/><use width="14.8" height="19.9" xlink:href="#C" x="529.7" y="236.1"/><use width="14.8" height="19.9" xlink:href="#C" x="575.2" y="236.1"/><use width="14.8" height="19.9" xlink:href="#C" x="484.2" y="236.1"/><use width="14.8" height="19.9" xlink:href="#C" x="552.4" y="236.1"/></svg>'
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
