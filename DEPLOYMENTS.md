
# Deployments

## June 13

== Logs ==
  Deployed mock USDC at: 0x685E6B7e6cf4c36C4046B20613e28261dc857D56
  Deployed mock USDT at: 0xB286a423DBce5aDA0327CD81330521fD3550Df35
  Using default registration fee: 10000000000000000000000
  Using default monthly fee: 1000000000
  SubchainRegistry deployed at: 0x7290826674F50d2D5F50f066492da6A4237A3e62

## Setting up 1 EVM.

==========================

Chain 11155111

Estimated gas price: 0.002279022 gwei

Estimated total gas used for script: 3328587

Estimated amount required: 0.000007585923001914 ETH

==========================

##### sepolia
✅  [Success] Hash: 0x4ddfdc2d0d20c4fc5643378d2f32f65325e311d5c817113f8808fe69253457db
Contract Address: 0xB286a423DBce5aDA0327CD81330521fD3550Df35
Block: 8540354
Paid: 0.000000921598557315 ETH (574165 gas * 0.001605111 gwei)


##### sepolia
✅  [Success] Hash: 0x4442da63055b24e0165d4d310552467821af77b4e1dde7f132c183c263775982
Contract Address: 0x685E6B7e6cf4c36C4046B20613e28261dc857D56
Block: 8540354
Paid: 0.000000921598557315 ETH (574165 gas * 0.001605111 gwei)


