pragma ton-solidity >= 0.44.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../interfaces/ILiquidFTRoot.sol";

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
    function  getWalletCode() external view             returns (TvmCell);   // Wallet code;
    function callWalletCode() external view responsible returns (TvmCell);   // Wallet code, responsible;
    function  getWalletInfo() external view             returns (TokenInfo); // Token information;
    function callWalletInfo() external view responsible returns (TokenInfo); // Token information, responsible;

    //========================================
    /// @notice Sends burn command to Root;
    ///
    /// @param amount - Amount of tokens to burn;
    //
    function burn(uint128 amount) external;

    //========================================
    /// @notice Sends Tokens to another Wallet;
    ///
    /// @param amount             - Amount of tokens to send;
    /// @param targetOwnerAddress - Receiver Wallet owner address to calculate Wallet address;
    /// @param initiatorAddress   - Transaction initiator (e.g. Multisig) to return the unspent change;
    /// @param notifyAddress      - "iFTNotify" contract address to receive a notification about minting (may be zero);
    /// @param body               - Custom body (business-logic specific, may be empty);
    //
    function transfer(uint128 amount, address targetOwnerAddress, address initiatorAddress, address notifyAddress, TvmCell body) external;

    //========================================
    /// @notice Receives Tokens from another Wallet or Root (minting);
    ///
    /// @param amount             - Amount of tokens to receive;
    /// @param senderOwnerAddress - Sender Wallet owner address to calculate Wallet address (may be zero when Root performs mint operation);
    /// @param initiatorAddress   - Transaction initiator (e.g. Multisig) to return the unspent change;
    /// @param notifyAddress      - "iFTNotify" contract address to receive a notification about minting (may be zero);
    /// @param body               - Custom body (business-logic specific, may be empty);
    //    
    function receiveTransfer(uint128 amount, address senderOwnerAddress, address initiatorAddress, address notifyAddress, TvmCell body) external;

    //========================================
    /// @notice Changes contract address to receive a notification when "receiveTransfer" is performed;
    ///
    /// @param newNotifyOnReceiveAddress - "iFTNotify" contract address to receive a notification (when zero no one is notified);
    //
    function changeNotifyOnReceiveAddress(address newNotifyOnReceiveAddress) external;
}

//================================================================================
//
