#!/usr/bin/env python3

# ==============================================================================
#
import freeton_utils
from   freeton_utils import *

class LiquidWallet(BaseContract):
    
    def __init__(self, everClient: TonClient, rootAddress: str, ownerAddress: str, signer: Signer = None):
        genSigner = generateSigner() if signer is None else signer
        self.CONSTRUCTOR = {}
        self.INITDATA    = {"_rootAddress":rootAddress, "_ownerAddress":ownerAddress}
        BaseContract.__init__(self, everClient=everClient, contractName="LiquidWallet", pubkey=ZERO_PUBKEY, signer=genSigner)

    #========================================
    #
    def burn(self, msig: Multisig, amount: int, notifyOnReceiveAddress: str = ZERO_ADDRESS):
        result = self._callFromMultisig(msig=msig, functionName="burn", functionParams={"amount":amount, "notifyOnReceiveAddress":notifyOnReceiveAddress}, value=DIME, flags=1)
        return result

    def transfer(self, msig: Multisig, amount: int, targetOwnerAddress: str, initiatorAddress: str = None, notifyAddress: str = ZERO_ADDRESS, allowReceiverNotify: str = False, body: str = ""):
        result = self._callFromMultisig(msig=msig, functionName="transfer", functionParams={"amount":amount,
                                                                                            "targetOwnerAddress":targetOwnerAddress,
                                                                                            "initiatorAddress": msig.ADDRESS if initiatorAddress is None else initiatorAddress,
                                                                                            "notifyAddress":notifyAddress,
                                                                                            "allowReceiverNotify":allowReceiverNotify,
                                                                                            "body":body}, value=DIME*5, flags=1)
        return result

    def changeNotifyOnReceiveAddress(self, msig: Multisig, newNotifyOnReceiveAddress: str):
        result = self._callFromMultisig(msig=msig, functionName="changeNotifyOnReceiveAddress", functionParams={"newNotifyOnReceiveAddress":newNotifyOnReceiveAddress}, value=DIME, flags=1)
        return result

    #========================================
    #
    def getInfo(self, includeAllowance: bool = False, includeWalletCode: bool = False):
        result = self._run(functionName="getInfo", functionParams={"includeAllowance":includeAllowance, "includeWalletCode":includeWalletCode})
        return result
    

# ==============================================================================
# 
