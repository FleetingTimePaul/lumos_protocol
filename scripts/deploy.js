const { ethers, network, web3, upgrades } = require("hardhat");

var path = require("path");

// npx hardhat run scripts/deploy.js --network bsctest

async function main() {
    var deployConfig = require(path.join(
        path.dirname(__dirname),
        "deploy-config.js"
    ))[network.name];

    var FollowNFT = await ethers.getContractFactory("FollowNFT");
    var ProfileNFT = await ethers.getContractFactory("ProfileNFT");
    var ContentNFT = await ethers.getContractFactory("ContentNFT");
    var Controller = await ethers.getContractFactory("Controller");

    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);


    var controller = await upgrades.deployProxy(Controller, [], { initializer: false });
    await controller.deployed();
    console.log("deploy controller at: ", controller.address);

    var followNFTBeacon = await upgrades.deployBeacon(FollowNFT);
    await followNFTBeacon.deployed();
    console.log("deploy followNFTBeacon at: ", followNFTBeacon.address);

    var profileNFT = await upgrades.deployProxy(ProfileNFT, ["Profile NFT", "ProfileNFT", controller.address]);
    await profileNFT.deployed();
    console.log("deploy profileNFT at: ", profileNFT.address);

    var contentNFT = await upgrades.deployProxy(ContentNFT, ["Content NFT", "ContentNFT", controller.address]);
    await contentNFT.deployed();
    console.log("deploy contentNFT at: ", contentNFT.address);

    await controller.initialize(deployer.address, profileNFT.address, contentNFT.address, followNFTBeacon.address);
}

main();
