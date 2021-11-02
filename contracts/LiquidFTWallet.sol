pragma ton-solidity >= 0.47.0;
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
    // Error codes
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER       = 100;
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_MY_ROOT        = 101;
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_WALLET_OR_ROOT = 102;
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_ALLOWED        = 103;
    uint constant ERROR_NOT_ENOUGH_BALANCE                   = 201;
    uint constant ERROR_CAN_NOT_TRANSFER_TO_YOURSELF         = 202;
    uint constant ERROR_ONLY_ROOT_CAN_MINT                   = 203;
    uint constant ERROR_RECEIVER_NOTIFY_DISABLED             = 204;
    uint constant ERROR_ALLOWANCE_EXPIRED                    = 205;
    uint constant ERROR_INSUFFICIENT_ALLOWANCE               = 206;

    //========================================
    // Variables
    address static _rootAddress;            //
    address static _ownerAddress;           //
    address        _notifyOnReceiveAddress; //
    uint128        _balance;                //

    mapping(address => AllowanceInfo) _allowances;

    //========================================
    // Modifiers
    function senderIsOwner()   internal view inline returns (bool) { return (msg.isInternal && msg.sender.isStdAddrWithoutAnyCast() && _ownerAddress == msg.sender && _ownerAddress != addressZero);    }
    function senderIsRoot()    internal view inline returns (bool) { return (msg.isInternal && msg.sender.isStdAddrWithoutAnyCast() && _rootAddress  == msg.sender && _rootAddress  != addressZero);    }
    function senderIsAllowed() internal view inline returns (bool) { return (msg.isInternal && _allowances.exists(msg.sender)) || senderIsOwner();    }
    modifier onlyOwner   {    require(senderIsOwner(), ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER);    _;    }
    modifier onlyRoot    {    require(senderIsRoot(),  ERROR_MESSAGE_SENDER_IS_NOT_MY_ROOT);     _;    }
    modifier onlyAllowed {    require(senderIsOwner(), ERROR_MESSAGE_SENDER_IS_NOT_ALLOWED);     _;    }

    //========================================
    // Getters
    function  getWalletCode()                  external view override                     returns (TvmCell                          ) {    return                      (tvm.code());               }
    function callWalletCode()                  external view override responsible reserve returns (TvmCell                          ) {    return {value: 0, flag: 128}(tvm.code());               }
    function  getOwnerAddress()                external view override                     returns (address                          ) {    return                      (_ownerAddress);            }
    function callOwnerAddress()                external view override responsible reserve returns (address                          ) {    return {value: 0, flag: 128}(_ownerAddress);            }
    function  getRootAddress()                 external view override                     returns (address                          ) {    return                      (_rootAddress);             }
    function callRootAddress()                 external view override responsible reserve returns (address                          ) {    return {value: 0, flag: 128}(_rootAddress);             }
    function  getBalance()                     external view override                     returns (uint128                          ) {    return                      (_balance);                 }
    function callBalance()                     external view override responsible reserve returns (uint128                          ) {    return {value: 0, flag: 128}(_balance);                 }
    function  getNotifyOnReceiveAddress()      external view override                     returns (address                          ) {    return                      (_notifyOnReceiveAddress);  }
    function callNotifyOnReceiveAddress()      external view override responsible reserve returns (address                          ) {    return {value: 0, flag: 128}(_notifyOnReceiveAddress);  }
    function  getAllowanceList()               external view override                     returns (mapping(address => AllowanceInfo)) {    return                      (_allowances);              }
    function callAllowanceList()               external view override responsible reserve returns (mapping(address => AllowanceInfo)) {    return {value: 0, flag: 128}(_allowances);              }
    function  getAllowanceSingle(address addr) external view override                     returns (AllowanceInfo                    ) {    return                      (_allowances[addr]);        }
    function callAllowanceSingle(address addr) external view override responsible reserve returns (AllowanceInfo                    ) {    return {value: 0, flag: 128}(_allowances[addr]);        }

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
    constructor(address senderOwnerAddress, address initiatorAddress, address notifyOnReceiveAddress, uint128 tokensAmount) public
    {
        (address walletAddress, ) = calculateFutureWalletAddress(senderOwnerAddress);
        require(walletAddress == msg.sender || _rootAddress == msg.sender, ERROR_MESSAGE_SENDER_IS_NOT_WALLET_OR_ROOT);
        if(_rootAddress != msg.sender)
        {
            require(tokensAmount == 0, ERROR_ONLY_ROOT_CAN_MINT);
        }

        _reserve();
        _balance                = tokensAmount;
        _notifyOnReceiveAddress = notifyOnReceiveAddress;

        initiatorAddress.transfer(0, true, 128);
    }

    //========================================
    //
    function burn(uint128 amount) public override onlyOwner reserve
    {
        require(_balance >= amount, ERROR_NOT_ENOUGH_BALANCE);
        _balance -= amount;

        // Event
        emit tokensBurned(amount);

        // Change will be returned by root
        ILiquidFTRoot(_rootAddress).burn{value: 0, flag: 128}(amount, _ownerAddress, msg.sender);
    }

    //========================================
    //
    function transfer(uint128 amount, address targetOwnerAddress, address initiatorAddress, address notifyAddress, bool allowReceiverNotify, TvmCell body) public override onlyAllowed reserve
    {
        require(_balance >= amount,                  ERROR_NOT_ENOUGH_BALANCE);
        require(targetOwnerAddress != _ownerAddress, ERROR_CAN_NOT_TRANSFER_TO_YOURSELF);

        // Check allowance
        bool isAllowance = !senderIsOwner();
        if(isAllowance)
        {
            require(_allowances[msg.sender].allowanceUntil == 0 || 
                    _allowances[msg.sender].allowanceUntil >= now,     ERROR_ALLOWANCE_EXPIRED     );
            require(_allowances[msg.sender].allowanceAmount >= amount, ERROR_INSUFFICIENT_ALLOWANCE);
        }

        // Event
        emit tokensSent(amount, targetOwnerAddress, body);

        // Target wallet initialization
        (address walletAddress, TvmCell stateInit) = calculateFutureWalletAddress(targetOwnerAddress);
        new LiquidFTWallet{value: msg.value / 2, flag: 0, bounce: false, stateInit: stateInit, wid: address(this).wid}(_ownerAddress, msg.sender, addressZero, 0);

        // Token transfer
        _balance -= amount;
        LiquidFTWallet(walletAddress).receiveTransfer{value: 0, flag: 128}(amount, _ownerAddress, initiatorAddress, notifyAddress, allowReceiverNotify, body);

        // Cleanup allowance if needed
        if(isAllowance)
        {
            if(_allowances[msg.sender].allowanceAmount == amount)
            {
                delete _allowances[msg.sender];
            }
            else
            {
                _allowances[msg.sender].allowanceAmount -= amount;
            }
        }
    }

    //========================================
    //
    function receiveTransfer(uint128 amount, address senderOwnerAddress, address initiatorAddress, address notifyAddress, bool allowReceiverNotify, TvmCell body) public override
    {
        (address walletAddress, ) = calculateFutureWalletAddress(senderOwnerAddress);
        require(msg.isInternal && (walletAddress == msg.sender || _rootAddress == msg.sender), ERROR_MESSAGE_SENDER_IS_NOT_WALLET_OR_ROOT);

        // If receiver wants a notify, sender must approve it
        require(_notifyOnReceiveAddress == addressZero || allowReceiverNotify, ERROR_RECEIVER_NOTIFY_DISABLED);

        _balance += amount;

        // Event
        emit tokensReceived(amount, senderOwnerAddress, body);

        // Notify sender and receiver (if required)
        if(notifyAddress != addressZero)
        {
            iFTNotify(notifyAddress).receiveNotification{value: msg.value / 3, flag: 0}(amount, senderOwnerAddress, initiatorAddress, body);
        }
        if(_notifyOnReceiveAddress != addressZero)
        {
            iFTNotify(_notifyOnReceiveAddress).receiveNotification{value: msg.value / 3, flag: 0}(amount, senderOwnerAddress, initiatorAddress, body);
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
    function setAllowance(address targetAddress, uint128 amount, uint32 until) external override onlyOwner reserve returnChange
    {
        if(amount == 0)
        {
            delete _allowances[targetAddress];
        }
        else
        {
            AllowanceInfo info;
            info.allowanceAmount = amount;
            info.allowanceUntil  = until;

            _allowances[targetAddress] = info;
        }
    }

    //========================================
    //
    function clearAllowance() external override onlyOwner reserve returnChange
    {
        delete _allowances;
    }

    //========================================
    //
    onBounce(TvmSlice slice) external 
    {
        uint32 functionId = slice.decode(uint32);
        if (functionId == tvm.functionId(receiveTransfer) || functionId == tvm.functionId(burn)) 
        {
            uint128 amount = slice.decode(uint128);
            _balance += amount;

            _ownerAddress.transfer(0, true, 128);
        }
    }
}

//================================================================================
//