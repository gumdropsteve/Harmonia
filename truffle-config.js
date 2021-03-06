const HDWalletProvider = require('@truffle/hdwallet-provider')
require('dotenv').config()

const key = process.env.PRIVATE_KEY
const url = process.env.RPC_URL
const skale_url = process.env.SKALE_CHAIN
const skale_key = process.env.SKALE_PRIVATE_KEY

module.exports = {
  networks: {
    cldev: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
    },
    ganache: {
      host: '127.0.0.1',
      port: 7545,
      network_id: '*',
    },
    binance_testnet: {
      provider: () => new HDWalletProvider(key,'https://data-seed-prebsc-1-s1.binance.org:8545'),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    kovan: {
      provider: () => {
        return new HDWalletProvider(key, url)
      },
      network_id: '42',
      skipDryRun: true
    },
    rinkeby: {
      provider: () => {
        return new HDWalletProvider(key, url)
      },
      network_id: '4',
      skipDryRun: true
    },
    skale: {
      provider: () => {
        return new HDWalletProvider(skale_key, skale_url)
      },
      gasPrice: 0,
      network_id: '*',
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: '0.6.6',
    },
  },
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  },
  plugins: [ 
    'truffle-plugin-verify'
  ]
}
