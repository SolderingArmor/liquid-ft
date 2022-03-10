pragma ton-solidity >= 0.52.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
// Metadata JSON format:
// name                - Human readable name   of the token; if JSON value and `_name`   fields are different `_name`   field is preferred.
// symbol              - Human readable symbol of the token; if JSON value and `_symbol` fields are different `_symbol` field is preferred.
// description         - Human readable description of the token.
// icon                - URL to the image of the token. PNG, GIF and JPG file formats are supported. 
//                       You may use the ?ext={file_extension} query to provide information on the file type.
// external_url        - URL to an external application or website where users can also view the token.
//
// EXAMPLE:
//{
//    "name": "Wrapped DOGE",
//    "symbol": "WDOGE",
//    "description": "Yet another wrapped token",
//    "icon": "https://path_to_icon?ext=png",
//    "external_url": "https://wrapped_token_website"
//}

//================================================================================
// TODO
interface ILiquidBurn
{
    function receiveBurnFromRoot(uint128 amount, address senderOwnerAddress, address initiatorAddress) external;
}

//================================================================================
//
interface ILiquidRoot
{
    //========================================
    // Events
    event tokensMinted (uint128 amount,       address targetOwnerAddress, TvmCell body);
    event walletCreated(address ownerAddress, address walletAddress     );
    event tokensBurned (uint128 amount,       address senderOwnerAddress);

    //========================================
    // Getters
    function getWalletAddress(address ownerAddress) external view responsible returns (address targetOwnerAddress, address walletAddress); // Arbitratry Wallet address;

    //
    function getInfo(bool includeMetadata, bool includeWalletCode) external view responsible returns (
        string  name, 
        string  symbol, 
        uint8   decimals, 
        uint128 totalSupply, 
        string  metadata,
        TvmCell walletCode);

    //========================================
    /// @notice Sets 0000000000000000000000000000000;
    ///
    /// @param previousRoot - 0000000000000000000000000000000;
    //
    function setPreviousRoot(address previousRoot) external;

    //========================================
    /// @notice Receives burn command from Wallet;
    ///
    /// @dev Burn is performed by Wallet, not by Root owner;
    ///
    /// @param amount             - Amount of tokens to burn;
    /// @param senderOwnerAddress - Sender Wallet owner address to calculate and verify Wallet address;
    /// @param initiatorAddress   - Transaction initiator (e.g. Multisig) to return the unspent change;
    //
    function burn(uint128 amount, address senderOwnerAddress, address initiatorAddress, address notifyOnReceiveAddress) external;

    //========================================
    /// @notice Mints tokens from Root to a target Wallet;
    ///
    /// @param amount             - Amount of tokens to mint;
    /// @param targetOwnerAddress - Receiver Wallet owner address to calculate Wallet address;
    /// @param notifyAddress      - "iFTNotify" contract address to receive a notification about minting (may be zero);
    /// @param body               - Custom body (business-logic specific, may be empty);
    //
    function mint(uint128 amount, address targetOwnerAddress, address notifyAddress, TvmCell body) external;

    //========================================
    /// @notice Creates a new Wallet with "tokensAmount" Tokens; "tokensAmount > 0" is available only for Root;
    ///         Returns wallet address;
    ///
    /// @param ownerAddress           - Receiver Wallet owner address to calculate Wallet address;
    /// @param notifyOnReceiveAddress - "iFTNotify" contract address to receive a notification when Wallet receives a transfer;
    /// @param tokensAmount           - When called by Root Owner, you can mint Tokens when creating a wallet;
    //
    function createWallet(address ownerAddress, address notifyOnReceiveAddress, uint128 tokensAmount) external returns (address);
}

//================================================================================
//
