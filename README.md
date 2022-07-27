# Lemonade Hardhat Environment
[![Known Vulnerabilities](https://snyk.io/test/github/lemonadesocial/lemonade-hardhat-environment/badge.svg)](https://snyk.io/test/github/lemonadesocial/lemonade-hardhat-environment)

This repository contains our Ethereum environment. You find the code of our Smart Contracts under *contracts*, the scripts used to deploy these Smart Contracts under *deploy*, their actual deployments and addresses under *deployments*, the code for testing these Smart Contracts for correct behavior under *test*, and the Hardhat compatible development environment under the root.

## Install

```shell
yarn install
```

## Usage

```shell
yarn hardhat --help
```

```
Usage: hardhat [GLOBAL OPTIONS] <TASK> [TASK OPTIONS]

GLOBAL OPTIONS:

  --config              A Hardhat config file.
  --emoji               Use emoji in messages.
  --help                Shows this message, or a task's help if its name is provided
  --max-memory          The maximum amount of memory that Hardhat can use.
  --network             The network to connect to.
  --show-stack-traces   Show stack traces.
  --tsconfig            Reserved hardhat argument -- Has no effect.
  --verbose             Enables Hardhat verbose logging
  --version             Shows hardhat's version.


AVAILABLE TASKS:

  check                 Check whatever you need
  clean                 Clears the cache and deletes all artifacts
  compile               Compiles the entire project, building all artifacts
  console               Opens a hardhat console
  deploy                Deploy contracts
  etherscan-verify      submit contract source code to etherscan
  export                export contract deployment of the specified network into one file
  export-artifacts
  flatten               Flattens and prints contracts and their dependencies
  help                  Prints this message
  node                  Starts a JSON-RPC server on top of Hardhat EVM
  run                   Runs a user-defined script after compiling the project
  sourcify              submit contract source code to sourcify (https://sourcify.dev)
  test                  Runs mocha tests

To get help for a specific task run: npx hardhat help [task]
```

For more information see the [Hardhat documentation](https://hardhat.org/getting-started/).

## Configuration

The following variables can be specified as environment variables or in the `.env` configuration file.

### `PRIVATE_KEY`

The private key of the signer.

### `MNEMONIC`

A Secret Recovery Phrase, mnemonic phrase, or Seed Phrase used to generate the signers.
