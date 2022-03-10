pragma ton-solidity >= 0.52.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../interfaces/ILiquidRoot.sol";

//================================================================================
// TODO
interface ILiquidNotify
{
    function receiveNotification(uint128 amount, address senderOwnerAddress, address initiatorAddress, TvmCell body) external;
}

//================================================================================
//
interface ILiquidWallet
{
    //========================================
    // Events
    event tokensBurned  (uint128 amount);
    event tokensSent    (uint128 amount, address targetOwnerAddress, address initiatorAddress, address notifyAddress, bool allowReceiverNotify, TvmCell body);
    event tokensReceived(uint128 amount, address senderOwnerAddress, address initiatorAddress, address notifyAddress, bool allowReceiverNotify, TvmCell body);

    //========================================
    // Getters
    function getInfo(bool includeWalletCode) external view responsible returns(
        TvmCell walletCode,
        address ownerAddress,
        address rootAddress,
        uint128 balance,
        address notifyOnReceiveAddress);

    //========================================
    /// @notice Sends burn command to Root;
    ///
    /// @param amount                 - Amount of tokens to burn;
    /// @param notifyOnReceiveAddress - Address to notify about the burn; can be needed in case of token upgrade;
    //
    function burn(uint128 amount, address notifyOnReceiveAddress) external;

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
}

//================================================================================
//
