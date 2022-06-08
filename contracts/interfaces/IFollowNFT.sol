// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IFollowNFT {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _profileId,
        address _lumos
    ) external;

    function mint(address to) external returns (uint256);
    function setFollowNFTURI(string calldata followNFTURI) external;
}
