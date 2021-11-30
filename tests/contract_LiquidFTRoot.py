#!/usr/bin/env python3

# ==============================================================================
#
import freeton_utils
from   freeton_utils import *

class LiquidFTRoot(BaseContract):
    
    def __init__(self, tonClient: TonClient, name: str, symbol: str, decimals: int, signer: Signer = None):
        genSigner = generateSigner() if signer is None else signer
        self.CONSTRUCTOR = {}
        self.INITDATA    = {"name":name, "symbol":symbol, "decimals":decimals}
        BaseContract.__init__(self, tonClient=tonClient, contractName="LiquidFTRoot", pubkey=ZERO_PUBKEY, signer=genSigner)

    #========================================
    #
    def changeOwner(self, msig: SetcodeMultisig, ownerAddress: str):
        result = self._callFromMultisig(msig=msig, functionName="changeOwner", functionParams={"ownerAddress":ownerAddress}, value=DIME, flags=1)
        return result

    def mint(self, msig: SetcodeMultisig, amount: int, targetOwnerAddress: str, notifyAddress: str, body: str):
        result = self._callFromMultisig(msig=msig, functionName="mint", functionParams={"amount":amount, "targetOwnerAddress":targetOwnerAddress, "notifyAddress":notifyAddress, "body":body}, value=DIME, flags=1)
        return result

    def createWallet(self, msig: SetcodeMultisig, ownerAddress: str, notifyOnReceiveAddress: str, tokensAmount: int):
        result = self._callFromMultisig(msig=msig, functionName="createWallet", functionParams={"ownerAddress":ownerAddress, "notifyOnReceiveAddress":notifyOnReceiveAddress, "tokensAmount":tokensAmount}, value=DIME, flags=1)
        return result

    #========================================
    #
    def getInfo(self, includeMetadata: bool):
        result = self._run(functionName="getInfo", functionParams={"includeMetadata":includeMetadata})
        return result
    
    def getWalletCode(self):
        result = self._run(functionName="getWalletCode", functionParams={})
        return result
    
    def getWalletAddress(self, ownerAddress: str):
        result = self._run(functionName="getWalletAddress", functionParams={"ownerAddress":ownerAddress})
        return result

# ==============================================================================
# 
