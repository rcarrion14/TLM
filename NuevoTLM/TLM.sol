// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "/contracts/TLMbase.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "/contracts/Vaulteable.sol";

contract TLM is Ownable, Vaulteable, TLMbase {
    
    bool minter = true;
    
    constructor (string memory name_, string memory symbol_ ) TLMbase(name_, symbol_) {}
    
    
    function mint(address account, uint256 amount) external onlyOwner {  //solo mintea el dueño una vez cuando se arranca el proceso
        require (minter == true, "TLM: TLM already minted" );
        _mint(account, amount);
        minter = false ;
    }
    
    function burn(address account, uint256 amount) external virtual onlyVault{ 
        _burn(account, amount);
    }
}