pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "/contracts/TLM.sol";
import "/contracts/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract TIENDAVAULT is Context, Ownable {
    
    TLM tlm;
    ERC20 backingCoin;
    uint256 private rate; // TLM:BACKINGCOING
    uint256 ceros = 1000000000000000000;
    uint256 tlmWithOutBacking;
    uint256 tlmWithBacking;
    
    address private adminWallet;
    
    event backingCreated (uint256 cantidadRespaldo, uint256 cantidadEmitida);
    event backingWithdrawn (uint256 cantidadRetirada, uint256 cantidadQuemada);
    event profitPayed (uint256 cantidadPagada);
    

    constructor (address tlmAddress, address backingCoinAddress, uint256 setRate, address setAdminWallet) {
    
        tlm = TLM(tlmAddress);
        backingCoin = ERC20(backingCoinAddress);
        rate = setRate * ceros;
        adminWallet = setAdminWallet;
    }
    
    
    //VAULT

    function backingCreation(uint256 amount) public onlyOwner {
    
        backingCoin.transferFrom(msg.sender, address(this), amount);
        tlm.mint(msg.sender, amount * rate /ceros);
        tlmWithBacking = amount * rate /ceros;
        tlmWithOutBacking =0;
        
        emit backingCreated(amount, amount * rate);
    }
    // ADMIN DEPOSITS bBTC, AND THE VAULT EMITS TLM.
    // tlmWithBacking AND tlmWithOutBacking were created because after a swap the tlm are not burned, are kept in the vault
    // it was necessary to make this difference to keep the exchange rate unaltered


    function profitPayment(uint256 amount) public onlyOwner {
        
        backingCoin.transferFrom(msg.sender, address(this), amount);
        
        rate = tlmWithBacking *ceros / (tlmWithBacking *ceros/ rate + amount);
        
        emit profitPayed(amount);
    }

    //ADMIN MAKES A PROFIT PAYMENT
    //Deposits bBTC in the Vault. Now there are more bBTC, so the exchange rate lowers. Clients's TLM are worth more bBTC.


    function backingWithdraw(uint256 amount) public {  // cliente le da TLM, devuelve BTC
    
        require(tlm.balanceOf(msg.sender)>= amount, "Cliente no tiene suficiente TLM");
        
        if (msg.sender== adminWallet){
            
            backingCoin.transfer(msg.sender, ((amount *ceros/ rate)));
            tlm.transferFrom(msg.sender, address(this), amount);
            
            tlmWithBacking = tlmWithBacking - amount;
            tlmWithOutBacking = tlmWithOutBacking + amount;
            
            
        }
        
        else{
        
            backingCoin.transfer(msg.sender, (amount *ceros/ rate)*9950/10000);
            backingCoin.transfer(adminWallet, (amount *ceros/ rate)*50/10000);  //  la diferencia anterior se transifere al dueño
            tlm.transferFrom(msg.sender, address(this), amount);
            
            tlmWithBacking = tlmWithBacking - amount;
            tlmWithOutBacking = tlmWithOutBacking + amount;
        
        }
        
        emit backingWithdrawn(amount / rate, amount);
        
    }

    //CLIENT SWAPS ITS TLM FOR bBTC
    //if the one calling this function is the admin, the are no trasaction fees.

    // TIENDA
    
    
    function supplyTLM() public view returns(uint256){   // TLM available for buying
        
        return tlm.balanceOf(address(this));
        
    }
    
    function priceTLM() public view returns(uint256){   // amount of TLM for 1 BTC
        
        return rate;
        
    }
    
    function upForSale(uint256 amount) external onlyOwner{   //Admin puts the TLM up for sale
        tlm.transferFrom(msg.sender, address(this), amount);
        
    }
    
    function outOfSale(uint256 amount) external onlyOwner{    // admin puts tlm out of sale
        require (amount <= tlm.balanceOf(address(this)), "TIENDA: no hay tantos TLM a la venta");
        tlm.transfer(msg.sender, amount);
        
    } 
    
    function buy(uint256 amount) public {
        require((amount * rate *9950/10000)/ceros <= tlm.balanceOf(address(this)), "TIENDA: no hay tantos TLM a la venta");
        if (tlmWithOutBacking >0){
            if(amount * rate /ceros*9950/10000 <= tlmWithOutBacking){
                backingCoin.transferFrom(msg.sender, address(this), amount);
                tlmWithOutBacking = tlmWithOutBacking - amount * rate /ceros;
                tlmWithBacking = tlmWithBacking + amount * rate /ceros;
                
            }
            
            else{
                backingCoin.transferFrom(msg.sender, address(this), tlmWithOutBacking *ceros/ rate);
                backingCoin.transferFrom(msg.sender, adminWallet, amount - tlmWithOutBacking *ceros/ rate);
                tlmWithBacking = tlmWithBacking + tlmWithOutBacking;
                tlmWithOutBacking = 0;
            }
        }
            
        else {
            backingCoin.transferFrom(msg.sender, adminWallet, amount);
        }
            
        tlm.transfer(msg.sender, amount * rate /ceros*9950/10000);
            
    }

     // THE CLIENT PUTS THE AMOUNT OF bBTC IS WILLING TO SPEND.
     //The contracts sends the TLM and modifies the variables in order to keep the exchange rate unaltered.

    
    function withOutBacking() public view returns(uint256){
        return tlmWithOutBacking;
    }
    
    function withBacking() public view returns(uint256){
        return tlmWithBacking;
    }
        
}