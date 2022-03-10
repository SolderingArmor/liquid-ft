pragma ton-solidity >= 0.52.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../contracts/LiquidRootBase.sol";

//================================================================================
//
contract LiquidRoot is LiquidRootBase
{
    //========================================
    //
    constructor(address ownerAddress) public
    {
        tvm.accept();
        _totalSupply           = 0;
        _ownerAddress          = ownerAddress;
        _amountForWalletDeploy = 0.1 ton;
    }
}

//================================================================================
//