const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const AnWNFT = artifacts.require('AnWNFT');
const ClaimNFT = artifacts.require('ClaimNFT');

module.exports = async function (deployer) {
  const proxyAnWNFT = '0x59CDF6c7824A86Cb0a00701F41AcA2EaD717d1a8';
  await upgradeProxy(proxyAnWNFT, AnWNFT, {
    deployer,
    unsafeAllowCustomTypes: true,
  });

  const proxyClaimNFT = '0x07E45e2D451cD4b97077B83f11D5D557200B9b80';
  await upgradeProxy(proxyClaimNFT, ClaimNFT, {
    deployer,
    unsafeAllowCustomTypes: true,
  });
};
