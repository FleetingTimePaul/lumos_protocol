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
    var Lumos = await ethers.getContractFactory("Lumos");
    var Factory = await ethers.getContractFactory("Factory");

    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    var followNFTImpl = await FollowNFT.deploy();
    await followNFTImpl.deployed();
    console.log("deploy followNFTImpl at: ", followNFTImpl.address);

    var profileNFTImpl = await ProfileNFT.deploy();
    await profileNFTImpl.deployed();
    console.log("deploy profileNFTImpl at: ", profileNFTImpl.address);

    var contentNFTImpl = await ContentNFT.deploy();
    await contentNFTImpl.deployed();
    console.log("deploy contentNFTImpl at: ", contentNFTImpl.address);

    var lumos = await upgrades.deployProxy(Lumos, [], { initializer: false });
    await lumos.deployed();
    console.log("deploy lumos at: ", lumos.address);
    var factory = await upgrades.deployProxy(Factory, [
        deployer.address,
        lumos.address,
        followNFTImpl.address,
        contentNFTImpl.address,
        profileNFTImpl.address,
    ]);

    await factory.deployed();
    console.log("deploy factory at: ", factory.address);

    var contentNFTInitializeData = web3.eth.abi.encodeFunctionCall(
        {
            inputs: [
                {
                    internalType: "string",
                    name: "_name",
                    type: "string",
                },
                {
                    internalType: "string",
                    name: "_symbol",
                    type: "string",
                },
                {
                    internalType: "address",
                    name: "_lumos",
                    type: "address",
                },
            ],
            name: "initialize",
            outputs: [],
            stateMutability: "nonpayable",
            type: "function",
        },
        ["Lumos Content NFT", "LCN", lumos.address]
    );
    var profileNFTInitializeData = web3.eth.abi.encodeFunctionCall(
        {
            inputs: [
                {
                    internalType: "string",
                    name: "_name",
                    type: "string",
                },
                {
                    internalType: "string",
                    name: "_symbol",
                    type: "string",
                },
                {
                    internalType: "address",
                    name: "_lumos",
                    type: "address",
                },
            ],
            name: "initialize",
            outputs: [],
            stateMutability: "nonpayable",
            type: "function",
        },
        ["Lumos Profile NFT", "LPN", lumos.address]
    );
    await lumos.initialize(
        deployer.address,
        factory.address,
        profileNFTInitializeData,
        contentNFTInitializeData
    );
}

main();
