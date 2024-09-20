// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketplace is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    
    uint256 private _tokenIds;

    // struct for listing
    struct NFTListing {
        uint256 price;
        address payable seller;
        bool isActive;
    }
    mapping(uint256 => NFTListing) private _listings;

    // struct to make an offer
    struct Offer {
        address payable offerer;
        uint256 offerAmount;
        bool isActive;
    }
    mapping(uint256 => Offer) private _offers;


    //events
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTListingCancelled(uint256 tokenId, address seller);
    event OfferCreated(uint256 tokenId, address offerer, uint256 offerAmount);
    event OfferAccepted(uint256 tokenId, address offerer, uint256 offerAmount);
    event OfferRejected(uint256 tokenId, address offerer);
    event OfferCancelled(uint256 tokenId, address offerer, uint256 offerAmount);


    // Custom errors
    error NotOwner();
    error PriceMustBeGreaterThanZero();
    error NFTNotListedForSale();
    error NFTListingNotActive();
    error NotSeller();
    error InsufficientPayment();
    error TransferFailed();
    error OfferAlreadyExists();
    error OfferNotFound();
    error CannotOfferOnOwnNFT();
    error NotOfferer();


    constructor(address _owner) ERC721("NFT Marketplace", "NFTM") Ownable(_owner) {}


    // mint new nft
    function mint(string memory _tokenURI) public returns (uint256) {
        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        return newTokenId;
    }


    // owner list nft for other to see and make offer
    function listNFT(uint256 tokenId, uint256 price) public {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotOwner();
        }
        if (price == 0) {
            revert PriceMustBeGreaterThanZero();
        }

        _listings[tokenId] = NFTListing(price, payable(msg.sender), true);
        emit NFTListed(tokenId, price, msg.sender);
    }

    //owner cancel listing
    function cancelListing(uint256 tokenId) public {
        NFTListing storage listing = _listings[tokenId];
        if (listing.seller != msg.sender) {
            revert NotSeller();
        }
        if (!listing.isActive) {
            revert NFTListingNotActive();
        }
        
        listing.isActive = false;
        emit NFTListingCancelled(tokenId, msg.sender);
    }


    // buyers see nft and make an offer with eth
    function makeOffer(uint256 tokenId) public payable {
        if (ownerOf(tokenId) == msg.sender) {
            revert CannotOfferOnOwnNFT();
        }
        if (_offers[tokenId].isActive) {
            revert OfferAlreadyExists();
        }
        if (msg.value == 0) {
            revert PriceMustBeGreaterThanZero();
        }

        _offers[tokenId] = Offer(payable(msg.sender), msg.value, true);
        emit OfferCreated(tokenId, msg.sender, msg.value);
    }

    // buyer cancel offer and deposited eth gets tranferred back
    function cancelOffer(uint256 tokenId) public nonReentrant {
        Offer memory offer = _offers[tokenId];
        if (!offer.isActive) {
            revert OfferNotFound();
        }
        if (offer.offerer != msg.sender) {
            revert NotOfferer();
        }

        uint256 offerAmount = offer.offerAmount;

        delete _offers[tokenId];

        (bool sent, ) = payable(msg.sender).call{value: offerAmount}("");
        if (!sent) {
            revert TransferFailed();
        }

        emit OfferCancelled(tokenId, msg.sender, offerAmount);
    }



    // owner of nft accept a buyers offer
    function acceptOffer(uint256 tokenId) public nonReentrant {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotOwner();
        }
        Offer memory offer = _offers[tokenId];
        if (!offer.isActive) {
            revert OfferNotFound();
        }

        address payable seller = payable(msg.sender);
        address payable buyer = offer.offerer;
        uint256 offerAmount = offer.offerAmount;

       

        (bool sent, ) = seller.call{value: offerAmount}("");
        if (!sent) {
            revert TransferFailed();
        }

        _transfer(seller, buyer, tokenId);

        delete _offers[tokenId];
        if (_listings[tokenId].isActive) {
            _listings[tokenId].isActive = false;
        }

        emit OfferAccepted(tokenId, buyer, offerAmount);
    }


    // owner of nft reject buy offer
    function rejectOffer(uint256 tokenId) public {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotOwner();
        }
        Offer memory offer = _offers[tokenId];
        if (!offer.isActive) {
            revert OfferNotFound();
        }

        address payable offerer = offer.offerer;
        uint256 offerAmount = offer.offerAmount;

        delete _offers[tokenId];

        (bool sent, ) = offerer.call{value: offerAmount}("");
        if (!sent) {
            revert TransferFailed();
        }

        emit OfferRejected(tokenId, offerer);
    }


    
    function getListingDetails(uint256 tokenId) public view returns (uint256 price, address seller, bool isActive) {
        NFTListing memory listing = _listings[tokenId];
        return (listing.price, listing.seller, listing.isActive);
    }

    function getOfferDetails(uint256 tokenId) public view returns (address offerer, uint256 offerAmount, bool isActive) {
        Offer memory offer = _offers[tokenId];
        return (offer.offerer, offer.offerAmount, offer.isActive);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    // withdraw stuct eth
    function withdrawFunds() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert("No funds to withdraw");
        }
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }
}