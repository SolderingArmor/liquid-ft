pragma ton-solidity >= 0.52.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../interfaces/ILiquidFTRoot.sol";

//================================================================================
//
interface iFTNotify
{
    function receiveNotification(uint128 amount, address senderOwnerAddress, address initiatorAddress, TvmCell body) external;
}

//================================================================================
//
struct AllowanceInfo
{
    uint128 allowanceAmount; //
    uint32  allowanceUntil;  // endless when 0;
}

//================================================================================
//
interface ILiquidFTWallet
{
    //========================================
    // Events
    event tokensBurned  (uint128 amount);
    event tokensSent    (uint128 amount, address targetOwnerAddress, TvmCell body);
    event tokensReceived(uint128 amount, address senderOwnerAddress, TvmCell body);

    //========================================
    // Getters
    function getInfo(bool includeAllowance) external view returns(TvmCell walletCode,
                                                                  address ownerAddress,
                                                                  address rootAddress,
                                                                  uint128 balance,
                                                                  address notifyOnReceiveAddress,
                                                                  mapping(address => AllowanceInfo)
                                                                          allowanceList);

    function callInfo(bool includeAllowance) external view responsible returns(TvmCell walletCode,
                                                                               address ownerAddress,
                                                                               address rootAddress,
                                                                               uint128 balance,
                                                                               address notifyOnReceiveAddress,
                                                                               mapping(address => AllowanceInfo)
                                                                                       allowanceList);
    function  getAllowanceSingle(address addr) external view             returns (AllowanceInfo); // 
    function callAllowanceSingle(address addr) external view responsible returns (AllowanceInfo); // 

    //========================================
    /// @notice Sends burn command to Root;
    ///
    /// @param amount - Amount of tokens to burn;
    //
    function burn(uint128 amount) external;

    //========================================
    /// @notice Sends Tokens to another Wallet;
    ///
    /// @param amount              - Amount of tokens to send;
    /// @param targetOwnerAddress  - Receiver Wallet owner address to calculate Wallet address;
    /// @param initiatorAddress    - Transaction initiator (e.g. Multisig) to return the unspent change;
    /// @param notifyAddress       - "iFTNotify" contract address to receive a notification about minting (may be zero);
    /// @param allowReceiverNotify - Allow receiver notifications. Please refer to README for information;
    /// @param body                - Custom body (business-logic specific, may be empty);
    //
    function transfer(uint128 amount, address targetOwnerAddress, address initiatorAddress, address notifyAddress, bool allowReceiverNotify, TvmCell body) external;

    //========================================
    /// @notice Receives Tokens from another Wallet or Root (minting);
    ///
    /// @param amount              - Amount of tokens to receive;
    /// @param senderOwnerAddress  - Sender Wallet owner address to calculate Wallet address (may be zero when Root performs mint operation);
    /// @param initiatorAddress    - Transaction initiator (e.g. Multisig) to return the unspent change;
    /// @param notifyAddress       - "iFTNotify" contract address to receive a notification about minting (may be zero);
    /// @param allowReceiverNotify - Allow receiver notifications. Please refer to README for information;
    /// @param body                - Custom body (business-logic specific, may be empty);
    //    
    function receiveTransfer(uint128 amount, address senderOwnerAddress, address initiatorAddress, address notifyAddress, bool allowReceiverNotify, TvmCell body) external;

    //========================================
    /// @notice Changes contract address to receive a notification when "receiveTransfer" is performed;
    ///
    /// @param newNotifyOnReceiveAddress - "iFTNotify" contract address to receive a notification (when zero no one is notified);
    //
    function changeNotifyOnReceiveAddress(address newNotifyOnReceiveAddress) external;

    //========================================
    /// @notice Changes target address allowance. If `amount` == 0 then allowance is deleted;
    ///
    /// @param targetAddress - Allowance target address (spender);
    /// @param amount        - Allowance amount;
    /// @param until         - Allowance expiration dt in unixtime (0 means endless);
    //
    function setAllowance(address targetAddress, uint128 amount, uint32 until) external;

    //========================================
    /// @notice Deletes all pending allowances. If you want to alter single allowance please use `setAllowance`;
    //
    function clearAllowance() external;
}

//================================================================================
//
