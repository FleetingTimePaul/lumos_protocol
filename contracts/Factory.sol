// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "./interfaces/IFollowNFT.sol";
import "./interfaces/ILumosBeacon.sol";

contract Factory is Initializable, AccessControlEnumerable {
    event FollowNFTDeployed(address followNFT, bytes initializeData);
    event ProfileNFTDeployed(address profileNFT, bytes initializeData);

    address private _followNFTBeacon;
    address private _contentNFTBeacon;
    address private _profileNFTBeacon;

    address private _lumos;

    function initialize(
        address admin,
        address lumos,
        address followNFTImpl,
        address contentNFTImpl,
        address profileNFTImpl
    ) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _lumos = lumos;
        _followNFTBeacon = address(new UpgradeableBeacon(followNFTImpl));
        _contentNFTBeacon = address(new UpgradeableBeacon(contentNFTImpl));
        _profileNFTBeacon = address(new UpgradeableBeacon(profileNFTImpl));
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Factory: only admin");
        _;
    }

    function getContentNFTImpl() external view returns (address) {
        return ILumosBeacon(_contentNFTBeacon).implementation();
    }

    function setContentNFTImpl(address _contentNFTImpl) external onlyAdmin {
        ILumosBeacon(_contentNFTBeacon).upgradeTo(_contentNFTImpl);
    }

    function getProfileNFTImpl() external view returns (address) {
        return ILumosBeacon(_profileNFTBeacon).implementation();
    }

    function setProfileNFTImpl(address _profileNFTImpl) external onlyAdmin {
        ILumosBeacon(_profileNFTBeacon).upgradeTo(_profileNFTImpl);
    }

    function getFollowNFTImpl() external view returns (address) {
        return ILumosBeacon(_followNFTBeacon).implementation();
    }

    function setFollowNFTImpl(address _followNFTImpl) external onlyAdmin {
        ILumosBeacon(_followNFTBeacon).upgradeTo(_followNFTImpl);
    }

    function deployFollowNFT(bytes memory initializeData)
        external
        returns (address)
    {
        require(msg.sender == _lumos, "Factory: not lumos");
        address followNFT = address(
            new BeaconProxy(_followNFTBeacon, initializeData)
        );
        emit FollowNFTDeployed(followNFT, initializeData);
        return followNFT;
    }

    function deployProfileNFT(bytes memory initializeData)
        external
        returns (address)
    {
        require(msg.sender == _lumos, "Factory: not lumos");
        address profileNFT = address(
            new BeaconProxy(_profileNFTBeacon, initializeData)
        );
        emit ProfileNFTDeployed(profileNFT, initializeData);
        return profileNFT;
    }

    function deployContentNFT(bytes memory initializeData)
        external
        returns (address)
    {
        require(msg.sender == _lumos, "Factory: not lumos");
        address contentNFT = address(
            new BeaconProxy(_contentNFTBeacon, initializeData)
        );
        emit ProfileNFTDeployed(contentNFT, initializeData);
        return contentNFT;
    }
}
