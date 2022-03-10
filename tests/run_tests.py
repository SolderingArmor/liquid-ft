#!/usr/bin/env python3

# ==============================================================================
# 
import freeton_utils
from   freeton_utils import *
from   tonclient.crypto  import *
import binascii
import unittest
import time
import sys
import os
import random
from   pathlib import Path
from   pprint import pprint
from   contract_LiquidWallet import LiquidWallet
from   contract_LiquidRoot   import LiquidRoot

SERVER_ADDRESS = "https://net.ton.dev"

# ==============================================================================
#
def getClient():
    return TonClient(config=ClientConfig(network=NetworkConfig(server_address=SERVER_ADDRESS)))

# ==============================================================================
# 
# Parse arguments and then clear them because UnitTest will @#$~!
for _, arg in enumerate(sys.argv[1:]):
    if arg == "--disable-giver":
        
        freeton_utils.USE_GIVER = False
        sys.argv.remove(arg)

    if arg == "--throw":
        
        freeton_utils.THROW = True
        sys.argv.remove(arg)

    if arg.startswith("http"):
        
        SERVER_ADDRESS = arg
        sys.argv.remove(arg)

    if arg.startswith("--msig-giver"):
        
        freeton_utils.MSIG_GIVER = arg[13:]
        sys.argv.remove(arg)

# ==============================================================================
# EXIT CODE FOR SINGLE-MESSAGE OPERATIONS
# we know we have only 1 internal message, that's why this wrapper has no filters
def _getAbiArray():
    files = []
    for file in os.listdir("../bin"):
        if file.endswith(".abi.json"):
            files.append(os.path.join("../bin", file))
    return files

def _unwrapMessages(result, everClient: TonClient):
    return unwrapMessages(everClient, result["result"].transaction["out_msgs"], _getAbiArray())

def _unwrapMessagesAndPrint(result):
    msgs = _unwrapMessages(result, getClient())
    pprint(msgs)

def _getExitCode(msgIdArray, everClient: TonClient):
    msgArray     = unwrapMessages(everClient, msgIdArray, _getAbiArray())
    if msgArray != "":
        realExitCode = msgArray[0]["TX_DETAILS"]["compute"]["exit_code"]
    else:
        realExitCode = -1
    return realExitCode   

# ==============================================================================
# 
print("DEPLOYING CONTRACTS...")

# MSIGS
msigRoot1 = Multisig(everClient=getClient())
msigRoot2 = Multisig(everClient=getClient())
msigW1    = Multisig(everClient=getClient())
msigW2    = Multisig(everClient=getClient())
msigW3    = Multisig(everClient=getClient())

giverGive(getClient(), msigRoot1.ADDRESS, EVER * 3)
giverGive(getClient(), msigRoot2.ADDRESS, EVER * 3)
giverGive(getClient(), msigW1.ADDRESS,    EVER * 3)
giverGive(getClient(), msigW2.ADDRESS,    EVER * 3)
giverGive(getClient(), msigW3.ADDRESS,    EVER * 3)

msigRoot1.deploy()
msigRoot2.deploy()
msigW1.deploy()
msigW2.deploy()
msigW3.deploy()

root1 = LiquidRoot(everClient=getClient(), name="token", symbol="TOK", decimals=9, ownerAddress=msigRoot1.ADDRESS, signer=msigRoot1.SIGNER)
msigRoot1.sendTransaction(addressDest=root1.ADDRESS, value=DIME*3)
root1.deploy()
pprint(root1.getInfo())

result = root1.mint(msig=msigRoot1, amount=100500, targetOwnerAddress=msigW1.ADDRESS)
_unwrapMessagesAndPrint(result=result)

w1 = LiquidWallet(everClient=getClient(), rootAddress=root1.ADDRESS, ownerAddress=msigW1.ADDRESS)

result = w1.transfer(msig=msigW1, amount=100, targetOwnerAddress=msigW2.ADDRESS)
_unwrapMessagesAndPrint(result=result)

w2 = LiquidWallet(everClient=getClient(), rootAddress=root1.ADDRESS, ownerAddress=msigW2.ADDRESS)

