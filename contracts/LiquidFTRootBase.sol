pragma ton-solidity >= 0.52.0;
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
abstract contract LiquidFTRootBase is IOwnable, ILiquidFTRoot
{
    //========================================
    // Error codes
    uint constant ERROR_WALLET_ADDRESS_INVALID = 301;

    //========================================
    // Variables
    TvmCell static _walletCode;  //
    string  static _name;        //
    string  static _symbol;      //
    uint8   static _decimals;    //
    uint128        _totalSupply; //
    string         _metadata;    //

    //========================================
    // Modifiers

    //========================================
    // Getters
    function  getWalletCode()                        external view             override         returns (TvmCell)         {                                                        return                      (_walletCode);       }
    function callWalletCode()                        external view responsible override reserve returns (TvmCell)         {                                                        return {value: 0, flag: 128}(_walletCode);       }
    function  getWalletAddress(address ownerAddress) external view             override         returns (address)         {    (address addr, ) = _getWalletInit(ownerAddress);    return                      (addr);              }
    function callWalletAddress(address ownerAddress) external view responsible override reserve returns (address)         {    (address addr, ) = _getWalletInit(ownerAddress);    return {value: 0, flag: 128}(addr);              }

    function getInfo(bool includeMetadata) external view override returns (string  name, 
                                                                           string  symbol, 
                                                                           uint8   decimals, 
                                                                           uint128 totalSupply, 
                                                                           string  metadata)
    {
        return (_name, 
                _symbol, 
                _decimals, 
                _totalSupply, 
                includeMetadata ? _metadata : metadata);  
    }
    function callInfo(bool includeMetadata) external view responsible override reserve returns (string  name, 
                                                                                                string  symbol, 
                                                                                                uint8   decimals, 
                                                                                                uint128 totalSupply, 
                                                                                                string  metadata)
    {
        return {value: 0, flag: 128}(_name, 
                                     _symbol, 
                                     _decimals, 
                                     _totalSupply, 
                                     includeMetadata ? _metadata : metadata);
    }

    //========================================
    //
    function setMetadata(string metadata) external onlyOwner reserve returnChange
    {
        _metadata = metadata;
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
    function _createWallet(address ownerAddress, address notifyOnReceiveAddress, uint128 tokensAmount, uint128 value, uint16 flag, bool emitCreateWallet) internal returns (address)
    {
        if(tokensAmount > 0)
        {
            require(senderIsOwner(), ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER);
            _totalSupply += tokensAmount;
        }
        
        (address walletAddress, TvmCell stateInit) = _getWalletInit(ownerAddress);
        if(emitCreateWallet)
        {
            // Event
            emit walletCreated(ownerAddress, walletAddress);
        }

        new LiquidFTWallet{value: value, flag: flag, bounce: false, stateInit: stateInit, wid: address(this).wid}(addressZero, msg.sender, notifyOnReceiveAddress, tokensAmount);

        return walletAddress;
    }

    //========================================
    // No returnChange here because 0 (flag 128) TONs are sent to the new wallet
    // 
    function createWallet(address ownerAddress, address notifyOnReceiveAddress, uint128 tokensAmount) external override reserve returns (address)
    {
        address walletAddress = _createWallet(ownerAddress, notifyOnReceiveAddress, tokensAmount, 0, 128, true);
        return(walletAddress);
    }

    function callCreateWallet(address ownerAddress, address notifyOnReceiveAddress, uint128 tokensAmount) external responsible override reserve returns (address)
    {
        address walletAddress = _createWallet(ownerAddress, notifyOnReceiveAddress, tokensAmount, msg.value / 2, 0, true);
        return{value: 0, flag: 128}(walletAddress);
    }

    //========================================
    //
    function burn(uint128 amount, address senderOwnerAddress, address initiatorAddress) external override reserve returnChangeTo(initiatorAddress)
    {
        (address walletAddress, ) = _getWalletInit(senderOwnerAddress);
        require(walletAddress == msg.sender, ERROR_WALLET_ADDRESS_INVALID);

        _totalSupply -= amount;

        // Event
        emit tokensBurned(amount, senderOwnerAddress);
    }

    //========================================
    //
    function mint(uint128 amount, address targetOwnerAddress, address notifyAddress, TvmCell body) external override onlyOwner reserve
    {
        address walletAddress = _createWallet(targetOwnerAddress, addressZero, 0, msg.value / 3, 0, false);
        // Event
        emit tokensMinted(amount, targetOwnerAddress, body);

        if(notifyAddress != addressZero)
        {
            iFTNotify(notifyAddress).receiveNotification{value: msg.value / 3, flag: 0}(amount, targetOwnerAddress, msg.sender, body);
        }

        // Mint adds balance to root total supply
        _totalSupply += amount;
        ILiquidFTWallet(walletAddress).receiveTransfer{value: 0, flag: 128}(amount, addressZero, _ownerAddress, notifyAddress, false, body);
    }

    //========================================
    //
    onBounce(TvmSlice slice) external
    {
        uint32 functionId = slice.decode(uint32);
        if (functionId == tvm.functionId(LiquidFTWallet.receiveTransfer)) 
        {
            uint128 amount = slice.decode(uint128);
            _totalSupply -= amount;

            // We know for sure that initiator in "mint" process is RTW owner;
            _ownerAddress.transfer(0, true, 128);
        }
    }
}

//================================================================================
//