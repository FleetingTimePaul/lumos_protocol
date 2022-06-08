// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IFactory {
    function deployFollowNFT(bytes calldata initializeData) external returns(address);
    function deployProfileNFT(bytes calldata initializeData) external returns(address);
    function deployContentNFT(bytes calldata initializeData) external returns(address);
}
