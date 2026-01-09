// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthorizationManager {
    function verifyAuthorization(
        bytes32 authorizationId,
        address vault,
        address recipient,
        uint256 amount,
        uint256 chainId,
        bytes memory signature
    ) external returns (bool);
}

contract AuthorizationManager is IAuthorizationManager {
    mapping(bytes32 => bool) public usedAuthorizations;
    address public owner;
    
    event AuthorizationConsumed(bytes32 indexed authorizationId, address indexed recipient, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    function verifyAuthorization(
        bytes32 authorizationId,
        address vault,
        address recipient,
        uint256 amount,
        uint256 chainId,
        bytes memory signature
    ) external override returns (bool) {
        // Check if authorization has already been used
        require(!usedAuthorizations[authorizationId], "Authorization already consumed");
        
        // Reconstruct the message hash
        bytes32 messageHash = keccak256(abi.encodePacked(
            authorizationId,
            vault,
            recipient,
            amount,
            chainId
        ));
        
        // Create the signed message hash
        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        
        // Recover the signer
        address recoveredSigner = recoverSigner(signedMessageHash, signature);
        require(recoveredSigner == owner, "Invalid authorization signature");
        
        // Mark authorization as consumed
        usedAuthorizations[authorizationId] = true;
        
        emit AuthorizationConsumed(authorizationId, recipient, amount);
        return true;
    }
    
    function recoverSigner(bytes32 messageHash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        if (v < 27) {
            v += 27;
        }
        
        require(v == 27 || v == 28, "Invalid signature v value");
        return ecrecover(messageHash, v, r, s);
    }
    
    function hasAuthorizationBeenUsed(bytes32 authorizationId) external view returns (bool) {
        return usedAuthorizations[authorizationId];
    }
}
