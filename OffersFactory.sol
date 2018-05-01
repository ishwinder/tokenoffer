pragma solidity ^0.4.11;

import './TokenPurchase.sol';
import './DetailedERC20.sol';
import './TokenOffer.sol';

contract OffersFactory {

  function OffersFactory() {
  }

  event TokenOfferCreated(address indexed offerAddress, address indexed erc20Address,
      uint256 _amount, uint256 _price, bool isSale);

  function createOffer(DetailedERC20 _token, uint256 _amount, uint256 _price, bool _isSale) payable external returns (address) {
      // require(_amount > 0);

      TokenOffer tokenOffer = new TokenOffer(_token, _amount, _price, _isSale);

      if(_isSale) {
         // They have to pledge ether for sale offer.
         //tokenOffer.sellerPledge();
      }

      tokenOffer.transferOwnership(msg.sender);
      TokenOfferCreated(tokenOffer, _token, _amount, _price, _isSale);

      return tokenOffer;
  }
}
