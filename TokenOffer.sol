pragma solidity ^0.4.11;

import './DetailedERC20.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract TokenOffer is Ownable {
  enum StatusOptions { Created, MakerPledge, TakerPledge, Tokens, Closed }

  bool public canReceiveEther;
  uint256 public amount;
  uint256 public price;
  DetailedERC20 public token;
  bool public isSale;
  mapping(address => uint256) pledges;
  StatusOptions status;

  event Refund(uint256 price);
  event TokenSold(address buyer, address seller, uint256 price, uint256 amount);

  modifier notClosed() {
    require(status != StatusOptions.Closed);
    _;
  }

  modifier canNotReceiveEther() {
    require(!canReceiveEther);
    _;
  }

   function TokenOffer(DetailedERC20 _token, uint256 _amount, uint256 _price, bool _isSale) payable {
      require(_amount > 0);
      require(_price > 0);

      // Sale offer requires 10% of pledge and buy offer requires full pledge.
      if(_isSale) {
         require(msg.value == _price/10);
      } else {
         require(msg.value == _price);
      }

      token = _token;
      amount = _amount;
      price = _price;
      isSale = _isSale;
      canReceiveEther = true;
      pledges[msg.sender] = msg.value;
      status = StatusOptions.MakerPledge;
   }

   function priceInWei() constant returns(uint) {
      return this.balance;
   }

   function takerPledge() payable external returns(bool) {
      require(status == StatusOptions.MakerPledge);

      // when you take an offer, you send the full price on sale offer.
      // if its a purchase offer, you send 1/10 of value.
      if(isSale) {
         require(msg.value == price);
      } else {
         require(msg.value == price/10);
      }

      pledges[msg.sender] = msg.value;
      status = StatusOptions.TakerPledge;
   }

  function claim() notClosed canNotReceiveEther returns(bool) {
    address _seller = msg.sender;
    uint256 _allowedTokens = token.allowance(_seller, address(this));
    require(_allowedTokens >= amount);

    status = StatusOptions.Closed;

    if(!token.transferFrom(_seller, owner, amount)) revert();
    uint256 _priceInWei = priceInWei();
    _seller.transfer(_priceInWei);
    TokenSold(owner, _seller, _priceInWei, amount);
    return true;
  }

  function refund() onlyOwner notClosed canNotReceiveEther returns(bool) {
    status = StatusOptions.Closed;

    uint256 _priceInWei = priceInWei();
    owner.transfer(_priceInWei);
    Refund(_priceInWei);
    return true;
  }
}
