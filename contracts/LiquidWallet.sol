pragma ton-solidity >= 0.52.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../interfaces/IBase.sol";
import "../interfaces/ILiquidWallet.sol";

//================================================================================
//
contract LiquidWallet is IBase, ILiquidWallet
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
    uint128        _amountForWalletDeploy;  // 

    //========================================
    // Modifiers
    modifier onlyOwner{    require(_checkSenderAddress(_ownerAddress),   ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER);    _;    }
    modifier onlyRoot {    require(_checkSenderAddress(_rootAddress ),   ERROR_MESSAGE_SENDER_IS_NOT_MY_ROOT);     _;    }

    //========================================
    // Getters
    function getInfo(bool includeWalletCode) external view responsible override returns(
        TvmCell walletCode,
        address ownerAddress,
        address rootAddress,
        uint128 balance,
        address notifyOnReceiveAddress)
    {
        TvmCell emptyCell;
        return{value: 0, flag: 128}(
            includeWalletCode ? tvm.code() : emptyCell, 
            _ownerAddress, 
            _rootAddress, 
            _balance, 
            _notifyOnReceiveAddress);
    }
    //========================================
    //
    function calculateFutureWalletAddress(address ownerAddress) private inline view returns (address, TvmCell)
    {
        TvmCell stateInit = tvm.buildStateInit({
            contr: LiquidWallet,
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
    constructor(address senderOwnerAddress, address initiatorAddress, address notifyOnReceiveAddress, uint128 tokensAmount) public reserve returnChangeTo(initiatorAddress)
    {
        (address walletAddress, ) = calculateFutureWalletAddress(senderOwnerAddress);
        require(_checkSenderAddress(walletAddress) || _checkSenderAddress(_rootAddress), ERROR_MESSAGE_SENDER_IS_NOT_WALLET_OR_ROOT);
        if(_rootAddress != msg.sender)
        {
            require(tokensAmount == 0, ERROR_ONLY_ROOT_CAN_MINT);
        }
        
        _balance                = tokensAmount;
        _notifyOnReceiveAddress = notifyOnReceiveAddress;
        _amountForWalletDeploy  = 0.1 ton; // TODO
    }

    //========================================
    //
    function burn(uint128 amount, address notifyOnReceiveAddress) public override onlyOwner reserve
    {
        require(_balance >= amount, ERROR_NOT_ENOUGH_BALANCE);
        _balance -= amount;

        // Event
        emit tokensBurned(amount);

        // Change will be returned by root
        ILiquidRoot(_rootAddress).burn{value: 0, flag: 128}(amount, _ownerAddress, msg.sender, notifyOnReceiveAddress);
    }

    //========================================
    //
    function transfer(
        uint128 amount, 
        address targetOwnerAddress, 
        address initiatorAddress, 
        address notifyAddress, 
        bool    allowReceiverNotify, 
        TvmCell body) public override onlyOwner reserve
    {
        require(_balance >= amount,                  ERROR_NOT_ENOUGH_BALANCE          );
        require(targetOwnerAddress != _ownerAddress, ERROR_CAN_NOT_TRANSFER_TO_YOURSELF);

        // Event
        emit tokensSent(amount, targetOwnerAddress, initiatorAddress, notifyAddress, allowReceiverNotify, body);

        // Target wallet initialization
        (address walletAddress, TvmCell stateInit) = calculateFutureWalletAddress(targetOwnerAddress);
        new LiquidWallet{value: _amountForWalletDeploy, flag: 0, bounce: false, stateInit: stateInit, wid: address(this).wid}(_ownerAddress, msg.sender, addressZero, 0);

        // Token transfer
        _balance -= amount;
        LiquidWallet(walletAddress).receiveTransfer{value: 0, flag: 128}(amount, _ownerAddress, initiatorAddress, notifyAddress, allowReceiverNotify, body);
    }

    //========================================
    //
    function receiveTransfer(
        uint128 amount, 
        address senderOwnerAddress, 
        address initiatorAddress, 
        address notifyAddress, 
        bool    allowReceiverNotify, 
        TvmCell body) public override reserve returnChangeTo(initiatorAddress) 
    {
        (address walletAddress, ) = calculateFutureWalletAddress(senderOwnerAddress);
        require(_checkSenderAddress(walletAddress) || _checkSenderAddress(_rootAddress), ERROR_MESSAGE_SENDER_IS_NOT_WALLET_OR_ROOT);

        // If receiver wants a notify, sender must approve it
        require(_notifyOnReceiveAddress == addressZero || allowReceiverNotify, ERROR_RECEIVER_NOTIFY_DISABLED);

        _balance += amount;

        // Event
        emit tokensReceived(amount, senderOwnerAddress, initiatorAddress, notifyAddress, allowReceiverNotify, body);

        // Notify sender and receiver (if required)
        if(notifyAddress != addressZero)
        {
            ILiquidNotify(notifyAddress).receiveNotification{value: msg.value / 3, flag: 0}(amount, senderOwnerAddress, initiatorAddress, body);
        }
        if(_notifyOnReceiveAddress != addressZero)
        {
            ILiquidNotify(_notifyOnReceiveAddress).receiveNotification{value: msg.value / 3, flag: 0}(amount, senderOwnerAddress, initiatorAddress, body);
        }
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
            _balance += amount;

            _ownerAddress.transfer(0, true, 128);
        }
    }
}

//================================================================================
//