#!/usr/bin/env python3

# ==============================================================================
#
import freeton_utils
from   freeton_utils import *

class LiquidFTRoot(BaseContract):
    
    def __init__(self, tonClient: TonClient, name: str, symbol: str, decimals: int, ownerAddress: str, signer: Signer = None):
        genSigner = generateSigner() if signer is None else signer
        self.CONSTRUCTOR = {"ownerAddress":ownerAddress}
        self.INITDATA    = {"_walletCode": getCodeFromTvc("../bin/LiquidFTWallet.tvc"), "_name":name, "_symbol":symbol, "_decimals":decimals}
        BaseContract.__init__(self, tonClient=tonClient, contractName="LiquidFTRoot", pubkey=genSigner.keys.public, signer=genSigner)

    #========================================
    #
    def changeOwner(self, msig: Multisig, ownerAddress: str):
        result = self._callFromMultisig(msig=msig, functionName="changeOwner", functionParams={"ownerAddress":ownerAddress}, value=DIME, flags=1)
        return result

    def mint(self, msig: Multisig, amount: int, targetOwnerAddress: str, notifyAddress: str = ZERO_ADDRESS, body: str = ""):
        result = self._callFromMultisig(msig=msig, functionName="mint", functionParams={"amount":amount, "targetOwnerAddress":targetOwnerAddress, "notifyAddress":notifyAddress, "body":body}, value=DIME*5, flags=1)
        return result

    def createWallet(self, msig: Multisig, ownerAddress: str, notifyOnReceiveAddress: str, tokensAmount: int):
        result = self._callFromMultisig(msig=msig, functionName="createWallet", functionParams={"ownerAddress":ownerAddress, "notifyOnReceiveAddress":notifyOnReceiveAddress, "tokensAmount":tokensAmount}, value=DIME*5, flags=1)
        return result

    #========================================
    #
    def getInfo(self, includeMetadata: bool = True):
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
