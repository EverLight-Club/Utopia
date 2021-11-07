// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC721/ERC721EnumerableUpgradeable.sol";
import "../../token/ERC3664Stand/ERC3664Upgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../interfaces/ICharacter.sol";
import "../../library/Genesis.sol";

contract Character is ICharacter, ERC3664Upgradeable, ERC721EnumerableUpgradeable, DirectoryBridge, ReentrancyGuard {
    
    uint256[4][3] public INIT_ATTR = [[100, 100, 100, 100], 
                                      [100, 100, 100, 100], 
                                      [100, 100, 100, 100]];
    
    mapping(string => uint256) _characterName;
    mapping(uint256 => mapping(string => string)) _extendAttr;
    
    function initialize() public initializer {
        //__ERC3664_init();
        __ERC721Enumerable_init("Utopia Character Token", "UCT");
        __DirectoryBridge_init();
        __Character_init_unchained();
    }

    function CharacterInit(uint256[] memory attrIds, string[] memory names, string[] memory symbols, string[] memory uris) external onlyOwner initializer {
        _mintBatch(attrIds, names, symbols, uris);
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
                                    uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), uint256(CHARACTERATTR.CHARACTER_CONSTITUTION), 
                                    uint256(CHARACTERATTR.CHARACTER_LUCK), uint256(CHARACTERATTR.CHARACTER_GOLD)];
        string[12] memory names = ["name", "occupation", "sex", "level", "experience", "points", "strength", "DEXTERITY", "intelligence", "CONSTITUTION", "luck", "gold"];
        string[12] memory symbols = ["NAME", "OCCUPATION", "SEX", "LEVEL", "EXPERIENCE", "POINTS", "STRENGTH", "DEXTERITY", "INTELLIGENCE", "CONSTITUTION", "LUCK", "GOLD"];
        string[12] memory uris = ["", "", "", "", "", "", "", "", "", "", "", ""];*/
        //_mintBatch(attrIds, names, symbols, uris);
    }

    function mintCharacter(address recipient, address recommender, uint256 tokenId, string memory name, EOCCUPATION occupation) external onlyDirectory {
        require(recipient != address(0), "recipient invalid");
        require(!_exists(tokenId), "tokenId already exists");
        require(getCharacterId(name) == 0, "Name already exist");

        _characterName[name] = tokenId;
        _safeMint(recipient, tokenId);
        
        _initAttribute(tokenId, name, occupation, ESEX.Neutral);
        emit NewCharacter(recipient, recommender, tokenId);
    }

    function attachLucklyPoint(uint256 tokenId, uint256 lucklyPoint) external onlyDirectory {
        require(_exists(tokenId), "Character: invalid characterId");
        require(lucklyPoint != 0, "Character: lucklyPoint is zero");
        require(_isApprovedOrOwner(tx.origin, tokenId), "Not owner or approver");
        _attach(tokenId, uint256(CHARACTERATTR.CHARACTER_LUCK), lucklyPoint, "", false);
    }

    function burnLucklyPoint(uint256 tokenId, uint256 lucklyPoint) external onlyDirectory {
        require(_exists(tokenId), "Character: invalid characterId");
        require(lucklyPoint != 0, "Character: lucklyPoint is zero");
        require(_isApprovedOrOwner(tx.origin, tokenId), "Not owner or approver");
        _burn(tokenId, uint256(CHARACTERATTR.CHARACTER_LUCK), lucklyPoint);
    }

    function getLucklyPoint(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Character: tokenId not exists");
        return balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_LUCK));
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) public view override returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory output) {

    }

    function getCharacterId(string memory name) public view returns (uint256) {
        return _characterName[name];
    }

    function getAttr(uint256 tokenId, uint256 attrId) public view returns (uint256, string memory) {
        require(_exists(tokenId), "Token not exist");
        return (balanceOf(tokenId, attrId), string(textOf(tokenId, attrId)));
    }

    function getBatchAttr(uint256 tokenId, uint256[] calldata attrIds) external view override returns (uint256[] memory) {
        require(_exists(tokenId), "Token not exist");
        return balanceOfBatch(tokenId, attrIds);
    }

    function getExtendAttr(uint256 tokenId, string memory key) external view returns (string memory) {
        require(_exists(tokenId), "Token not exist");
        return _extendAttr[tokenId][key];
    }

    function increaseAttr(uint256 tokenId, uint256 attrId, uint256 value) external onlyDirectory {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");
        _attach(tokenId, attrId, value, "", false);
        if (attrId == uint256(CHARACTERATTR.CHARACTER_EXPERIENCE)) {
            _upLevel(tokenId);
        }
    }

    function decreaseAttr(uint256 tokenId, uint256 attrId, uint256 value) external onlyDirectory {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");
        _burn(tokenId, attrId, value);
    }

    function setExtendAttr(uint256 tokenId, string memory key, string memory value) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");
        _extendAttr[tokenId][key] = value;
    }

    // 思考：考虑使用的场景
    function assignPoints(uint256 tokenId, uint32 strength, uint32 DEXTERITY, uint32 intelligence, uint32 CONSTITUTION) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");

        uint256 totalPoints = uint256(strength) + uint256(DEXTERITY) + uint256(intelligence) + uint256(CONSTITUTION);
        uint256 currPoints = balanceOf(tokenId, totalPoints);
        require(totalPoints <= currPoints, "Not enough points");

        _burn(tokenId, uint256(CHARACTERATTR.CHARACTER_POINTS), totalPoints);
        _attach(tokenId, uint256(CHARACTERATTR.CHARACTER_STRENGTH), strength, "", false);
        _attach(tokenId, uint256(CHARACTERATTR.CHARACTER_DEXTERITY), DEXTERITY, "", false);
        _attach(tokenId, uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), intelligence, "", false);
        _attach(tokenId, uint256(CHARACTERATTR.CHARACTER_CONSTITUTION), CONSTITUTION, "", false);
    }

    // 考虑：需要核对场景
    function washPoints(uint256 tokenId) payable external nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");
        require(msg.value >= Genesis.WASH_POINTS_PRICE, "Payed too low value");
        Address.sendValue(Genesis.TREASURY, msg.value);

        /*uint256[] memory attrIds = [uint256(CHARACTERATTR.CHARACTER_OCCUPATION), uint256(CHARACTERATTR.CHARACTER_LEVEL), 
                                    uint256(CHARACTERATTR.CHARACTER_POINTS), uint256(CHARACTERATTR.CHARACTER_STRENGTH), 
                                    uint256(CHARACTERATTR.CHARACTER_DEXTERITY), uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), 
                                    uint256(CHARACTERATTR.CHARACTER_CONSTITUTION)];
        bytes[] memory texts = ["", "", "", "", "", "", ""];

        uint256[] memory currValue = balanceOfBatch(tokenId, attrIds);*/
        uint256[] memory attrIds = new uint256[](4);
        bytes[] memory texts = new bytes[](4);

        //uint256[] memory currValue = balanceOfBatch(tokenId, attrIds);
        //_burnBatch(tokenId, attrIds, currValue);

        /*currValue[2] = (currValue[1] - 1) * 5;
        currValue[3] = INIT_ATTR[ currValue[0] ][0];
        currValue[4] = INIT_ATTR[ currValue[0] ][1];
        currValue[5] = INIT_ATTR[ currValue[0] ][2];
        currValue[6] = INIT_ATTR[ currValue[0] ][3];
        _batchAttach(tokenId, attrIds, currValue, texts);*/
    }

    function _initAttribute(uint256 tokenId, string memory name, EOCCUPATION occupation, ESEX sex) internal {
       /* uint256[] memory attrIds = [uint256(CHARACTERATTR.CHARACTER_NAME), uint256(CHARACTERATTR.CHARACTER_OCCUPATION), 
                                    uint256(CHARACTERATTR.CHARACTER_SEX), uint256(CHARACTERATTR.CHARACTER_LEVEL), 
                                    uint256(CHARACTERATTR.CHARACTER_EXPERIENCE), uint256(CHARACTERATTR.CHARACTER_POINTS), 
                                    uint256(CHARACTERATTR.CHARACTER_STRENGTH), uint256(CHARACTERATTR.CHARACTER_DEXTERITY), 
                                    uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), uint256(CHARACTERATTR.CHARACTER_CONSTITUTION), 
                                    uint256(CHARACTERATTR.CHARACTER_LUCK), uint256(CHARACTERATTR.CHARACTER_GOLD)];
        
        uint256[] memory amounts = [1, uint256(occupation), uint256(sex), 1, 0, 0, INIT_ATTR[uint256(occupation)][0], INIT_ATTR[occupation][1], INIT_ATTR[occupation][2], INIT_ATTR[occupation][3], 0, 0];
        
        bytes[] memory texts = [bytes(name), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes(""), bytes("")];
        */
        //uint256[] memory attrIds = new uint256[](12);
        //uint256[] memory amounts = new uint256[](12);
        //bytes[] memory texts = new bytes[](12);
        _batchAttach(tokenId, _getInitAttributeAttrIds(), _getInitAttributeAmounts(occupation, sex), _getInitAttributeTexts(name));
    }

    function _getInitAttributeAttrIds() internal returns(uint256[] memory) {
        uint256[] memory attrIds = new uint256[](12);
        {
            (
                attrIds[0], attrIds[1], attrIds[2], attrIds[3], attrIds[4]
            ) = 
            (
                uint256(CHARACTERATTR.CHARACTER_NAME), uint256(CHARACTERATTR.CHARACTER_OCCUPATION), 
                uint256(CHARACTERATTR.CHARACTER_SEX), uint256(CHARACTERATTR.CHARACTER_LEVEL), 
                uint256(CHARACTERATTR.CHARACTER_EXPERIENCE)
            );
        }
        {
            (
                attrIds[5], attrIds[6], attrIds[7], attrIds[8], attrIds[9]
            ) = 
            (
                uint256(CHARACTERATTR.CHARACTER_POINTS), 
                uint256(CHARACTERATTR.CHARACTER_STRENGTH), uint256(CHARACTERATTR.CHARACTER_DEXTERITY), 
                uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), uint256(CHARACTERATTR.CHARACTER_CONSTITUTION)
            );
        }
        {
            (
                attrIds[10], attrIds[11]
            ) = 
            (
                uint256(CHARACTERATTR.CHARACTER_LUCK), uint256(CHARACTERATTR.CHARACTER_GOLD)
            );
        }
        return attrIds;
    }

    function _getInitAttributeAmounts(EOCCUPATION occupation, ESEX sex) internal returns(uint256[] memory) {
        uint256[] memory amounts = new uint256[](12);
        {(
            amounts[0], amounts[1], amounts[2], amounts[3], amounts[4]
        ) = 
        (
            1, uint256(occupation), uint256(sex), 1, 0
        );}
        {(
            amounts[5], amounts[6], amounts[7], amounts[8], amounts[9]
        ) = 
        (
            0, INIT_ATTR[uint256(occupation)][0], INIT_ATTR[uint256(occupation)][1], INIT_ATTR[uint256(occupation)][2], INIT_ATTR[uint256(occupation)][3]
        );}
        {(
            amounts[10],amounts[11]
        ) = 
        (
            0, 0
        );}
        return amounts;
    }

    function _getInitAttributeTexts(string memory name) internal returns(bytes[] memory) {
        bytes[] memory texts = new bytes[](12);
        {(
            texts[0], texts[1], texts[2], texts[3], texts[4]
        ) = 
        (
            bytes(name), bytes(""), bytes(""), bytes(""), bytes("")
        );}
        {(
            texts[5], texts[6], texts[7], texts[8], texts[9]
        ) = 
        (
            bytes(""), bytes(""), bytes(""), bytes(""), bytes("")
        );}
        {(
            texts[10],texts[11]
        ) = 
        (
            bytes(""), bytes("")
        );}
        return texts;
    }
    
    function _upLevel(uint256 tokenId) internal {
        while (true) {
            uint256 currExperience = balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_EXPERIENCE));
            uint256 currLevel = balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_LEVEL));
            uint256 upgradeExperience = 30 * currLevel ** 2 + 150 * currLevel - 80;

            if (currExperience < upgradeExperience) {
                break;
            }

            _attach(tokenId, uint256(CHARACTERATTR.CHARACTER_LEVEL), 1, "", false);
            _attach(tokenId, uint256(CHARACTERATTR.CHARACTER_POINTS), 5, "", false);
            _burn(tokenId, uint256(CHARACTERATTR.CHARACTER_EXPERIENCE), upgradeExperience);
        }
    }
}
