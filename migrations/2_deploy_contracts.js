const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const ClaimNFT = artifacts.require('ClaimNFT');
const AnWNFT = artifacts.require('AnWNFT');

module.exports = async function (deployer) {
  await deployProxy(AnWNFT, { deployer, initializer: 'initialize' });
  console.log('[Proxy AnWNFT]', (await AnWNFT.deployed()).address);

  await deployProxy(ClaimNFT, { deployer, initializer: 'initialize' });
  console.log('[Proxy ClaimNFT]', (await ClaimNFT.deployed()).address);
};
