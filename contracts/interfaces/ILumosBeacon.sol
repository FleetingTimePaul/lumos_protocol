// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;


import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

interface ILumosBeacon is IBeacon {
	function upgradeTo(address newImplementation) external;
}