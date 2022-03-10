#!/usr/bin/env python3

# ==============================================================================
#
import freeton_utils
from   freeton_utils import *

class LiquidRoot(BaseContract):
    
    def __init__(self, everClient: TonClient, name: str, symbol: str, decimals: int, ownerAddress: str, signer: Signer = None):
        genSigner = generateSigner() if signer is None else signer
        self.CONSTRUCTOR = {"ownerAddress":ownerAddress}
        self.INITDATA    = {"_walletCode": getCodeFromTvc("../bin/LiquidWallet.tvc"), "_name": name, "_symbol": symbol, "_decimals": decimals}
        BaseContract.__init__(self, everClient=everClient, contractName="LiquidRoot", pubkey=genSigner.keys.public, signer=genSigner)

    #========================================
    #
    def setOwner(self, msig: Multisig, ownerAddress: str):
        result = self._callFromMultisig(msig=msig, functionName="setOwner", functionParams={"ownerAddress":ownerAddress}, value=DIME, flags=1)
        return result

    def setMetadata(self, msig: Multisig, metadata: str):
        result = self._callFromMultisig(msig=msig, functionName="setMetadata", functionParams={"metadata":metadata}, value=DIME, flags=1)
        return result

    def setPreviousRoot(self, msig: Multisig, previousRoot: str):
        result = self._callFromMultisig(msig=msig, functionName="setPreviousRoot", functionParams={"previousRoot":previousRoot}, value=DIME, flags=1)
        return result

    def mint(self, msig: Multisig, amount: int, targetOwnerAddress: str, notifyAddress: str = ZERO_ADDRESS, body: str = ""):
        result = self._callFromMultisig(msig=msig, functionName="mint", functionParams={"amount":amount, "targetOwnerAddress":targetOwnerAddress, "notifyAddress":notifyAddress, "body":body}, value=DIME*5, flags=1)
        return result

    def createWallet(self, msig: Multisig, ownerAddress: str, notifyOnReceiveAddress: str, tokensAmount: int):
        result = self._callFromMultisig(msig=msig, functionName="createWallet", functionParams={"ownerAddress":ownerAddress, "notifyOnReceiveAddress":notifyOnReceiveAddress, "tokensAmount":tokensAmount}, value=DIME*5, flags=1)
        return result

    #========================================
    #
    def getInfo(self, includeMetadata: bool = True, includeWalletCode: bool = False):
        result = self._run(functionName="getInfo", functionParams={"includeMetadata":includeMetadata, "includeWalletCode":includeWalletCode, "answerId":0})
        return result
    
    def getWalletAddress(self, ownerAddress: str):
        result = self._run(functionName="getWalletAddress", functionParams={"ownerAddress":ownerAddress})
        return result

# ==============================================================================
# 
