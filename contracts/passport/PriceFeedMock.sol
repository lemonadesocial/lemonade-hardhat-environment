// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PriceFeedMock {
    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    mapping(uint80 => RoundData) internal _roundData;
    RoundData internal _latestRound;
    uint8 internal _decimal;

    constructor(uint8 decimal_, RoundData[] memory rounds) {
        _decimal = decimal_;

        uint256 length = rounds.length;
        for (uint256 i = 0; i < length; ) {
            RoundData memory data = rounds[i];
            _roundData[data.roundId] = data;

            unchecked {
                ++i;
            }
        }

        _latestRound = rounds[length - 1];
    }

    function decimals() external view returns (uint8) {
        return _decimal;
    }

    function latestRoundData() external view returns (RoundData memory data) {
        data = _latestRound;
    }

    function getRoundData(
        uint80 _roundId
    ) public view returns (RoundData memory data) {
        data = _roundData[_roundId];
    }
}
