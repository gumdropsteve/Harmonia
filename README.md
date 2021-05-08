# Decentralized Autonomous Resolutions
Peer to peer dispute resolution.

## Description
A contract for dispute resolution.

#### Trust Issue
Disputes are resolved in an honest and fair way without 3rd party (corporate) interests influncing outcomes.

### Demo
#### Live Demo

#### Video

### Architecture diagram
![Architecture diagram](https://lh5.googleusercontent.com/tlU469mcXo9YM3XvwThlGU5GB8fIdXe-jSwqN0WJScORjkI6wAnCPiNU5NaIUQEb0gZkW0FEhCK6yCQ-VXiPqznxHIhy-pRhxCq9Z1n-wT2MaB6bjlgGTcvVLkJFe7u5IMRlsFwy)

## Getting Started
### On SKALE
```
git clone https://github.com/gumdropsteve/dispute-resolution

cd dispute-resolution

npm install

truffle compile

truffle migrate --reset --network skale -f 2
```

#### Adding SKALE to Metamask
https://skale.network/docs/developers/wallets/getting-started#metamask
1. Add a Custom RPC Network
2. Network URL: https://eth-global-0.skalenodes.com:10456
3. Chain ID: 0xb9454a5c40f66

### Unit tests
To run the unit testing scripts
```
truffle test ./test/Arbitrator_test.js

truffle test ./test/Token_test.js
```

## Tech Used
<img align="right" width="150" height="150" src="https://lh6.googleusercontent.com/3WDXeY6cvDfW5-P6rmqtun9dRYYCtQa_c4MFqjNssE2CE4h2t8VfG5iHMADLNaX-Mq8kS7hQeEe99DV7lA-1tpCbtxirq6MFuMiJJQoSJU3vrCpNCuzLzbWWby2Ug7qAn9jfeVKt">

#### NuCypher
Cryptographic Infrastructure for Privacy-Preserving Applications
- [GitHub](https://github.com/nucypher/)
- [Website](https://www.nucypher.com/)
- We used NuCypher to help keep votes private while the voting period is live so that voters are not influenced by other voters

<img align="right" width="150" height="150" src="https://lh3.googleusercontent.com/YSzrZ4MAb3oDhGDo1d0yZ-ET8Bhb5b6RUbKJGXqKPMSFNEt8kKtqDQmyc7TZn6uQJllHQlU6VQxdt3uw2EW_RQEG6dU5py3d3VGcCtOY2U79rbHq5u4rpGFh8lBbnQQzDp7iLO34">

#### SKALE
Decentralized modular environment for Solidity dApps
- [GitHub](https://github.com/skalenetwork/)
- [Website](https://skale.network/)
- We used SKALE to eliminate gas fees and reduce costs


## Future Direction
This dispute resolution contract was origionally thought of as part of a decentralized real estate rental service, making AirBnb like disputes between guests and hosts more transparent and honest.
