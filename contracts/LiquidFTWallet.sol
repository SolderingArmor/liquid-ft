pragma ton-solidity >= 0.44.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../interfaces/IBase.sol";
import "../interfaces/ILiquidFTWallet.sol";

//================================================================================
//
contract LiquidFTWallet is IBase, ILiquidFTWallet
{
    //========================================
    // Constants

    //========================================
    // Variables
    address    static _rootAddress;  //
    address    static _ownerAddress; //
    TokenInfo         _walletInfo;   //
    address           _notifyOnReceiveAddress;

    //========================================
    // Modifiers
    function senderIsOwner() internal view inline returns (bool) { return (msg.sender.isStdAddrWithoutAnyCast() && _ownerAddress == msg.sender && _ownerAddress != addressZero);    }
    function senderIsRoot()  internal view inline returns (bool) { return (msg.sender.isStdAddrWithoutAnyCast() && _rootAddress  == msg.sender && _rootAddress  != addressZero);    }
    modifier onlyOwner {    require(senderIsOwner(), 100);    _;    }
    modifier onlyRoot  {    require(senderIsRoot(),  100);    _;    }

    //========================================
    // Getters
    function  getWalletCode() external view override                     returns (TvmCell)  {    return                      (tvm.code());    }
    function callWalletCode() external view override responsible reserve returns (TvmCell)  {    return {value: 0, flag: 128}(tvm.code());    }
    function  getWalletInfo() external view override                     returns (TokenInfo){    return                      (_walletInfo);   }
    function callWalletInfo() external view override responsible reserve returns (TokenInfo){    return {value: 0, flag: 128}(_walletInfo);   }

    //========================================
    //
    function calculateFutureWalletAddress(address ownerAddress) private inline view returns (address, TvmCell)
    {
        TvmCell stateInit = tvm.buildStateInit({
            contr: LiquidFTWallet,
            varInit: {
                _rootAddress:  _rootAddress,
                _ownerAddress: ownerAddress
            },
            code: tvm.code()
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }

    //========================================
    //
    constructor(address initiatorAddress) public onlyRoot
    {
        _reserve();
        tvm.accept();

        _notifyOnReceiveAddress = addressZero;

        initiatorAddress.transfer(0, true, 128);
    }

    //========================================
    //
    function burn(uint128 amount) public override onlyOwner reserve
    {
        require(_walletInfo.balance >= amount, 9999);
        _walletInfo.balance -= amount;

        // Event
        emit tokensBurned(amount);

        // Change will be returned by root
        ILiquidFTRoot(_rootAddress).burn(amount, _ownerAddress, msg.sender);
    }

    //========================================
    //
    function transfer(uint128 amount, address targetOwnerAddress, address initiatorAddress, address notifyAddress, TvmCell body) public override onlyOwner reserve
    {
        require(_walletInfo.balance >= amount,       9999);
        require(targetOwnerAddress != _ownerAddress, 9999);

        // Event
        emit tokensSent(amount, targetOwnerAddress, body);

        (address walletAddress, ) = calculateFutureWalletAddress(targetOwnerAddress);

        _walletInfo.balance -= amount;
        LiquidFTWallet(walletAddress).receiveTransfer{value: 0, flag: 128}(amount, _ownerAddress, initiatorAddress, notifyAddress, body);
    }

    //========================================
    //
    function receiveTransfer(uint128 amount, address senderOwnerAddress, address initiatorAddress, address notifyAddress, TvmCell body) public override
    {
        (address walletAddress, ) = calculateFutureWalletAddress(senderOwnerAddress);
        require(walletAddress == msg.sender || _rootAddress == msg.sender, 9999);

        _walletInfo.balance += amount;

        // Event
        emit tokensReceived(amount, senderOwnerAddress, body);

        // Notify sender and receiver (if required)
        if(notifyAddress != addressZero)
        {
            iFTNotify(notifyAddress).receiveNotification{value: msg.value / 3, flag: 0}(amount, _ownerAddress, initiatorAddress, body);
        }
        if(_notifyOnReceiveAddress != addressZero)
        {
            iFTNotify(_notifyOnReceiveAddress).receiveNotification{value: msg.value / 3, flag: 0}(amount, _ownerAddress, initiatorAddress, body);
        }

        // Return the change to initiator
        initiatorAddress.transfer(0, true, 128);
    }

    //========================================
    //
    function changeNotifyOnReceiveAddress(address newNotifyOnReceiveAddress) external override onlyOwner reserve returnChange
    {
        _notifyOnReceiveAddress = newNotifyOnReceiveAddress;
    }

    //========================================
    //
    onBounce(TvmSlice slice) external 
    {
        uint32 functionId = slice.decode(uint32);
        if (functionId == tvm.functionId(receiveTransfer) || functionId == tvm.functionId(burn)) 
        {
            uint128 amount = slice.decode(uint128);
            _walletInfo.balance += amount;

            _ownerAddress.transfer(0, true, 128);
        }
    }
}

//================================================================================
//