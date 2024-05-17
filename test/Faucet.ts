import { loadFixture, time } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import hre from 'hardhat';

const INITIAL_WITHDRAWABLE_VALUE = 100_000_000_000_000_000n;
const INITIAL_BALANCE = 10_000_000_000_000_000_000n;

describe('Faucet', function () {
  async function deployFaucetFixture() {
    const withdrawableValue = INITIAL_WITHDRAWABLE_VALUE;
    const initialBalance = INITIAL_BALANCE;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const faucetContractFactory = await hre.ethers.getContractFactory('Faucet');
    const faucetContract = await faucetContractFactory.deploy(owner, withdrawableValue, {
      value: initialBalance
    });

    return { faucetContract, withdrawableValue, initialBalance, owner, otherAccount };
  }

  describe('Deployment', function () {
    it('Should set the correct withdrawable amount of Ether', async function () {
      const { faucetContract, withdrawableValue } = await loadFixture(deployFaucetFixture);
      expect(await faucetContract.withdrawableValue()).to.equal(withdrawableValue);
    });
    it('Should set the right owner', async function () {
      const { faucetContract, owner } = await loadFixture(deployFaucetFixture);
      expect(await faucetContract.owner()).to.equal(owner.address);
    });
    it('Should receive and store the faucet funds', async function () {
      const { faucetContract, initialBalance } = await loadFixture(deployFaucetFixture);
      expect(await hre.ethers.provider.getBalance(faucetContract.target)).to.equal(initialBalance);
    });
  });

  describe('Fund faucet', function () {
    describe('Functionality', function () {
      it('Should receive and store additional funds', async function () {
        const additionalFunds = 1_000_000_000_000_000_000n;
        const { faucetContract, initialBalance } = await loadFixture(deployFaucetFixture);
        await faucetContract.fundFaucet({ value: additionalFunds });
        const newBalance = initialBalance + additionalFunds;
        expect(await hre.ethers.provider.getBalance(faucetContract.target)).to.equal(newBalance);
      });
    });
    describe('Events', function () {
      it('Should emit an event while funding the faucet', async function () {
        const additionalFunds = 1_000_000_000_000_000_000n;
        const { faucetContract } = await loadFixture(deployFaucetFixture);
        await expect(faucetContract.fundFaucet({ value: additionalFunds }))
          .to.emit(faucetContract, 'FundFaucet')
          .withArgs(additionalFunds);
      });
    });
  });

  describe('Update withdrawable value', function () {
    describe('Functionality', function () {
      it('Should update the value which can be withdrawn by the caller', async function () {
        const newWithdrawableValue = 1n;
        const { faucetContract } = await loadFixture(deployFaucetFixture);
        await faucetContract.updateWithdrawableValue(newWithdrawableValue);
        expect(await faucetContract.withdrawableValue()).to.equal(newWithdrawableValue);
      });
    });
    describe('Events', function () {
      it('Should emit an event while updating the withdrawable value', async function () {
        const newWithdrawableValue = 1n;
        const { faucetContract } = await loadFixture(deployFaucetFixture);
        await expect(faucetContract.updateWithdrawableValue(newWithdrawableValue))
          .to.emit(faucetContract, 'UpdateWithdrawValue')
          .withArgs(newWithdrawableValue);
      });
    });
  });

  describe('Request Ether', function () {
    describe('Functionality', function () {
      it('Should send requested Ether to caller for first request', async function () {
        const { faucetContract, otherAccount } = await loadFixture(deployFaucetFixture);
        const accountBalanceBeforeRequest = await hre.ethers.provider.getBalance(
          otherAccount.address
        );
        const transaction = await faucetContract.connect(otherAccount).requestEther();
        expect(await hre.ethers.provider.getBalance(faucetContract.target)).to.equal(
          INITIAL_BALANCE - INITIAL_WITHDRAWABLE_VALUE
        );
        const trxReceipt = await transaction.wait();
        if (trxReceipt) {
          expect(await hre.ethers.provider.getBalance(otherAccount.address)).to.equal(
            accountBalanceBeforeRequest +
              INITIAL_WITHDRAWABLE_VALUE -
              trxReceipt.gasUsed * trxReceipt.gasPrice
          );
        }
      });
      it('Should send requested Ether to the caller for the second time after waiting period elapsed', async function () {
        const { faucetContract, otherAccount } = await loadFixture(deployFaucetFixture);
        const accountBalanceBeforeRequest = await hre.ethers.provider.getBalance(
          otherAccount.address
        );
        const transactionOne = await faucetContract.connect(otherAccount).requestEther();
        await time.increase((await time.latest()) + 70);
        const transactionTwo = await faucetContract.connect(otherAccount).requestEther();
        expect(await hre.ethers.provider.getBalance(faucetContract.target)).to.equal(
          INITIAL_BALANCE - 2n * INITIAL_WITHDRAWABLE_VALUE
        );
        const trxReceiptOne = await transactionOne.wait();
        const trxReceiptTwo = await transactionTwo.wait();
        if (trxReceiptOne && trxReceiptTwo) {
          const trxFeeOne = trxReceiptOne.gasUsed * trxReceiptOne.gasPrice;
          const trxFeeTwo = trxReceiptTwo.gasUsed * trxReceiptTwo.gasPrice;
          expect(await hre.ethers.provider.getBalance(otherAccount.address)).to.equal(
            accountBalanceBeforeRequest + 2n * INITIAL_WITHDRAWABLE_VALUE - trxFeeOne - trxFeeTwo
          );
        }
      });
    });
    describe('Events', function () {
      it('Should emit an event when the next request can be send', async function () {
        const secondsMinute = 60;
        const { faucetContract } = await loadFixture(deployFaucetFixture);
        const requestTransaction = await faucetContract.requestEther();
        const requestTrxReceipt = await requestTransaction.wait();
        if (requestTrxReceipt) {
          const block = await hre.ethers.provider.getBlock(requestTrxReceipt.blockNumber);
          if (block) {
            await expect(requestTransaction)
              .to.emit(faucetContract, 'NextPossibleRequest')
              .withArgs(block.timestamp + secondsMinute);
          }
        }
      });
    });
    describe('Errors', function () {
      it('Should fail to send a request when the contract balance is lower than the withdrawable amount', async function () {});
      it('Should fail to send a request when the waiting period is not over yet', async function () {});
      it('Should fail to send a request when the user does not have enough funds to pay for gas fees', async function () {
        const { faucetContract, otherAccount } = await loadFixture(deployFaucetFixture);
        await otherAccount.sendTransaction({
          to: '0x92d3267215Ec56542b985473E73C8417403B15ac',
          value: hre.ethers.parseUnits('9999.92', 'ether')
        });
        expect(await faucetContract.connect(otherAccount).requestEther())
          .to.be.revertedWithCustomError(faucetContract, 'TransferEther')
          .withArgs('Transfering Ether failed');
      });
    });
  });
});
