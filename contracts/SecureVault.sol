// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuthorizationManager.sol";

contract SecureVault {
    IAuthorizationManager public authorizationManager;
    uint256 public totalDeposits;
    
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount, bytes32 indexed authorizationId);
    event AuthorizationFailed(bytes32 indexed authorizationId, string reason);
    
    constructor(address _authorizationManager) {
        require(_authorizationManager != address(0), "Invalid authorization manager");
        authorizationManager = IAuthorizationManager(_authorizationManager);
    }
    
    // Allow deposits via receive function
    receive() external payable {
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // Fallback function to accept ETH
    fallback() external payable {
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // Withdraw with authorization verification
    function withdraw(
        bytes32 authorizationId,
        address recipient,
        uint256 amount,
        uint256 chainId,
        bytes memory signature
    ) external {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= address(this).balance, "Insufficient vault balance");
        
        // Verify authorization before updating state
        bool isAuthorized = authorizationManager.verifyAuthorization(
            authorizationId,
            address(this),
            recipient,
            amount,
            chainId,
            signature
        );
        
        require(isAuthorized, "Authorization failed");
        
        // Update internal accounting
        totalDeposits -= amount;
        
        // Transfer funds
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(recipient, amount, authorizationId);
    }
    
    // View function to check vault balance
    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Check if authorization has been used
    function isAuthorizationUsed(bytes32 authorizationId) external view returns (bool) {
        return authorizationManager.hasAuthorizationBeenUsed(authorizationId);
    }
}
