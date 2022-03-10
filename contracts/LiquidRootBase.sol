pragma ton-solidity >= 0.52.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../interfaces/ILiquidRoot.sol";
import "../interfaces/IOwnable.sol";
import "../contracts/LiquidWallet.sol";

//================================================================================
//
abstract contract LiquidRootBase is IBase, ILiquidRoot, ILiquidBurn
{
    //========================================
    // Error codes
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER = 100;
    uint constant ERROR_WALLET_ADDRESS_INVALID         = 301;

    //========================================
    // Variables
    TvmCell static _walletCode;            //
    string  static _name;                  //
    string  static _symbol;                //
    uint8   static _decimals;              //
    address        _ownerAddress;          //
    uint128        _totalSupply;           //
    string         _metadata;              //
    address        _previousRoot;          // 
    uint128        _amountForWalletDeploy; // 

    //========================================
    // Modifiers
    function senderIsOwner() internal inline view returns (bool) {    return _checkSenderAddress(_ownerAddress);    }
    modifier onlyOwner{    require(senderIsOwner(),   ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER);    _;    }

    //========================================
    //
    function calculateFutureWalletAddress(address ownerAddress) private inline view returns (address, TvmCell)
    {
        TvmCell stateInit = tvm.buildStateInit({
            contr: LiquidWallet,
            varInit: {
                _rootAddress:  address(this),
                _ownerAddress: ownerAddress
            },
            code: _walletCode
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }

    //========================================
    // Getters
    function getWalletAddress(address ownerAddress) external view responsible override returns (address targetOwnerAddress, address walletAddress) 
    {
        (address addr, ) = calculateFutureWalletAddress(ownerAddress);
        return (ownerAddress, addr);
    }

    //
    function getInfo(bool includeMetadata, bool includeWalletCode) external view responsible override returns (
        string  name, 
        string  symbol, 
        uint8   decimals, 
        uint128 totalSupply, 
        string  metadata,
        TvmCell walletCode)
    {
        TvmCell emptyCell;
        return {value: 0, flag: 128}(
            _name, 
            _symbol, 
            _decimals, 
            _totalSupply, 
            includeMetadata   ? _metadata   : "{}",
            includeWalletCode ? _walletCode : emptyCell);  
    }

    //========================================
    // TODO: emit
    function setOwner(address ownerAddress) external onlyOwner reserve returnChange
    {
        _ownerAddress = ownerAddress;
    }

    //========================================
    //
    function setMetadata(string metadata) external onlyOwner reserve returnChange
    {
        _metadata = metadata;
    }

    //========================================
    //
    function setPreviousRoot(address previousRoot) external override onlyOwner reserve returnChange
    {
        _previousRoot = previousRoot;
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
        
        (address walletAddress, TvmCell stateInit) = calculateFutureWalletAddress(ownerAddress);
        if(emitCreateWallet)
        {
            // Event
            emit walletCreated(ownerAddress, walletAddress);
        }

        new LiquidWallet{value: value, flag: flag, bounce: false, stateInit: stateInit, wid: address(this).wid}(addressZero, msg.sender, notifyOnReceiveAddress, tokensAmount);

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

    //========================================
    // TODO
    function burn(uint128 amount, address senderOwnerAddress, address initiatorAddress, address notifyOnReceiveAddress) external override reserve
    {
        (address walletAddress, ) = calculateFutureWalletAddress(senderOwnerAddress);
        require(_checkSenderAddress(walletAddress), ERROR_WALLET_ADDRESS_INVALID);

        _totalSupply -= amount;

        // Event
        emit tokensBurned(amount, senderOwnerAddress);

        if(notifyOnReceiveAddress != addressZero)
        {
            ILiquidBurn(notifyOnReceiveAddress).receiveBurnFromRoot{value: 0, bounce: false, flag: 128}(amount, senderOwnerAddress, initiatorAddress);
        }
        else
        {
            initiatorAddress.transfer(0, false, 128);
        }
    }

    //========================================
    // TODO
    function receiveBurnFromRoot(uint128 amount, address senderOwnerAddress, address initiatorAddress) external override reserve
    {
        require(_checkSenderAddress(_previousRoot), 6666);

        address walletAddress = _createWallet(senderOwnerAddress, addressZero, 0, _amountForWalletDeploy, 0, false);

        // Event
        TvmCell emptyCell;
        emit tokensMinted(amount, senderOwnerAddress, emptyCell);
        
        // Mint adds balance to root total supply
        _totalSupply += amount;
        ILiquidWallet(walletAddress).receiveTransfer{value: 0, flag: 128}(amount, addressZero, initiatorAddress, addressZero, false, emptyCell);

    }

    //========================================
    //
    function mint(uint128 amount, address targetOwnerAddress, address notifyAddress, TvmCell body) external override onlyOwner reserve
    {
        address walletAddress = _createWallet(targetOwnerAddress, addressZero, 0, _amountForWalletDeploy, 0, false);
        // Event
        emit tokensMinted(amount, targetOwnerAddress, body);

        if(notifyAddress != addressZero)
        {
            ILiquidNotify(notifyAddress).receiveNotification{value: (msg.value - _amountForWalletDeploy) / 2, flag: 0}(amount, targetOwnerAddress, msg.sender, body);
        }

        // Mint adds balance to root total supply
        _totalSupply += amount;
        ILiquidWallet(walletAddress).receiveTransfer{value: 0, flag: 128}(amount, addressZero, _ownerAddress, notifyAddress, false, body);
    }

    //========================================
    //
    onBounce(TvmSlice slice) external
    {
        uint32 functionId = slice.decode(uint32);
        if (functionId == tvm.functionId(LiquidWallet.receiveTransfer)) 
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