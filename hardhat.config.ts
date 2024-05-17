import 'dotenv/config';
import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-foundry';
import { HardhatUserConfig } from 'hardhat/config';
import chalk from 'chalk';
import console from 'console';
import process from 'process';

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.24',
        settings: {
          optimizer: {
            enabled: true,
            runs: 10000
          }
        }
      }
    ]
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './build/cache',
    artifacts: './build/artifacts'
  },
  gasReporter: {
    enabled: true,
    outputFile: './test/gas-report.txt',
    noColors: true
  },
  networks: {
    localhost: {
      chainId: 31337,
      url: 'http://localhost:8545'
    },
    sepolia: {
      url: 'https://ethereum-sepolia-rpc.publicnode.com',
      chainId: 11155111,
      accounts: getSepoliaPrivateKeys()
    }
  }
};

function getSepoliaPrivateKeys(): string[] {
  const sepoliaPrivateKeysEnv = process.env.SEPOLIA_PRIVATE_KEYS;
  if (sepoliaPrivateKeysEnv === undefined) {
    console.log(chalk.red('Env variable SEPOLIA_PRIVATE_KEY is not set'));
    process.exit();
  }
  const sepoliaPrivateKeys = sepoliaPrivateKeysEnv.split(',');
  return sepoliaPrivateKeys;
}

export default config;