##### sepolia
✅  [Success] Hash: 0x9771ee1fd94c23f0fb898e72a6dbe3061f8bd6e92839ff71d1cc879ea2f3c5b1
Contract Address: 0x7290826674F50d2D5F50f066492da6A4237A3e62
Block: 8540354
Paid: 0.000002266614160653 ETH (1412123 gas * 0.001605111 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.000004109811275283 ETH (2560453 gas * avg 0.001605111 gwei)
                                                                                                        

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /Users/askucher/Documents/projects/velas-subchain-manager/contracts/broadcast/SubchainRegistry.sol/11155111/run-latest.json

Sensitive values saved to: /Users/askucher/Documents/projects/velas-subchain-manager/contracts/cache/SubchainRegistry.sol/11155111/run-latest.json

➜  velas-subchain-manager git:(master) ✗ git add .                   
➜  velas-subchain-manager git:(master) ✗ git commit -m "fix decimals"
[master a636aac] fix decimals
 4 files changed, 322 insertions(+), 69 deletions(-)
 create mode 100644 contracts/broadcast/SubchainRegistry.sol/11155111/run-1749824690.json
➜  velas-subchain-manager git:(master) bash exec.sh deploy         
^C
➜  velas-subchain-manager git:(master) git push origin HEAD
Enumerating objects: 17, done.
Counting objects: 100% (17/17), done.
Delta compression using up to 16 threads
Compressing objects: 100% (7/7), done.
Writing objects: 100% (10/10), 9.42 KiB | 4.71 MiB/s, done.
Total 10 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
remote: This repository moved. Please use the new location:
remote:   git@github.com:askucher/velas-subchain-manager.git
To github.com:askucher/velas-suchain-manager.git
   fe2d91d..a636aac  HEAD -> master
➜  velas-subchain-manager git:(master) bash exec.sh deploy 
[⠊] Compiling...
[⠑] Compiling 2 files with Solc 0.8.28
[⠘] Solc 0.8.28 finished in 683.33ms
Compiler run successful!
Script ran successfully.

== Logs ==
  Deployed mock USDC at: 0xc257D65D898BB4148EBECBFDDa1D0e96376d80a3
  Deployed mock USDT at: 0x07C7A885a8FE50B215B34f3ba089eAB56ce9aD1A
  Using default registration fee: 10000000000000000000000
  Using default monthly fee: 1000000000000000000000
  SubchainRegistry deployed at: 0x8Fe65655E0b65cD46EB9D5eFc361bc0f156cC194

## Setting up 1 EVM.

==========================

Chain 11155111

Estimated gas price: 0.002299139 gwei

Estimated total gas used for script: 3328634

Estimated amount required: 0.000007652992246126 ETH

==========================

##### sepolia
✅  [Success] Hash: 0xeba46037a85751a91f180adc5f29a7b88cdda35dbf3b9de1d9d017f04c4dc52b
Contract Address: 0x8Fe65655E0b65cD46EB9D5eFc361bc0f156cC194
Block: 8540931
Paid: 0.000002327769003784 ETH (1412159 gas * 0.001648376 gwei)


##### sepolia
✅  [Success] Hash: 0xbacb0a5cf5e5b2d6178467b73802cac913842b471b1dcf0580e65d68b4b6be56
Contract Address: 0x07C7A885a8FE50B215B34f3ba089eAB56ce9aD1A
Block: 8540931
Paid: 0.00000094643980604 ETH (574165 gas * 0.001648376 gwei)


##### sepolia
✅  [Success] Hash: 0x822a705b608b207a57e123024ab5903223fee3931e66e8f26b32612fdcde600f
Contract Address: 0xc257D65D898BB4148EBECBFDDa1D0e96376d80a3
Block: 8540931
Paid: 0.00000094643980604 ETH (574165 gas * 0.001648376 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.000004220648615864 ETH (2560489 gas * avg 0.001648376 gwei)
                                                                                                        

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /Users/askucher/Documents/projects/velas-subchain-manager/contracts/broadcast/SubchainRegistry.sol/11155111/run-latest.json

Sensitive values saved to: /Users/askucher/Documents/projects/velas-subchain-manager/contracts/cache/SubchainRegistry.sol/11155111/run-latest.json

## June 13

== Logs ==
  Deployed mock USDC at: 0x685E6B7e6cf4c36C4046B20613e28261dc857D56
  Deployed mock USDT at: 0xB286a423DBce5aDA0327CD81330521fD3550Df35
  Using default registration fee: 10000000000000000000000
  Using default monthly fee: 1000000000
  SubchainRegistry deployed at: 0x7290826674F50d2D5F50f066492da6A4237A3e62

## Setting up 1 EVM.

==========================

Chain 11155111

Estimated gas price: 0.002279022 gwei

Estimated total gas used for script: 3328587

Estimated amount required: 0.000007585923001914 ETH

==========================

##### sepolia
✅  [Success] Hash: 0x4ddfdc2d0d20c4fc5643378d2f32f65325e311d5c817113f8808fe69253457db
Contract Address: 0xB286a423DBce5aDA0327CD81330521fD3550Df35
Block: 8540354
Paid: 0.000000921598557315 ETH (574165 gas * 0.001605111 gwei)


##### sepolia
✅  [Success] Hash: 0x4442da63055b24e0165d4d310552467821af77b4e1dde7f132c183c263775982
Contract Address: 0x685E6B7e6cf4c36C4046B20613e28261dc857D56
Block: 8540354
Paid: 0.000000921598557315 ETH (574165 gas * 0.001605111 gwei)


##### sepolia
✅  [Success] Hash: 0x9771ee1fd94c23f0fb898e72a6dbe3061f8bd6e92839ff71d1cc879ea2f3c5b1
Contract Address: 0x7290826674F50d2D5F50f066492da6A4237A3e62
Block: 8540354
Paid: 0.000002266614160653 ETH (1412123 gas * 0.001605111 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.000004109811275283 ETH (2560453 gas * avg 0.001605111 gwei)
                                                                                                        

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /Users/askucher/Documents/projects/velas-subchain-manager/contracts/broadcast/SubchainRegistry.sol/11155111/run-latest.json

Sensitive values saved to: /Users/askucher/Documents/projects/velas-subchain-manager/contracts/cache/SubchainRegistry.sol/11155111/run-latest.json

## Jun 13

= Logs ==
  Deployed mock USDC at: 0x153Fa62D7A02B9d62606f8DCb408f7C1cE5e02Fb
  Deployed mock USDT at: 0x7fC37BAeB8117bC9Ff41DE3EE30DD8885c004B05
  Using default registration fee: 10000000000
  Using default monthly fee: 1000000000
  SubchainRegistry deployed at: 0x385650590651c985268b20297A76E6b1A912Ea90

## Setting up 1 EVM.

==========================

Chain 11155111

Estimated gas price: 0.004052234 gwei

Estimated total gas used for script: 3328509

Estimated amount required: 0.000013487897339106 ETH

==========================

##### sepolia
✅  [Success] Hash: 0xecb8b54ff27f9e1201e6a87373d52090665e21580d8b9da182b5a36cdd22ba0d
Contract Address: 0x7fC37BAeB8117bC9Ff41DE3EE30DD8885c004B05
Block: 8539205
Paid: 0.00000139209404741 ETH (574165 gas * 0.002424554 gwei)


##### sepolia
✅  [Success] Hash: 0x8c939c65201ed6311addf8a20c20bc8d439d40b3869956243d6675689921b536
Contract Address: 0x153Fa62D7A02B9d62606f8DCb408f7C1cE5e02Fb
Block: 8539205
Paid: 0.00000139209404741 ETH (574165 gas * 0.002424554 gwei)


##### sepolia
✅  [Success] Hash: 0xa03b8a138c075e3bd6c8d3e3e905da4e93a140ffc040950768efe8679929a34a
Contract Address: 0x385650590651c985268b20297A76E6b1A912Ea90
Block: 8539205
Paid: 0.000003423622994902 ETH (1412063 gas * 0.002424554 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.000006207811089722 ETH (2560393 gas * avg 0.002424554 gwei)
                                                                                                                                                  

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /Users/askucher/Documents/projects/velas-subchain-manager/contracts/broadcast/SubchainRegistry.sol/11155111/run-latest.json

Sensitive values saved to: /Users/askucher/Documents/projects/velas-subchain-manager/contracts/cache/SubchainRegistry.sol/11155111/run-latest.json
