// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC721/ERC721EnumerableUpgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../interfaces/ICharacter.sol";
import "../../library/Genesis.sol";
import "../../utils/Base64.sol";
import "../../utils/Strings.sol";
import "../../proxy/Ownable.sol";
import "./Character3664.sol";

contract Character is Ownable, ICharacter, DirectoryBridge, ERC721EnumerableUpgradeable, IERC721ReceiverUpgradeable, ReentrancyGuard {
    
    using Strings for uint256;
    
    mapping(string => uint256) _characterName;
    mapping(uint256 => mapping(string => string)) _extendAttr;
    
    Character3664 public character3664;

    function initialize() public initializer {
        __ERC721Enumerable_init("Utopia Character Token", "UCT");
        __DirectoryBridge_init();
        __Character_init_unchained();
    }

    function __Character_init_unchained() internal initializer {
        /*uint256[] memory attrIds = new uint256[](12);
        string[] memory names = new string[](12);
        string[] memory symbols = new string[](12);
        string[] memory uris = new string[](12);*/
        
        /*uint256[] memory attrIds = [uint256(CHARACTERATTR.CHARACTER_NAME), uint256(CHARACTERATTR.CHARACTER_OCCUPATION), 
                                    uint256(CHARACTERATTR.CHARACTER_SEX), uint256(CHARACTERATTR.CHARACTER_LEVEL), 
                                    uint256(CHARACTERATTR.CHARACTER_EXPERIENCE), uint256(CHARACTERATTR.CHARACTER_POINTS), 
                                    uint256(CHARACTERATTR.CHARACTER_STRENGTH), uint256(CHARACTERATTR.CHARACTER_DEXTERITY), 
                                    uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), uint256(CHARACTERATTR.CHARACTER_PATIENCE), 
                                    uint256(CHARACTERATTR.CHARACTER_LUCK), uint256(CHARACTERATTR.CHARACTER_GOLD)];
        string[12] memory names = ["name", "occupation", "sex", "level", "experience", "points", "strength", "DEXTERITY", "intelligence", "PATIENCE", "luck", "gold"];
        string[12] memory symbols = ["NAME", "OCCUPATION", "SEX", "LEVEL", "EXPERIENCE", "POINTS", "STRENGTH", "DEXTERITY", "INTELLIGENCE", "PATIENCE", "LUCK", "GOLD"];
        string[12] memory uris = ["", "", "", "", "", "", "", "", "", "", "", ""];*/
        //_mintBatch(attrIds, names, symbols, uris);
    }

    function setCharacter3664(address _character3664) external onlyOwner {
        require(_character3664 != address(0), "address is nil address");
        character3664 = Character3664(_character3664);
    }

    function mintCharacter(address recipient, address recommender, uint256 tokenId, string memory name, uint256 occupation) external payable onlyDirectory {
        require(recipient != address(0), "recipient invalid");
        require(!_exists(tokenId), "tokenId already exists");
        require(getCharacterId(name) == 0, "Name already exist");

        _characterName[name] = tokenId;
        _safeMint(recipient, tokenId);
        
        character3664.initAttributeForCharacter(tokenId, name, occupation, uint256(ESEX.Neutral));
        emit NewCharacter(recipient, recommender, tokenId);
    }

    function attachLucklyPoint(uint256 tokenId, uint256 lucklyPoint) external onlyDirectory {
        require(_exists(tokenId), "Character: invalid characterId");
        require(lucklyPoint != 0, "Character: lucklyPoint is zero");
        require(_isApprovedOrOwner(tx.origin, tokenId), "Not owner or approver");
        character3664.attach(tokenId, uint256(CHARACTERATTR.CHARACTER_LUCK), lucklyPoint, "", false);
    }

    function burnLucklyPoint(uint256 tokenId, uint256 lucklyPoint) external onlyDirectory {
        require(_exists(tokenId), "Character: invalid characterId");
        require(lucklyPoint != 0, "Character: lucklyPoint is zero");
        require(_isApprovedOrOwner(tx.origin, tokenId), "Not owner or approver");
        character3664.burn(tokenId, uint256(CHARACTERATTR.CHARACTER_LUCK), lucklyPoint);
    }

    function getLucklyPoint(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Character: tokenId not exists");
        return character3664.balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_LUCK));
    }

    function getCharacterCE(uint256 tokenId) public view returns (uint256 _ce) {
        require(_exists(tokenId), "Character-getPower: tokenId not exists");
        uint256 occu = character3664.balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_OCCUPATION));
        // 敏捷/力量/智力
        uint256 strength = character3664.balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_STRENGTH));
        uint256 dexterity /*敏捷*/ = character3664.balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_DEXTERITY));
        uint256 intelligence /*智力*/= character3664.balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE));
        uint256 patience/*耐力*/ = character3664.balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_PATIENCE));
        (uint256 _hp, uint256 _dps, uint256 _atk, uint256 _def) = (0, 0, 0, 0);
        // Warrior 战士、 Archer 射手、 Mage 法师
        if(occu == uint256(EOCCUPATION.Archer)){
            _dps = dexterity * 5;
            _atk = dexterity * 5;
            _def = intelligence * 5;
            _hp  = patience * 10;
        }
        if(occu == uint256(EOCCUPATION.Warrior)){
            _dps = dexterity * 5;
            _atk = strength * 5;
            _def = intelligence * 5;
            _hp  = patience * 10;
        }
        if(occu == uint256(EOCCUPATION.Mage)){
            _dps = dexterity * 5;
            _atk = intelligence * 5;
            _def = intelligence * 5;
            _hp  = patience * 10;
        }
        _ce = (_atk + _dps + _def + _hp) * 2;
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) public view returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory output) {
        require(_exists(tokenId), 'Token does not exist');
        output = tokenURIForCharacter(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', tokenId.toString(), '", "description": "The first fully autonomous decentralized NFT Metaverse game.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function tokenURIForCharacter(uint256 tokenId) internal view returns (string memory output) {
        string[] memory parts = new string[](2 * 12 + 3);
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; } </style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';     
        uint256 index = 1;
        uint256 yValue = 20;
        for(uint i = 0; i < 12; i++) {
            yValue = yValue + 20;
            if(i == 0){
                parts[index] = pluck(tokenId, i, true);
            }else{
                parts[index] = pluck(tokenId, i, false);
            }
            index = index + 1;
            parts[index] = string(abi.encodePacked('</text><text x="10" y="',yValue.toString(),'" class="base">')); // '</text><text x="10" y="40" class="base">';
            index++;
        }
        parts[index] = '</text></svg>';

        uint n = 0;
        while(n < parts.length){  // 5
          if(n % 2 == 0){ // 0, 2, 4, 6, 8
            output = string(abi.encodePacked(output, parts[n], parts[n+1]));
          }
          n = n + 2;
          if(n == (parts.length - 1)){
            output = string(abi.encodePacked(output, parts[n]));
            break;
          }
          if(n >= parts.length){
            break;
          } 
        }
        return output;
    }

    // attrIds len: 21
    function pluck(uint256 tokenId, uint256 attrId, bool isText) internal view returns (string memory output) {
        string memory symbol = character3664.symbol(attrId);
        uint256 balance = character3664.balanceOf(tokenId, attrId);
        bytes memory text = character3664.textOf(tokenId, attrId);

        if(isText){
            output = string(abi.encodePacked(symbol, ":", string(text)));
        } else {
            output = string(abi.encodePacked(symbol, ":", balance.toString()));
        }
        /*string memory color = everLight.queryColorByRare(tokenInfo._rare);
        if(bytes(color).length > 0) {
          output = string(abi.encodePacked('<a style="fill:', color, ';">', output, '</a>'));
        }*/
        return output;
    }

    // @dev 查询地址的角色ID列表
    function queryCharacterByAddress(address addr, uint256 startIndex) external view returns(uint256[] memory characterIdList, uint256 lastIndex) {
        uint256 count = ERC721Upgradeable.balanceOf(addr);
        characterIdList = new uint256[](10);    // default returns 20 records.
        uint256 index = 0;
        lastIndex = startIndex;
        for(uint256 i = startIndex; i < count; i++) {
            if(index >= characterIdList.length){
                lastIndex = i;
                break;
            }
            characterIdList[index] = tokenOfOwnerByIndex(addr, i);
            if(characterIdList[index] != 0){
                lastIndex = i;
            }
            index++;
        }
        return (characterIdList, lastIndex);
    }

    /*function queryCharacterAttrs(uint256 tokenId) external view returns(uint256[] memory balances) {
        require(_exists(tokenId), "Token not exist");
        uint256[] memory attrIds = _getInitAttributeAttrIds();
        balances = new uint256[](attrIds.length);
        for(uint256 i = 0; i < attrIds.length; i++){
            balances[i] = balanceOf(tokenId, attrIds[i]);
        }
    }*/

    function getCharacterId(string memory name) public view returns (uint256) {
        return _characterName[name];
    }

    /*function getAttr(uint256 tokenId, uint256 attrId) public view returns (uint256, string memory) {
        require(_exists(tokenId), "Token not exist");
        return (balanceOf(tokenId, attrId), string(textOf(tokenId, attrId)));
    }*/

    /*function getBatchAttr(uint256 tokenId, uint256[] calldata attrIds) external view override returns (uint256[] memory) {
        require(_exists(tokenId), "Token not exist");
        return balanceOfBatch(tokenId, attrIds);
    }*/

    function getExtendAttr(uint256 tokenId, string memory key) external view returns (string memory) {
        require(_exists(tokenId), "Token not exist");
        return _extendAttr[tokenId][key];
    }

    function increaseAttr(uint256 tokenId, uint256 attrId, uint256 value) external onlyDirectory {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");
        character3664.attach(tokenId, attrId, value, bytes(""), false);
        if (attrId == uint256(CHARACTERATTR.CHARACTER_EXPERIENCE)) {
            _upLevel(tokenId);
        }
    }

    function decreaseAttr(uint256 tokenId, uint256 attrId, uint256 value) external onlyDirectory {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");
        character3664.burn(tokenId, attrId, value);
    }

    function setExtendAttr(uint256 tokenId, string memory key, string memory value) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");
        _extendAttr[tokenId][key] = value;
    }

    function assignPoints(uint256 tokenId, uint32 strength, uint32 DEXTERITY, uint32 intelligence, uint32 PATIENCE) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");

        uint256 totalPoints = uint256(strength) + uint256(DEXTERITY) + uint256(intelligence) + uint256(PATIENCE);
        uint256 currPoints = character3664.balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_POINTS));
        require(totalPoints <= currPoints, "Not enough points");

        character3664.burn(tokenId, uint256(CHARACTERATTR.CHARACTER_POINTS), totalPoints);
        character3664.attach(tokenId, uint256(CHARACTERATTR.CHARACTER_STRENGTH), strength, "", false);
        character3664.attach(tokenId, uint256(CHARACTERATTR.CHARACTER_DEXTERITY), DEXTERITY, "", false);
        character3664.attach(tokenId, uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), intelligence, "", false);
        character3664.attach(tokenId, uint256(CHARACTERATTR.CHARACTER_PATIENCE), PATIENCE, "", false);
    }

    // 考虑：需要核对场景
    function washPoints(uint256 tokenId) payable external nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");
        require(msg.value >= Genesis.WASH_POINTS_PRICE, "Payed too low value");
        Address.sendValue(Genesis.TREASURY, msg.value);

        uint256[] memory attrIds = new uint256[](7);
        {

            (attrIds[0],attrIds[1],attrIds[2]) 
            = 
            ( 
                uint256(CHARACTERATTR.CHARACTER_OCCUPATION),                                    
                uint256(CHARACTERATTR.CHARACTER_LEVEL), 
                uint256(CHARACTERATTR.CHARACTER_POINTS)                                   
            );
        }
        {

            (attrIds[3],attrIds[4],attrIds[5],attrIds[6]) 
            = 
            ( 
                uint256(CHARACTERATTR.CHARACTER_STRENGTH), 
                uint256(CHARACTERATTR.CHARACTER_DEXTERITY), 
                uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), 
                uint256(CHARACTERATTR.CHARACTER_PATIENCE)                                  
            );
        }
        bytes[] memory texts = new bytes[](7);

        uint256[] memory currValue = character3664.balanceOfBatch(tokenId, attrIds);
        character3664.burnBatch(tokenId, attrIds, currValue);

        currValue[2] = (currValue[1] - 1) * 5;  // CHARACTER_POINTS
        currValue[3] = 100;         // CHARACTER_STRENGTH
        currValue[4] = 100;         // CHARACTER_DEXTERITY
        currValue[5] = 100;         // CHARACTER_INTELLIGENCE
        currValue[6] = 100;         // CHARACTER_PATIENCE
        character3664.batchAttach(tokenId, attrIds, currValue, texts);
    }

    // function _initAttribute(uint256 tokenId, string memory name, uint256 occupation, ESEX sex) internal {
    //     uint256[] memory attrIds = [uint256(CHARACTERATTR.CHARACTER_NAME), uint256(CHARACTERATTR.CHARACTER_OCCUPATION), 
    //                                 uint256(CHARACTERATTR.CHARACTER_SEX), uint256(CHARACTERATTR.CHARACTER_LEVEL), 
    //                                 uint256(CHARACTERATTR.CHARACTER_EXPERIENCE), uint256(CHARACTERATTR.CHARACTER_POINTS), 
    //                                 uint256(CHARACTERATTR.CHARACTER_STRENGTH), uint256(CHARACTERATTR.CHARACTER_DEXTERITY), 
    //                                 uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), uint256(CHARACTERATTR.CHARACTER_PATIENCE), 
    //                                 uint256(CHARACTERATTR.CHARACTER_LUCK), uint256(CHARACTERATTR.CHARACTER_GOLD)];
        
    //     uint256[] memory amounts = [1, uint256(occupation), uint256(sex), 1, 0, 0, INIT_ATTR[uint256(occupation)][0], INIT_ATTR[occupation][1], INIT_ATTR[occupation][2], INIT_ATTR[occupation][3], 0, 0];
        
    //     bytes[] memory texts = [bytes(name), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes("")];
        
    //     //uint256[] memory attrIds = new uint256[](12);
    //     //uint256[] memory amounts = new uint256[](12);
    //     //bytes[] memory texts = new bytes[](12);
    //     _batchAttach(tokenId, _getInitAttributeAttrIds(), _getInitAttributeAmounts(occupation, sex), _getInitAttributeTexts(name));
    // }

    // function _getInitAttributeAttrIds() internal pure returns(uint256[] memory) {
    //     uint256[] memory attrIds = new uint256[](12);
    //     {
    //         (
    //             attrIds[0], attrIds[1], attrIds[2], attrIds[3], attrIds[4]
    //         ) = 
    //         (
    //             uint256(CHARACTERATTR.CHARACTER_NAME), uint256(CHARACTERATTR.CHARACTER_OCCUPATION), 
    //             uint256(CHARACTERATTR.CHARACTER_SEX), uint256(CHARACTERATTR.CHARACTER_LEVEL), 
    //             uint256(CHARACTERATTR.CHARACTER_EXPERIENCE)
    //         );
    //     }
    //     {
    //         (
    //             attrIds[5], attrIds[6], attrIds[7], attrIds[8], attrIds[9]
    //         ) = 
    //         (
    //             uint256(CHARACTERATTR.CHARACTER_POINTS), 
    //             uint256(CHARACTERATTR.CHARACTER_STRENGTH), uint256(CHARACTERATTR.CHARACTER_DEXTERITY), 
    //             uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), uint256(CHARACTERATTR.CHARACTER_PATIENCE)
    //         );
    //     }
    //     {
    //         (
    //             attrIds[10], attrIds[11]
    //         ) = 
    //         (
    //             uint256(CHARACTERATTR.CHARACTER_LUCK), uint256(CHARACTERATTR.CHARACTER_GOLD)
    //         );
    //     }
    //     return attrIds;
    // }

    // function _getInitAttributeAmounts(uint256 occupation, ESEX sex) internal pure returns(uint256[] memory) {
    //     uint256[] memory amounts = new uint256[](12);
    //     {
    //         (
    //             amounts[0], amounts[1], amounts[2], amounts[3], amounts[4]
    //         ) = 
    //         (
    //             1, uint256(occupation), uint256(sex), 1, 0
    //         );
    //     }
    //     {
    //         (
    //             amounts[5], amounts[6], amounts[7], amounts[8], amounts[9]
    //         ) = 
    //         (
    //             0, 100, 100, 100, 100
    //         );
    //     }
    //     {(
    //         amounts[10],amounts[11]
    //     ) = 
    //     (
    //         0, 0
    //     );}
    //     return amounts;
    // }

    // function _getInitAttributeTexts(string memory name) pure internal returns(bytes[] memory) {
    //     bytes[] memory texts = new bytes[](12);
    //     {(
    //         texts[0], texts[1], texts[2], texts[3], texts[4]
    //     ) = 
    //     (
    //         bytes(name), bytes(""), bytes(""), bytes(""), bytes("")
    //     );}
    //     {(
    //         texts[5], texts[6], texts[7], texts[8], texts[9]
    //     ) = 
    //     (
    //         bytes(""), bytes(""), bytes(""), bytes(""), bytes("")
    //     );}
    //     {(
    //         texts[10],texts[11]
    //     ) = 
    //     (
    //         bytes(""), bytes("")
    //     );}
    //     return texts;
    // }
    
    function _upLevel(uint256 tokenId) internal {
        while (true) {
            uint256 currExperience = character3664.balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_EXPERIENCE));
            uint256 currLevel = character3664.balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_LEVEL));
            uint256 upgradeExperience = 30 * currLevel ** 2 + 150 * currLevel - 80;

            if (currExperience < upgradeExperience) {
                break;
            }

            character3664.attach(tokenId, uint256(CHARACTERATTR.CHARACTER_LEVEL), 1, "", false);
            character3664.attach(tokenId, uint256(CHARACTERATTR.CHARACTER_POINTS), 5, "", false);
            character3664.burn(tokenId, uint256(CHARACTERATTR.CHARACTER_EXPERIENCE), upgradeExperience);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(operator != address(0), "invalid operator");
        require(from != address(0), "invalid from");
        require(tokenId != 0, "invalid tokenId");
        require(data.length != 0, "invalid data");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
