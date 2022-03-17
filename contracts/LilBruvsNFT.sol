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

  uint256 public publicMintId = 1;
  uint256 public whiteListMintId = 1;
  uint256 public whiteListMintPrice = 0.00 ether;
  uint256 public publicMintPrice = 0.00 ether;
  uint256 public dropNumber = 0;

  uint256 public mintFrom = 0;
  uint256 public mintTo = 300;
  uint256 public maxMintPerDrop = 3;

  uint256 public whiteListSize = 10;
  bytes32 public whiteListMerkleRoot;

  uint256 public totalMinted = 0;

  bool public isPaused = true;

  mapping(address => bool) public isClaimed;
  mapping(address => uint256) public currentDrop;
  mapping(address => uint256) public currentMinted;

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

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
    require(
      MerkleProof.verify(
        merkleProof,
          root,
          keccak256(abi.encodePacked(msg.sender))
      ),
      "Error: Address is NOT whitelisted yet!"
    );
    _;
  }

  modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
    require(
      price * numberOfTokens <= msg.value,
      "Error: Sent ETH value is INCORRECT!"
    );
    _;
  }

  modifier canMint(uint256 numberOfTokens) {
    require(
      currentDrop[msg.sender] < dropNumber || currentDrop[msg.sender] == dropNumber && currentMinted[msg.sender] + numberOfTokens <= maxMintPerDrop && mintFrom + whiteListSize + publicMintId + numberOfTokens < mintTo,
      "Error: Not enough tokens remaining to mint!"
    );
    _;
  }

  modifier onlyCommunity() {
    require((msg.sender == taylorAddr || msg.sender == oddzleAddr || msg.sender == ownerAddr), "ERR: You are not a correct community memeber!");
    _;
  }

  modifier onlyNotClaimed() {
    require(((currentDrop[msg.sender] == dropNumber && !isClaimed[msg.sender]) || currentDrop[msg.sender] < dropNumber), "ERR: You already claimed!");
    require(((currentDrop[msg.sender] == dropNumber && currentMinted[msg.sender] < maxMintPerDrop) || currentDrop[msg.sender] < dropNumber), "ERR: You cannot mint more at this phase!");
    require(whiteListMintId < whiteListSize, "ERR: WhiteListMint is finished!");
    _;
  }

  function whiteListMint(
    bytes32[] calldata merkleProof
  )
      public
      payable
      isMintAllowed
      isValidMerkleProof(merkleProof, whiteListMerkleRoot)
      isCorrectPayment(whiteListMintPrice, 1)
      onlyNotClaimed
      nonReentrant
  {
      require(mintFrom + whiteListMintId < mintFrom + whiteListSize, "Error: Already minted maximum number of tokens!");
      _mint(msg.sender, mintFrom + whiteListMintId);
      _setTokenURI(mintFrom + whiteListMintId, Strings.toString(mintFrom + whiteListMintId));
      whiteListMintId ++;
      totalMinted ++;
      isClaimed[msg.sender] = true;
 
      if(currentDrop[msg.sender] < dropNumber) {
        currentDrop[msg.sender] = dropNumber;
        currentMinted[msg.sender] = 0;
      }
      currentMinted[msg.sender] ++;
  }

  function publicMint(
    uint256 numberOfTokens
  )
    public
    payable
    isMintAllowed
    isCorrectPayment(publicMintPrice, numberOfTokens)
    canMint(numberOfTokens)
    nonReentrant
  {
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _mint(msg.sender, mintFrom + whiteListSize + publicMintId);
      _setTokenURI(mintFrom + whiteListSize + publicMintId, Strings.toString(mintFrom + whiteListSize + publicMintId));
      publicMintId ++;
      totalMinted ++;
      
      if(currentDrop[msg.sender] < dropNumber) {
        currentDrop[msg.sender] = dropNumber;
        currentMinted[msg.sender] = 0;
      }
      currentMinted[msg.sender] ++;
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

  function setWhiteListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    whiteListMerkleRoot = merkleRoot;
  }

  function setWhiteListMintPrice(uint256 _price) public onlyOwner {
      whiteListMintPrice = _price;
  }

  function setPublicMintPrice(uint256 _price) public onlyOwner {
      publicMintPrice = _price;
  }

  function setPaused(bool _paused) public onlyOwner {
    isPaused = _paused;
  }

  function setDrop(uint256 _dropNumber) public onlyOwner {
    dropNumber = _dropNumber;
  }

  function setWhiteListSize(uint256 _wlSize) public onlyOwner {
    whiteListSize = _wlSize;
  }

  function setMintRange(uint256 _from, uint256 _to) public onlyOwner {
    mintFrom = _from;
    mintTo = _to;
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