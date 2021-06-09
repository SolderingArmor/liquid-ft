pragma ton-solidity >= 0.44.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../interfaces/ILiquidFTRoot.sol";
import "../interfaces/IOwnable.sol";
import "../contracts/LiquidFTWallet.sol";

//================================================================================
//
contract LiquidFTRoot is IOwnable, ILiquidFTRoot
{
    //========================================
    // Variables
    TvmCell   static _walletCode; //
    TokenInfo static _rootInfo;   //
    bytes            _icon;       // utf8-string with encoded PNG image. The string format is "data:image/png;base64,<image>", where image - image bytes encoded in base64.
                                  // _icon = "data:image/png;base64,iVBORw0KG...5CYII=";

    //========================================
    // Modifiers

    //========================================
    // Getters
    function  getWalletCode()                        external view             override         returns (TvmCell)         {                                                        return                      (_walletCode);       }
    function callWalletCode()                        external view responsible override reserve returns (TvmCell)         {                                                        return {value: 0, flag: 128}(_walletCode);       }
    function  getRootInfo()                          external view             override         returns (TokenInfo, bytes){                                                        return                      (_rootInfo, _icon);  }
    function callRootInfo()                          external view responsible override reserve returns (TokenInfo, bytes){                                                        return {value: 0, flag: 128}(_rootInfo, _icon);  }
    function  getWalletAddress(address ownerAddress) external view             override         returns (address)         {    (address addr, ) = _getWalletInit(ownerAddress);    return                      (addr);              }
    function callWalletAddress(address ownerAddress) external view responsible override reserve returns (address)         {    (address addr, ) = _getWalletInit(ownerAddress);    return {value: 0, flag: 128}(addr);              }

    //========================================
    //
    constructor(bytes icon) public
    {
        tvm.accept();
        _icon = icon;
    }

    //========================================
    //
    function _getWalletInit(address ownerAddress) private inline view returns (address, TvmCell)
    {
        TvmCell stateInit = tvm.buildStateInit({
            contr: LiquidFTWallet,
            varInit: {
                _rootAddress:  address(this),
                _ownerAddress: ownerAddress
            },
            code: _walletCode
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }

    //========================================
    //
    function createWallet(address ownerAddress) external override reserve
    {
        (, TvmCell stateInit) = _getWalletInit(ownerAddress);
        address walletAddress = new LiquidFTWallet{value: 0, flag: 128, stateInit: stateInit}(msg.sender);

        // Event
        emit walletCreated(ownerAddress, walletAddress);
    }

    //========================================
    //
    function burn(uint128 amount, address senderOwnerAddress, address initiatorAddress) external override reserve
    {
        (address walletAddress, ) = _getWalletInit(senderOwnerAddress);
        require(walletAddress == msg.sender, 9999);

        _rootInfo.balance -= amount;

        // Event
        emit tokensBurned(amount, senderOwnerAddress);

        // Return the change
        initiatorAddress.transfer(0, true, 128);
    }

    //========================================
    //
    function mint(uint128 amount, address targetOwnerAddress, address notifyAddress, TvmCell body) external override onlyOwner reserve
    {
        (address walletAddress, ) = _getWalletInit(targetOwnerAddress);

        // Mint adds balance to root total supply
        _rootInfo.balance += amount;
        ILiquidFTWallet(walletAddress).receiveTransfer{value: 0, flag: 128}(amount, addressZero, _ownerAddress, notifyAddress, body);
        
        // Event
        emit tokensMinted(amount, targetOwnerAddress);
    }

    //========================================
    //
    onBounce(TvmSlice slice) external 
    {
		uint32 functionId = slice.decode(uint32);
		if (functionId == tvm.functionId(LiquidFTWallet.receiveTransfer)) 
        {
			uint128 amount = slice.decode(uint128);
            _rootInfo.balance -= amount;

            // We know for sure that initiator in "mint" process is RTW owner;
            _ownerAddress.transfer(0, true, 128);
		}
	}
}

//================================================================================
//