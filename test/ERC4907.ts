import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('ERC4907', function () {
  async function deployOneYearLockFixture() {
    const [owner, otherAccount] = await ethers.getSigners();

    const ERC4907 = await ethers.getContractFactory('ERC4907');
    const contract = await ERC4907.deploy('My Awesome Token', 'MAT');

    return { contract, owner, otherAccount };
  }

  describe('Deployment', function () {
    it('Check symbol', async function () {
      const { contract } = await loadFixture(deployOneYearLockFixture);

      expect(await contract.symbol()).to.equal('MAT');
    });

    it('Check minted tokens', async function () {
      const { contract, owner } = await loadFixture(deployOneYearLockFixture);

      expect(await contract.ownerOf(1)).to.equal(owner.address);
      expect(await contract.ownerOf(10)).to.equal(owner.address);
    });
  });

  describe('Renting', function () {
    it('Try to rent without owner', async function () {
      const { contract, otherAccount } = await loadFixture(
        deployOneYearLockFixture
      );

      await expect(
        contract
          .connect(otherAccount)
          .setUser(1, otherAccount.address, (await time.latest()) + 10)
      ).to.be.revertedWithCustomError(contract, 'OnlyOwnerCanSetUser');
    });

    it('Rent and check', async function () {
      const { contract, otherAccount } = await loadFixture(
        deployOneYearLockFixture
      );

      await contract.setUser(
        1,
        otherAccount.address,
        (await time.latest()) + 10
      );
      expect(await contract.userOf(1)).to.equal(otherAccount.address);
    });

    it('Rent and expire', async function () {
      const { contract, otherAccount } = await loadFixture(
        deployOneYearLockFixture
      );

      await contract.setUser(
        1,
        otherAccount.address,
        (await time.latest()) + 10
      );
      expect(await contract.userOf(1)).to.equal(otherAccount.address);

      await time.increase(11);

      expect(await contract.userOf(1)).to.equal(ethers.constants.AddressZero);
    });
  });
});
