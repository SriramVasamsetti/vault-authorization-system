const ethers = require('ethers');
const fs = require('fs');
const path = require('path');

async function main() {
  const [deployer] = await ethers.getSigners();
  const chainId = (await ethers.provider.getNetwork()).chainId;
  
  console.log('Deploying contracts with account:', deployer.address);
  console.log('Network ID:', chainId);
  
  // Deploy AuthorizationManager
  const AuthManager = await ethers.getContractFactory('AuthorizationManager');
  const authManager = await AuthManager.deploy();
  await authManager.waitForDeployment();
  const authManagerAddr = await authManager.getAddress();
  console.log('AuthorizationManager deployed to:', authManagerAddr);
  
  // Deploy SecureVault
  const Vault = await ethers.getContractFactory('SecureVault');
  const vault = await Vault.deploy(authManagerAddr);
  await vault.waitForDeployment();
  const vaultAddr = await vault.getAddress();
  console.log('SecureVault deployed to:', vaultAddr);
  
  // Save deployment info
  const deployment = {
    authorizationManager: authManagerAddr,
    secureVault: vaultAddr,
    deployer: deployer.address,
    chainId: chainId,
    blockNumber: await ethers.provider.getBlockNumber(),
  };
  
  const deploymentPath = path.join(__dirname, '../deployment.json');
  fs.writeFileSync(deploymentPath, JSON.stringify(deployment, null, 2));
  console.log('Deployment info saved to:', deploymentPath);
}

main().catch(console.error);
