pragma ton-solidity >= 0.44.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../contracts/LiquidFTRootBase.sol";

//================================================================================
//
contract LiquidFTRoot is LiquidFTRootBase
{
    //========================================
    //
    constructor(address ownerAddress) public
    {
        tvm.accept();
        _totalSupply  = 0;
        _ownerAddress = ownerAddress;
    }
}

//================================================================================
//