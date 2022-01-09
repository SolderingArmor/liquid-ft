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
from   contract_LiquidFTWallet import LiquidFTWallet
from   contract_LiquidFTRoot   import LiquidFTRoot

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

def _unwrapMessages(result):
    return unwrapMessages(getClient(), result["result"].transaction["out_msgs"], _getAbiArray())

def _unwrapMessagesAndPrint(result):
    msgs = _unwrapMessages(result)
    pprint(msgs)

def _getExitCode(msgIdArray):
    msgArray     = unwrapMessages(getClient(), msgIdArray, _getAbiArray())
    if msgArray != "":
        realExitCode = msgArray[0]["TX_DETAILS"]["compute"]["exit_code"]
    else:
        realExitCode = -1
    return realExitCode   

# ==============================================================================
# 
print("DEPLOYING CONTRACTS...")

# MSIGS
msigRoot = Multisig(tonClient=getClient())
msigW1   = Multisig(tonClient=getClient())
msigW2   = Multisig(tonClient=getClient())
msigW3   = Multisig(tonClient=getClient())

giverGive(getClient(), msigRoot.ADDRESS, EVER * 3)
giverGive(getClient(), msigW1.ADDRESS,   EVER * 3)
giverGive(getClient(), msigW2.ADDRESS,   EVER * 3)
giverGive(getClient(), msigW3.ADDRESS,   EVER * 3)

msigRoot.deploy()
msigW1.deploy()
msigW2.deploy()
msigW3.deploy()

root = LiquidFTRoot(tonClient=getClient(), name="token", symbol="TOK", decimals=9, ownerAddress=msigRoot.ADDRESS, signer=msigRoot.SIGNER)
msigRoot.sendTransaction(addressDest=root.ADDRESS, value=DIME*3)
root.deploy()
pprint(root.getInfo())

result = root.mint(msig=msigRoot, amount=100500, targetOwnerAddress=msigW1.ADDRESS)
_unwrapMessages(result)

w1 = LiquidFTWallet(tonClient=getClient(), rootAddress=root.ADDRESS, ownerAddress=msigW1.ADDRESS)

w1.transfer(msig=msigW1, amount=100, targetOwnerAddress=msigW2.ADDRESS)
w2 = LiquidFTWallet(tonClient=getClient(), rootAddress=root.ADDRESS, ownerAddress=msigW2.ADDRESS)

print("Before setting allowance...")
pprint(w1.getInfo(includeAllowance=True))

result = w1.setAllowance(msig=msigW1, targetAddress=msigW3.ADDRESS, amount=100)
print("After setting allowance...")
pprint(w1.getInfo(includeAllowance=True))

result = w1.transfer(msig=msigW3, amount=100, targetOwnerAddress=msigW2.ADDRESS)
print("After first transfer using allowance...")
pprint(w1.getInfo(includeAllowance=True))

result = w1.transfer(msig=msigW3, amount=100, targetOwnerAddress=msigW2.ADDRESS)
print("After second transfer using allowance...")
pprint(w1.getInfo(includeAllowance=True))


print("WALLET 2...")
pprint(w2.getInfo(includeAllowance=True))
