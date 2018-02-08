module.exports = {
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    },
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "314", // pre-configured TestRPC
            gasPrice: 20000000000,
            gas: 4000000
        },

        ropsten: {
            host: "localhost",
            port: 8546,
            network_id: "3",
            gasPrice: 40000000000
        },

        rinkeby: {
            host: "localhost",
            port: 8544,
            network_id: "4",
            gasPrice: 40000000000,
            gas: 4000000
        }
    }
};
