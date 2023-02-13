// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
// import "./sol";
import "./IBEP20.sol";

contract AnWNFT is
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _tokenIds;

    // using AnWNFTsUpgradeable for AnWNFT;
    using MathUpgradeable for uint256;
    using MathUpgradeable for uint48;
    using MathUpgradeable for uint32;
    using MathUpgradeable for uint16;
    uint256 public version;
    struct AnWNFTStruct {
        uint256 id;
        uint256 anWNFTType;
        uint256 rank;
        uint256 createdTime;
        uint256 isDeleted;
    }

    // namely the ERC721 instances for name symbol decimals etc
    function initialize() public initializer {
        __ERC721_init("A&W NFT", "ANWN");
        __Ownable_init();
    }

    mapping(address => mapping(uint256 => uint256)) public anWNFTs; // address - id - details // cach lay details = anWNFTs[address][anWNFTId]
    mapping(uint256 => address) public anWNFTIndexToOwner;

    address public claimNFT;
    modifier onlyClaimNFTorOperatorOrOwner() {
        require(
            msg.sender == claimNFT ||
                msg.sender == owner() ||
                msg.sender == operator
        );
        _;
    }

    function createAnWNFT(
        address owner,
        uint256 anWNFTType,
        uint256 rank
    ) public onlyClaimNFTorOperatorOrOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newAnWNFTId = _tokenIds.current();
        //we can call mint from the ERC721 contract to mint our nft token
        // _safeMint(msg.sender, newAnWNFTId);
        _safeMint(owner, newAnWNFTId);
        anWNFTs[owner][newAnWNFTId] = encode(
            AnWNFTStruct(newAnWNFTId, anWNFTType, rank, block.timestamp, 0)
        );
        anWNFTIndexToOwner[newAnWNFTId] = owner;
        return newAnWNFTId;
    }

    function updateAnWNFT(
        address owner,
        uint256 nftId,
        uint256 id,
        uint256 anWNFTType,
        uint256 rank,
        uint256 createdTime,
        uint256 isDeleted
    ) public onlyOperatorOrOwner returns (uint256) {
        anWNFTs[owner][nftId] = encode(
            AnWNFTStruct(id, anWNFTType, rank, createdTime, isDeleted)
        );
        return nftId;
    }

    function getAnWNFT(address owner, uint256 id)
        public
        view
        returns (AnWNFTStruct memory _anWNFT)
    {
        uint256 details = anWNFTs[owner][id];
        _anWNFT.id = uint256(uint48(details >> 100));
        _anWNFT.anWNFTType = uint256(uint16(details >> 148));
        _anWNFT.rank = uint256(uint16(details >> 164));
        _anWNFT.createdTime = uint256(uint32(details >> 196));
        _anWNFT.isDeleted = uint256(uint8(details >> 228));
    }

    function getAnWNFTPublic(address _owner, uint256 _id)
        public
        view
        returns (
            uint256 id,
            uint256 anWNFTType,
            uint256 rank,
            uint256 createdTime,
            uint256 isDeleted
        )
    {
        AnWNFTStruct memory _anWNFT = getAnWNFT(_owner, _id);
        id = _anWNFT.id;
        anWNFTType = _anWNFT.anWNFTType;
        rank = _anWNFT.rank;
        createdTime = _anWNFT.createdTime;
        isDeleted = _anWNFT.isDeleted;
    }

    function encode(AnWNFTStruct memory anWNFT) public pure returns (uint256) {
        // function encode(AnWNFT memory anWNFT)  external view returns  (uint256) {
        uint256 value;
        value = uint256(anWNFT.id);
        value |= anWNFT.id << 100;
        value |= anWNFT.anWNFTType << 148;
        value |= anWNFT.rank << 164;
        value |= anWNFT.createdTime << 196;
        value |= anWNFT.isDeleted << 228;
        return value;
    }

    function initByOwner(address _claimNFT) public onlyOwner {
        claimNFT = _claimNFT;
    }

    function getAnWNFTOfSender(address sender)
        external
        view
        returns (AnWNFTStruct[] memory)
    {
        uint256 range = _tokenIds.current();
        uint256 i = 1;
        uint256 index = 0;
        uint256 x = 0;
        for (i; i <= range; i++) {
            AnWNFTStruct memory anWNFT = getAnWNFT(sender, i);
            if (anWNFT.id != 0) {
                index++;
            }
        }
        AnWNFTStruct[] memory result = new AnWNFTStruct[](index);
        i = 1;
        for (i; i <= range; i++) {
            AnWNFTStruct memory anWNFT = getAnWNFT(sender, i);
            if (anWNFT.id != 0) {
                result[x] = anWNFT;
                x++;
            }
        }
        return result;
    }

    function transfer(uint256 _nftId, address _target) external whenNotPaused {
        require(_exists(_nftId), "Non existed NFT");
        require(
            ownerOf(_nftId) == msg.sender || getApproved(_nftId) == msg.sender,
            "Not approved"
        );
        require(_target != address(0), "Invalid address");
        // if (msg.sender != anWNFTMarketPlace) {
        //     require(
        //         _target == anWNFTMarketPlace,
        //         "function only support for Marketplace"
        //     );
        //     require(msg.sender != _target, "Can not transfer myself");
        // }
        AnWNFTStruct memory anWNFT = getAnWNFT(ownerOf(_nftId), _nftId);
        anWNFTs[_target][_nftId] = encode(anWNFT);
        anWNFTs[ownerOf(_nftId)][_nftId] = encode(AnWNFTStruct(0, 0, 0, 0, 0));
        anWNFTIndexToOwner[_nftId] = _target;
        _transfer(ownerOf(_nftId), _target, _nftId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        require(isTransfer == true, "Can not transfer");
        require(_exists(tokenId), "Non existed NFT");
        require(ownerOf(tokenId) == from, "Only owner NFT can transfer");
        require(from != to, "Can not transfer myself");
        require(
            ownerOf(tokenId) == msg.sender ||
                getApproved(tokenId) == msg.sender,
            "Not approved"
        );
        require(to != address(0), "Invalid address");

        AnWNFTStruct memory anWNFT = getAnWNFT(from, tokenId);
        anWNFTs[to][tokenId] = encode(anWNFT);
        anWNFTs[from][tokenId] = encode(AnWNFTStruct(0, 0, 0, 0, 0));
        anWNFTIndexToOwner[tokenId] = to;
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(isTransfer == true, "Can not transfer");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        require(from != to, "Can not transfer myself");
        AnWNFTStruct memory anWNFT = getAnWNFT(from, tokenId);
        anWNFTs[to][tokenId] = encode(anWNFT);
        anWNFTs[from][tokenId] = encode(AnWNFTStruct(0, 0, 0, 0, 0));
        anWNFTIndexToOwner[tokenId] = to;
        _safeTransfer(from, to, tokenId, _data);
    }

    function updateAnWNFTIndexToOwner(uint256 nftId, address owner)
        public
        onlyOwner
    {
        anWNFTIndexToOwner[nftId] = owner;
    }

    function setVersion(uint256 _version) public onlyOwner {
        version = _version;
    }

    function setClaimNFT(address _claimNFT) public onlyOwner {
        claimNFT = _claimNFT;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    string public baseURI;
    using StringsUpgradeable for uint256;

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        address sender = ownerOf(tokenId);
        AnWNFTStruct memory anWNFT = getAnWNFT(sender, tokenId);
        string memory json = ".json";
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        anWNFT.anWNFTType.toString(),
                        "_",
                        anWNFT.rank.toString(),
                        json
                    )
                )
                : "";
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
    }

    address public operator;
    modifier onlyOperatorOrOwner() {
        require(msg.sender == operator || msg.sender == owner());
        _;
    }

    bool isTransfer;

    function setIsTransfer(bool _isTransfer) public onlyOwner {
        isTransfer = _isTransfer;
    }

    IBEP20 public token;

    function setIBEP20(address _tokenBEP20) public onlyOwner {
        token = IBEP20(_tokenBEP20);
    }

    function withdrawToken() external onlyOwner {
        uint256 _balance = token.balanceOf(address(this));
        token.transfer(msg.sender, _balance);
    }
}
