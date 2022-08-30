// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/* -------------- */
/*      Errors    */
/* -------------- */

error NftMarketPlace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketPlace__NotOwner(address nftAddress, uint256 tokenId, address notOwner);
error NftMarketPlace__PriceAboveZero();
error NftMarketPlace__NotApprovedForMarketPlace(address nftAddress, uint256 tokenId);
error NftMarketPlace__NotListedOnMarketPlace(address nftAddress, uint256 tokenId);
error NftMarketPlace__InsufficientFunds(address nftAddress, uint256 tokenId, uint256 listedPrice, uint256 sentPrice);
error NftMarketPlace__NoFundToWithdraw(address withdrawer);
error NftMarketPlace__WithdrawFailed(address withdrawer);

contract NftMarketPlace is ReentrancyGuard {

    struct NFT {
        uint256 price;
        address seller;
    }

    event NFTListed(
        address indexed nftAddress, 
        uint256 indexed tokenId, 
        uint256 price, 
        address indexed seller
    );

    event ListingCanceled(
        address indexed nftAddress, 
        uint256 indexed tokenId, 
        address indexed seller
    );

    event ListedNFTSelled(
        address indexed nftAddress, 
        uint256 indexed tokenId, 
        uint256 price, 
        address seller, 
        address indexed buyer
    );

    mapping(address => mapping(uint256 => NFT)) private nft_listings; // _nftAddress => TokenId => NFT
    mapping(address => uint256) private balances;
    
    /* -------------- */
    /*    Modifiers   */
    /* -------------- */

    modifier notListed(address _nftAddress, uint256 _tokenId) {
        NFT memory nft = nft_listings[_nftAddress][_tokenId];
        if(nft.price > 0) {
            revert NftMarketPlace__AlreadyListed(_nftAddress, _tokenId);
        }
        _;
    }    

    modifier isOwner(address _nftAddress, uint256 _tokenId, address _owner) {
        IERC721 nft = IERC721(_nftAddress);
        if(nft.ownerOf(_tokenId) != _owner) {
            revert NftMarketPlace__NotOwner(_nftAddress, _tokenId, _owner);
        }
        _;
    }

    modifier isPriceAboveZero(uint256 _price) {
        if(_price <= 0) {
            revert NftMarketPlace__PriceAboveZero();
        }
        _;
    }

    modifier isListed(address _nftAddress, uint256 _tokenId) {
        NFT memory nft = nft_listings[_nftAddress][_tokenId];
        if(nft.price <= 0) {
            revert NftMarketPlace__NotListedOnMarketPlace(_nftAddress, _tokenId);
        }
        _;
    }

    /* -------------- */
    /* Main Functions */
    /* -------------- */

    /*
    * @notice: Method for listing NFT's
    * @param: _nftAddress: Address of the NFT contract
    * @param: _tokenId: Token ID of the NFT
    * @param: _price: Price of the NFT
    */
    function listNFT(
        address _nftAddress, 
        uint256 _tokenId, 
        uint256 _price
        ) 
        external
        notListed(_nftAddress, _tokenId)
        isOwner(_nftAddress, _tokenId, msg.sender)
        isPriceAboveZero(_price)
        nonReentrant
    {
        IERC721 nft = IERC721(_nftAddress);
        if(nft.getApproved(_tokenId) != address(this)) {
            revert NftMarketPlace__NotApprovedForMarketPlace(_nftAddress, _tokenId);
        }

        nft_listings[_nftAddress][_tokenId] = NFT(_price, msg.sender);
        emit NFTListed(_nftAddress, _tokenId, _price, msg.sender);
    }

    /*
    * @notice: Method for canceling Nft Listing
    * @param: _nftAddress: Address of the NFT contract
    * @param: _tokenId: Token ID of the NFT
    */
    function cancelListing(
        address _nftAddress,
        uint256 _tokenId
    )
        external
        isListed(_nftAddress, _tokenId)
        isOwner(_nftAddress, _tokenId, msg.sender)
    {
        delete (nft_listings[_nftAddress][_tokenId]);
        emit ListingCanceled(_nftAddress, _tokenId, msg.sender);
    }

    /*
    * @notice: Method for buying NFT's listed on the marketplace
    * @param: _nftAddress: Address of the NFT contract
    * @param: _tokenId: Token ID of the NFT
    */
    function buyNFT(
        address _nftAddress,
        uint256 _tokenId
    )
        external
        payable
        isListed(_nftAddress, _tokenId)
        nonReentrant
    {
        NFT memory listedNFT = nft_listings[_nftAddress][_tokenId];
        if(msg.value < listedNFT.price) {
            revert NftMarketPlace__InsufficientFunds(_nftAddress, _tokenId, listedNFT.price, msg.value);
        }
        delete (nft_listings[_nftAddress][_tokenId]);

        balances[listedNFT.seller] += msg.value;
        IERC721 nftContract = IERC721(_nftAddress);
        nftContract.safeTransferFrom(listedNFT.seller, msg.sender, _tokenId);
        emit ListedNFTSelled(_nftAddress, _tokenId, listedNFT.price, listedNFT.seller, msg.sender);
    }

    /*
    * @notice: Method for updating NFT's price
    * @param: _nftAddress: Address of the NFT contract
    * @param: _tokenId: Token ID of the NFT
    * @param: _price: New price of the NFT
    */
    function updateListingPrice(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    )
        external
        isListed(_nftAddress, _tokenId)
        isOwner(_nftAddress, _tokenId, msg.sender)
        isPriceAboveZero(_newPrice)
        nonReentrant
    {
        nft_listings[_nftAddress][_tokenId].price = _newPrice;
        emit NFTListed(_nftAddress, _tokenId, _newPrice, msg.sender);
    }

    function withdrawBalance()
        external
        nonReentrant
    {
        uint256 amount = balances[msg.sender];
        if(amount <= 0) {
            revert NftMarketPlace__NoFundToWithdraw(msg.sender);
        }
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) {
            revert NftMarketPlace__WithdrawFailed(msg.sender);
        }
    }
    
    /* ---------------- */
    /* Getter Functions */
    /* ---------------- */
    
    function getListing(address _nftAddress, uint256 _tokenId) 
        external 
        view 
        returns(NFT memory) 
    {
        return nft_listings[_nftAddress][_tokenId];
    }
    
    function getBalance() 
        external 
        view 
        returns(uint256) 
    {
        return balances[msg.sender];
    }

}


// ListNFT          ✅
// CancelListing    ✅
// BuyNFT           ✅
// UpdateListing    ✅
// WithDrawBalance  ✅
// getListing       ✅
// getBalance       ✅