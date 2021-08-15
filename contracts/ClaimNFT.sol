// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IBEP20.sol";
import "./AnWNFT.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract ClaimNFT is OwnableUpgradeable, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _tokenIds;
    mapping(address => CountersUpgradeable.Counter) public totalRefs;
    mapping(address => string) public refs;
    mapping(string => address) public refAddresses;
    // CountersUpgradeable.Counter public totalClaims;
    bool public isClaim;
    AnWNFT public anWNFT;

    struct InfoClaimNFT {
        uint256 timeClaim; //timeClaim != 0 is Received
        uint256 nftId;
        address receiver;
        string ref;
    }

    mapping(address => uint256) public indexOfClaimNFTs;
    mapping(uint256 => InfoClaimNFT) public infoClaimNFTs;
    uint256 public timeWait;
    uint256 public minFee;
    event claimNFTEvent(uint256 nftId);

    function initialize() public initializer {
        isClaim = true;
        timeWait = 604800;
        __Ownable_init();
    }

    function initByOwner(bool _isClaim, AnWNFT _anWNFT)
        public
        // ,IBEP20 _bep20
        onlyOwner
    {
        isClaim = _isClaim;
        anWNFT = _anWNFT;
    }

    function isClaimedNFT(address receiver) external view returns (bool) {
        uint256 index = indexOfClaimNFTs[receiver];
        if (infoClaimNFTs[index].nftId != 0) {
            return true;
        } else {
            return false;
        }
    }

    function registerClaimNFT(string memory ref) external whenNotPaused {
        require(isClaim == true, "Claim is not active");
        require(bytes(ref).length <= 6, "ref is not correct");
        _tokenIds.increment();
        uint256 index = _tokenIds.current();
        indexOfClaimNFTs[msg.sender] = index;
        infoClaimNFTs[index].receiver = msg.sender;
        infoClaimNFTs[index].timeClaim = block.timestamp + timeWait;
        infoClaimNFTs[index].ref = ref;
        string memory _refs = getSlice(3, 8);
        if (refAddresses[_refs] != msg.sender) {
            refs[msg.sender] = _refs;
            refAddresses[_refs] = msg.sender;
        }

        address parentRef = refAddresses[infoClaimNFTs[index].ref];
        if (parentRef != 0x0000000000000000000000000000000000000000) {
            totalRefs[parentRef].increment();
        }

        emit claimNFTEvent(index);
    }

    function claimNFT() external whenNotPaused {
        require(isClaim == true, "Claim is not active");
        uint256 index = indexOfClaimNFTs[msg.sender];
        require(index != 0, "You not register");
        require(
            infoClaimNFTs[index].timeClaim < block.timestamp,
            "You can not claim"
        );
        require(infoClaimNFTs[index].nftId == 0, "You can not claim again");
        uint256 id = anWNFT.createAnWNFT(msg.sender, 1, 1);
        infoClaimNFTs[index].nftId = id;
        emit claimNFTEvent(id);
    }

    function getInfoClaimNFT(address sender)
        external
        view
        returns (
            uint256 _timeClaim,
            address _receiver,
            uint256 _index,
            uint256 _nftId,
            string memory _ref
        )
    {
        _index = indexOfClaimNFTs[sender];
        _timeClaim = infoClaimNFTs[_index].timeClaim;
        _receiver = infoClaimNFTs[_index].receiver;
        _nftId = infoClaimNFTs[_index].nftId;
        _ref = infoClaimNFTs[_index].ref;
    }

    function setInfoClaimNFT(
        uint256 _timeClaim,
        address _receiver,
        uint256 _index,
        uint256 _nftId
    ) external whenNotPaused {
        uint256 index = indexOfClaimNFTs[msg.sender];
        require(index == 0, "You not register");
        infoClaimNFTs[_index].timeClaim = _timeClaim;
        infoClaimNFTs[_index].receiver = _receiver;
        infoClaimNFTs[_index].nftId = _nftId;
    }

    function listInfoClaimNFT(uint256 from, uint256 to)
        external
        view
        returns (InfoClaimNFT[] memory)
    {
        uint256 range = to - from + 1;
        require(range >= 1, "range [from to] must be greater than 0");
        require(range <= 100, "range [from to] must be less than 100");
        InfoClaimNFT[] memory result = new InfoClaimNFT[]((to - from) + 1);
        uint256 i = from;
        uint256 index = 0;
        for (i; i <= to; i++) {
            result[index] = infoClaimNFTs[i];
            index++;
        }
        return result;
    }

    function getSlice(uint256 begin, uint256 end)
        public
        view
        returns (string memory)
    {
        bytes memory a = new bytes(end - begin + 1);
        for (uint256 i = 0; i <= end - begin; i++) {
            a[i] = bytes(addressToString(msg.sender))[i + begin - 1];
        }
        return string(a);
    }

    function addressToString(address _addr)
        public
        pure
        returns (string memory)
    {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    // function setClaimNFTDefault(address[] memory _recipients)
    //     external
    //     onlyOwner
    // {
    //     require(_recipients.length > 0, "recipients or amountClaims not empty");
    //     for (uint256 i = 0; i < _recipients.length; i++) {
    //         if (indexOfClaimNFTs[_recipients[i]] == 0) {
    //             _tokenIds.increment();
    //             uint256 newInfoClaimNFT = _tokenIds.current();
    //             indexOfClaimNFTs[_recipients[i]] = newInfoClaimNFT;

    //             uint256 id = anWNFT.createAnWNFT(msg.sender, 1, 1);
    //             infoClaimNFTs[newInfoClaimNFT].timeClaim = 0;
    //             infoClaimNFTs[newInfoClaimNFT].receiver = _recipients[i];
    //             infoClaimNFTs[newInfoClaimNFT].nftId = id;

    //             emit claimNFTEvent(id);
    //         }
    //     }
    // }

    //     function compareStrings(string memory a, string memory b) public pure returns (bool) {
    //     return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    // }

    function setAnWNFT(AnWNFT _anWNFT) public onlyOwner {
        anWNFT = _anWNFT;
    }

    function setMinFee(uint256 _minFee) public onlyOwner {
        minFee = _minFee;
    }

    function setIsClaim(bool _isClaim) public onlyOwner {
        isClaim = _isClaim;
    }

    function setTimeWait(uint256 _timeWait) public onlyOwner {
        timeWait = _timeWait;
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
}
