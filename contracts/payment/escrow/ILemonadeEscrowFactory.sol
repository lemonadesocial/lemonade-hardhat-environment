// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILemonadeEscrowFactory {
    error CannotPayFee();

    function getSigner() external returns (address);
}
