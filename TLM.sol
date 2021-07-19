// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "/contracts/TLMbase.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "/contracts/Vaulteable.sol";

contract TLM is Ownable, Vaulteable, TLMbase {
    
    
    constructor (string memory name_, string memory symbol_ ) TLMbase(name_, symbol_) {}
    
    
    function mint(address account, uint256 amount) external onlyVault {
        _mint(account, amount);
        
    }
    
    function burn(address account, uint256 amount) external virtual onlyVault{
        _burn(account, amount);
    }

}