// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "/contracts/TLM.sol";
import "/contracts/ERC20.sol";

contract TIENDAVAULT is Context {
    
    address signature1;
    address signature2;
    address signature3;
    
    mapping (address=>bool) signers;
    
    mapping (address=>bool) changeSigners1;
    mapping (address=>bool) changeSigners2;
    mapping (address=>bool) changeSigners3;
    
    uint256 counter;
    
    uint256 counterChangeSigners1;
    uint256 counterChangeSigners2;
    uint256 counterChangeSigners3;
    
    
    TLM immutable tlm;
    ERC20 immutable backingCoin;
    uint256 private rate; // TLM:BACKINGCOING
    uint256 constant ceros = 10**18;
    uint256 tlmWithOutBacking;
    uint256 tlmWithBacking;
    
    address immutable private adminWallet;
    
    event backingCreated (uint256 cantidadRespaldo, uint256 cantidadEmitida);
    event backingWithdrawn (uint256 cantidadRetirada, uint256 cantidadQuemada);
    event profitPayed (uint256 cantidadPagada);
    

    constructor (address tlmAddress, address backingCoinAddress, uint256 setRate, address setAdminWallet, address setSignature1, address setSignature2, address setSignature3) {
        
        
        require(address(0) != tlmAddress , "TIENDAVAULT: set tlm to the zero address");
        require(address(0) != backingCoinAddress , "TIENDAVAULT: set backingCoin to the zero address");
        require(setRate > 0, "TIENDAVAULT: set rate to be zero");
        require(address(0) != setAdminWallet , "TIENDAVAULT: set adminWallet to the zero address");
        
        tlm = TLM(tlmAddress);
        backingCoin = ERC20(backingCoinAddress);
        rate = setRate * ceros;
        adminWallet = setAdminWallet;
        
        signature1 = setSignature1;
        signature2 = setSignature2;
        signature3 = setSignature3;
        
        counter = 0;
    
        counterChangeSigners1=0;
        counterChangeSigners2=0;
        counterChangeSigners3=0;
        
    }    
    
    //VAULT

    function profitPayment(uint256 amount) public {
        require( tlm.totalSupply() > tlm.balanceOf(address(this)), "No hay TLM en circulacion");
        backingCoin.transferFrom(msg.sender, address(this), amount);
        
        rate = (tlm.totalSupply()-tlm.balanceOf(address(this)))*ceros/backingCoin.balanceOf(address(this));
        emit profitPayed(amount);
    }

    //ADMIN MAKES A PROFIT PAYMENT
    //Deposits bBTC in the Vault. Now there are more bBTC, so the exchange rate lowers. Clients's TLM are worth more bBTC.


    function backingWithdraw(uint256 amount) public {  // cliente le da TLM, devuelve bBTC
        require(tlm.balanceOf(msg.sender)>= amount, "Cliente no tiene suficiente TLM");
	    require(backingCoin.balanceOf(address(this)) >= amount * ceros / rate, "Vault no tiene suficiente bBTC");

        tlm.transferFrom(msg.sender, address(this), amount);

        backingCoin.transfer(msg.sender, (amount *ceros/ rate)*9950/10000);
        backingCoin.transfer(adminWallet, (amount *ceros/ rate)*50/10000);  //  la diferencia anterior se transifere al admin
                
        emit backingWithdrawn(amount / rate, amount);        
    }

    //CLIENT SWAPS ITS TLM FOR bBTC

    // TIENDA
    
    
    function supplyTLM() public view returns(uint256){   // TLM available for buying        
        return tlm.balanceOf(address(this));        
    }
    
    function priceTLM() public view returns(uint256){   // amount of TLM for 1 BTC        
        return rate;        
    }

/*    
    function upForSale(uint256 amount) external{   //Admin puts the TLM up for sale     // HABRIA QUE SACARLA? lo mismo a sacar
        require (msg.sender==signature1, "msg sender is not the owner");
        
        tlm.transferFrom(msg.sender, address(this), amount);        
    }
*/   

/*    
    function outOfSale(uint256 amount) external {    // admin puts tlm out of sale
        require (amount <= tlm.balanceOf(address(this)), "TIENDA: no hay tantos TLM a la venta");
        require (msg.sender == signature1 || msg.sender == signature2 || msg.sender == signature3, "Billetera no valida");
        
        if (signers[msg.sender]==false){
            counter= counter+1;
        }
            
        signers[msg.sender] = true;
            
        if (counter >1){
            counter = 0;
            signers[signature1]=false;
            signers[signature2]=false;
            signers[signature3]=false;
                
            tlm.transfer(msg.sender, amount);
                
        }
    }
*/

    function cleanSignatures () internal {
        counter=0;
                
        counterChangeSigners1 = 0;
        counterChangeSigners2 = 0;
        counterChangeSigners3 = 0;
                
        changeSigners1[signature1] = false;
        changeSigners1[signature2] = false;
        changeSigners1[signature3] = false;
                
        changeSigners2[signature1] = false;
        changeSigners2[signature2] = false;
        changeSigners2[signature3] = false;
                
        changeSigners3[signature1] = false;
        changeSigners3[signature2] = false;
        changeSigners3[signature3] = false;
        
        
    }
    
    function changeSigner1(address newSigner) external {
        
        require(msg.sender == signature2 || msg.sender == signature3, "Billetera no valida");
        
        if (changeSigners1[msg.sender]==false){
            counterChangeSigners1= counterChangeSigners1 + 1;
        }
            
        changeSigners1[msg.sender] = true;
            
        if (counterChangeSigners1 >1){
                
            cleanSignatures();
            signature1=newSigner;
                
        }
        
    }
    
    function changeSigner2(address newSigner) external {
        
        require(msg.sender == signature1 || msg.sender == signature3, "Billetera no valida");
        
        if (changeSigners2[msg.sender]==false){
            counterChangeSigners2= counterChangeSigners2 + 1;
        }
            
        changeSigners2[msg.sender] = true;
            
        if (counterChangeSigners2 >1){
                
            cleanSignatures();
            signature2=newSigner;
                
        }
        
    }
    
    function changeSigner3(address newSigner) external {
        
        require(msg.sender == signature1 || msg.sender == signature2, "Billetera no valida");
        
        if (changeSigners3[msg.sender]==false){
            counterChangeSigners3= counterChangeSigners3 + 1;
        }
            
        changeSigners3[msg.sender] = true;
            
        if (counterChangeSigners3 >1){
                
            cleanSignatures();
            signature3=newSigner;                
        }        
    }            
    
    function buy(uint256 amount) public {
        require((amount * rate *9950/10000)/ceros <= tlm.balanceOf(address(this)), "TIENDA: no hay tantos TLM a la venta");        

        backingCoin.transferFrom(msg.sender, address(this), amount*9950/10000);
        backingCoin.transferFrom(msg.sender, adminWallet, amount*50/10000);

        tlm.transfer(msg.sender, amount * rate /ceros*9950/10000);
    }

     // THE CLIENT PUTS THE AMOUNT OF bBTC IS WILLING TO SPEND.
     //The contracts sends the TLM and modifies the variables in order to keep the exchange rate unaltered.

 /*
    function withOutBacking() public view returns(uint256){
        return tlmWithOutBacking;
    }

    function withBacking() public view returns(uint256){
        return tlmWithBacking;
    } 
*/

}