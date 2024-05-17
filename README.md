# hardhat-foundry-starter-kit

This is an up-to-date template repository while working with hardhat (typescript based) and foundry.

## Recommended vscode extensions

* [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)
* [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)

There was a question during the workshop, how I made the brackets colorful. This is now built-in to VSCode directly and can be activated with the following setting `@id:editor.bracketPairColorization.enabled @id:editor.guides.bracketPairs`. For colorful indentation use [this extension](https://marketplace.visualstudio.com/items?itemName=oderwat.indent-rainbow).

Note: In order that ESLint and Prettier extension work as expected I also added the `.vscode` folder to the repo with the respective settings. It is still possible that something does not work as vscode settings are sometimes tricky.

## How to start

1. Create `.env` file in the root of the repo with the following env variables:
    * `SEPOLIA_PRIVATE_KEYS` - need to be created freshly
    * `LOCALHOST_PRIVATE_KEYS` - can be obtained from local devnet (fired up with hardhat or foundry)

1. Install dependencies

    ```bash
    npm install
    ```

## How to add Foundry to a hardhat project

Before you start you need to [install foundry](https://book.getfoundry.sh/getting-started/installation).

**Note: Foundry/forge-std was already added as submodule to THIS repository. You do not need to execute one of the below commands. This was just added to showcase the possibilities you have when you work on a fresh repository/project.**

After installation you have two possibilities:

1. [Use hardhat-foundry for setup](https://hardhat.org/hardhat-runner/docs/advanced/hardhat-and-foundry#setting-up-a-hybrid-project)
1. Add foundry git submodule manually (resulting in a cleaner structure)

    ```bash
    git submodule add https://github.com/foundry-rs/forge-std foundry/lib/forge-std
    ```

    * create `foundry.toml` in the root of the repository(see [here for configuration settings](https://book.getfoundry.sh/reference/config/))
    * be sure to configure path settings (see `foundry.toml` in this repo)

## General commands

## Start local devnet

* with hardhat: `npx hardhat node`
* with foundry: `anvil`

## Basic hardhat commands

1. Compile contract

    ```bash
    npx hardhat compile
    ```

1. Test contract

    ```bash
    npx hardhat test

    # Test with coverage table
    npx hardhat coverage
    ```

1. Deploy contract to local testnet

    ```bash
    npx hardhat ignition deploy ignition/modules/* --network localhost
    ```

## Basic foundry commands

1. Compile contract

    ```bash
    forge build
    ```

1. Test contract

    ```bash
    # Test with gas-report output
    forge test --gas-report
    ```

1. Get coverage table

    ```bash
    forge coverage
    ```

1. Deploy contract to local testnet

    ```bash
    forge script ./foundry/script/Faucet.s.sol:FaucetDeploymentScript --rpc-url localhost --broadcast
    ```
