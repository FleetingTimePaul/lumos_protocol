require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3");


require("dotenv").config({
    path: require("path").join(__dirname, ".env"),
});

module.exports = {
    solidity: {
        version: "0.8.12",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    networks: {
        rinkeby: {
            url: process.env.RINKEBY_PROVIDER,
            accounts: [process.env.RINKEBY_DEPLOYER],
        },
        bsctest: {
            url: process.env.BSCTEST_PROVIDER,
            accounts: [process.env.BSCTEST_DEPLOYER],
        },
        bscmain: {
            url: process.env.BSCMAIN_PROVIDER,
            accounts: [process.env.BSCMAIN_DEPLOYER],
            gasPrice: 10000000000
        },
        polygontest: {
            url: process.env.POLYGONTEST_PROVIDER,
            accounts: [process.env.POLYGONTEST_DEPLOYER],
        },
    },
    etherscan: {
        apiKey: {
            mainnet: process.env.ETHERSCAN_API_KEY,
            bscTestnet: process.env.BSCTEST_API_KEY,
        }
    },
};
