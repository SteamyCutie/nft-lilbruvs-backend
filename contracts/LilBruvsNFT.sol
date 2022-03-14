//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LilBruvsNFT is ERC721URIStorage, Ownable, ReentrancyGuard {
  string public baseURI;

  uint256 public maxDropMint = 400;
  uint256 public publicMintId = 1;
  uint256 public SALE_PRICE = 0.00 ether;
  uint256 public DROP_NUMBER = 1;

  bool public isPaused = true;

  address taylorAddr = 0x194f207Ac9C55Dbdcea44D3ff65b5D427e5b7f62;
  address oddzleAddr = 0xFBE11edE3c277594e86251650A98b26C776eA033;
  address communityAddr = 0xfE116480682f4F8702fa87d5146dBf2b5f0c6a9B;
  address ownerAddr = 0xabaA41ECF5F6bd12CdFcac3751d8D06F8c16351f;

  constructor() ERC721("LilBruvsNFT", "NFT") {
    setBaseURI("");
    setPaused(true);
  }

  modifier isMintAllowed() {
    require(
      !isPaused, 
      "Error: You are not allowed to mint until the owner starts Minting!"
    );
    _;
  }

  modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
    require(
      price * numberOfTokens == msg.value,
      "Error: Sent ETH value is INCORRECT!"
    );
    _;
  }

  modifier canMint(uint256 numberOfTokens) {
    require(
      publicMintId + numberOfTokens <= maxDropMint,
      "Error: Not enough tokens remaining to mint!"
    );
    _;
  }

  modifier onlyCommunity() {
    require((msg.sender == taylorAddr || msg.sender == oddzleAddr || msg.sender == ownerAddr), "ERR: You are not a correct community memeber!");
    _;
  }

  function publicMint(
    uint256 numberOfTokens
  )
    public
    payable
    isMintAllowed
    isCorrectPayment(SALE_PRICE, numberOfTokens)
    canMint(numberOfTokens)
    nonReentrant
  {
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _mint(msg.sender, publicMintId);
      _setTokenURI(publicMintId, Strings.toString(publicMintId));
      publicMintId ++;
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Error: Token does not exist!");
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setSalePrice(uint256 _price) public onlyOwner {
    SALE_PRICE = _price;
  }

  function setDrop(uint256 _dropNumber) public onlyOwner {
    DROP_NUMBER = _dropNumber;
  }

  function setPaused(bool _paused) public onlyOwner {
    isPaused = _paused;
  }

  function distributeTreasure() public onlyCommunity {
    uint256 toCommun = address(this).balance / 2;
    uint256 toTaylor = address(this).balance / 4;
    uint256 toOddzle = address(this).balance / 4;
    payable(communityAddr).transfer(toCommun);
    payable(taylorAddr).transfer(toTaylor);
    payable(oddzleAddr).transfer(toOddzle);
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawTokens(IERC20 token) public onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    token.transfer(msg.sender, balance);
  }
}