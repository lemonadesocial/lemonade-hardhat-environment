// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ChainlinkRequest is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    bytes32 private _jobId;
    uint256 private _fee;
    string private _url;

    struct PendingRequest {
        address sender;
        bytes4 selector;
        bytes state;
    }
    mapping(bytes32 => PendingRequest) private _pendingRequests;

    constructor(
        address chainlinkToken,
        address chainlinkOracle,
        bytes32 jobId,
        uint256 fee,
        string memory url
    ) {
        configure(chainlinkToken, chainlinkOracle, jobId, fee, url);
    }

    function configure(
        address chainlinkToken,
        address chainlinkOracle,
        bytes32 jobId,
        uint256 fee,
        string memory url
    ) public onlyOwner {
        setChainlinkToken(chainlinkToken);
        setChainlinkOracle(chainlinkOracle);

        _jobId = jobId;
        _fee = fee;
        _url = url;
    }

    function requestBytes(bytes4 selector, bytes memory state)
        public
        returns (bytes32 requestId)
    {
        uint256 selector_;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 4, 4)
            selector_ := shr(224, mload(ptr))
        }

        Chainlink.Request memory req = buildChainlinkRequest(
            _jobId,
            address(this),
            this.fulfillBytes.selector
        );
        req.add(
            "get",
            string(
                abi.encodePacked(
                    _url,
                    "&sender=",
                    Strings.toHexString(uint256(uint160(msg.sender)), 20),
                    "&selector=",
                    Strings.toHexString(selector_, 4),
                    "&state=",
                    Base64.encode(state)
                )
            )
        );
        req.add("path", "data");
        requestId = sendChainlinkRequest(req, _fee);

        _pendingRequests[requestId] = PendingRequest({
            sender: msg.sender,
            selector: selector,
            state: state
        });
        return requestId;
    }

    function fulfillBytes(bytes32 requestId, bytes memory bytesData)
        public
        recordChainlinkFulfillment(requestId)
    {
        PendingRequest memory pendingRequest = _pendingRequests[requestId];

        (bool success, bytes memory result) = pendingRequest.sender.call(
            abi.encodeWithSelector(
                pendingRequest.selector,
                pendingRequest.state,
                bytesData
            )
        );
        if (!success) {
            if (result.length > 0) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            } else {
                revert("ChainlinkRequest: callback failed");
            }
        }

        delete _pendingRequests[requestId];
    }

    function withdrawLink(address to) public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(to, link.balanceOf(address(this))),
            "ChainlinkRequest: unable to transfer"
        );
    }
}
