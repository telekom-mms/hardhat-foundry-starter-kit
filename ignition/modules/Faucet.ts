import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const WITHDRAWABLE_VALUE = 100_000_000_000_000_000n;
const INITIAL_BALANCE = 10_000_000_000_000_000_000n;

const FaucetModule = buildModule('FaucetModule', (moduleBuilder) => {
  const initialOwner = moduleBuilder.getAccount(1);

  const faucetContract = moduleBuilder.contract('Faucet', [initialOwner, WITHDRAWABLE_VALUE], {
    value: INITIAL_BALANCE
  });

  return { faucetContract };
});

export default FaucetModule;
