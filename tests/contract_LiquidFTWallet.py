#!/usr/bin/env python3

# ==============================================================================
#
import freeton_utils
from   freeton_utils import *

class LiquidFTWallet(BaseContract):
    
    def __init__(self, tonClient: TonClient, rootAddress: str, ownerAddress: str, signer: Signer = None):
        genSigner = generateSigner() if signer is None else signer
        self.CONSTRUCTOR = {}
        self.INITDATA    = {"_rootAddress":rootAddress, "_ownerAddress":ownerAddress}
        BaseContract.__init__(self, tonClient=tonClient, contractName="LiquidFTWallet", pubkey=ZERO_PUBKEY, signer=genSigner)

    #========================================
    #
    def changeOwner(self, msig: SetcodeMultisig, ownerAddress: str):
        result = self._callFromMultisig(msig=msig, functionName="changeOwner", functionParams={"ownerAddress":ownerAddress}, value=DIME, flags=1)
        return result

    def burn(self, msig: SetcodeMultisig, amount: int):
        result = self._callFromMultisig(msig=msig, functionName="burn", functionParams={"amount":amount}, value=DIME, flags=1)
        return result

    def transfer(self, msig: SetcodeMultisig, amount: int, targetOwnerAddress: str, initiatorAddress: str, notifyAddress: str, allowReceiverNotify: str, body: str):
        result = self._callFromMultisig(msig=msig, functionName="transfer", functionParams={"amount":amount,
                                                                                            "targetOwnerAddress":targetOwnerAddress,
                                                                                            "initiatorAddress":initiatorAddress,
                                                                                            "notifyAddress":notifyAddress,
                                                                                            "allowReceiverNotify":allowReceiverNotify,
                                                                                            "body":body}, value=DIME, flags=1)
        return result

    def changeNotifyOnReceiveAddress(self, msig: SetcodeMultisig, newNotifyOnReceiveAddress: str):
        result = self._callFromMultisig(msig=msig, functionName="changeNotifyOnReceiveAddress", functionParams={"newNotifyOnReceiveAddress":newNotifyOnReceiveAddress}, value=DIME, flags=1)
        return result

    def setAllowance(self, msig: SetcodeMultisig, targetAddress: str, amount: int, until: int):
        result = self._callFromMultisig(msig=msig, functionName="setAllowance", functionParams={"targetAddress":targetAddress, "amount":amount, "until":until}, value=DIME, flags=1)
        return result

    def clearAllowance(self, msig: SetcodeMultisig):
        result = self._callFromMultisig(msig=msig, functionName="clearAllowance", functionParams={}, value=DIME, flags=1)
        return result

    #========================================
    #
    def getInfo(self, includeAllowance: bool):
        result = self._run(functionName="getInfo", functionParams={"includeAllowance":includeAllowance})
        return result
    
    def getAllowanceSingle(self, allowanceAddress: str):
        result = self._run(functionName="getAllowanceSingle", functionParams={"allowanceAddress":allowanceAddress})
        return result

# ==============================================================================
# 
