#!/bin/bash

export GATEONE=0xd7ee95BF44eCD6BEE4818A3E81FBd4ED2bbCDa49
export GATEKEEPER=0x2FA71266bDee2857c17A8882f2C6fDDA9c205866

for i in {0..100}
do
    gasToSend=$((819300 + i))
    echo "Gas = $gasToSend"
    cast send -r $ARBSEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY $GATEONE "unlock(address,uint256)()" $GATEKEEPER $gasToSend
    sleep 2
done
