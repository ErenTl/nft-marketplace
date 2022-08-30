ethsec@7df50ceb8b52:~/files$ slither ./nftMarketPlace/contracts --solc-remaps @openzeppelin=node_modules/@openzeppelin --exclude naming-convention,external-function,low-level-calls

Reentrancy in NftMarketPlace.buyNFT(address,uint256) (nftMarketPlace/contracts/NftMarketPlace.sol#138-157):
        External calls:
        - nftContract.safeTransferFrom(listedNFT.seller,msg.sender,_tokenId) (nftMarketPlace/contracts/NftMarketPlace.sol#155)
        Event emitted after the call(s):
        - ListedNFTSelled(_nftAddress,_tokenId,listedNFT.price,listedNFT.seller,msg.sender) (nftMarketPlace/contracts/NftMarketPlace.sol#156)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
===> Function is non-reentrant so there is no problem ✅ 

Different versions of Solidity are used:
        - Version used: ['0.8.15', '^0.8.0']
        - 0.8.15 (nftMarketPlace/contracts/NftMarketPlace.sol#2)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol#4)
        - ^0.8.0 (node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#4)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#different-pragma-directives-are-used

Pragma version0.8.15 (nftMarketPlace/contracts/NftMarketPlace.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.6.12/0.7.6/0.8.7
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol#4) allows old versions
Pragma version^0.8.0 (node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#4) allows old versions
solc-0.8.15 is not recommended for deployment
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity
./nftMarketPlace/contracts analyzed (4 contracts with 75 detectors), 7 result(s) found