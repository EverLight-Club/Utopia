// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC721/ERC721EnumerableUpgradeable.sol";
import "../../token/ERC3664/ERC3664Upgradeable.sol";
import "../Directory/DirectoryBridge.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../interfaces/ICharacter.sol";
import "../../library/Genesis.sol";

contract Character is ERC3664Upgradeable, ERC721EnumerableUpgradeable, ICharacter, DirectoryBridge, ReentrancyGuard {
	
    mapping(string => uint256) _characterName;
    mapping(uint256 => mapping(string => string)) _extendAttr;
    uint256 _totalToken;

    function initialize() public initializer {
        __ERC3664_init_unchained();
        __ERC721Enumerable_init_unchained("Utopia Character Token", "UCT");
        __DirectoryBridge_init();
        __Character_init_unchained();
	}

    function __Character_init_unchained() internal initializer {
        uint256[] memory attrIds = [uint256(CHARACTERATTR.CHARACTER_NAME), uint256(CHARACTERATTR.CHARACTER_OCCUPATION), 
                                    uint256(CHARACTERATTR.CHARACTER_SEX), uint256(CHARACTERATTR.CHARACTER_LEVEL), 
                                    uint256(CHARACTERATTR.CHARACTER_EXPERIENCE), uint256(CHARACTERATTR.CHARACTER_POINTS), 
                                    uint256(CHARACTERATTR.CHARACTER_STRENGTH), uint256(CHARACTERATTR.CHARACTER_DEXTERITY), 
                                    uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), uint256(CHARACTERATTR.CHARACTER_CONSTITUTION), 
                                    uint256(CHARACTERATTR.CHARACTER_LUCK), uint256(CHARACTERATTR.CHARACTER_GOLD)];
        string[] memory names = ["name", "occupation", "sex", "level", "experience", "points", "strength", "DEXTERITY", "intelligence", "CONSTITUTION", "luck", "gold"];
        string[] memory symbols = ["NAME", "OCCUPATION", "SEX", "LEVEL", "EXPERIENCE", "POINTS", "STRENGTH", "DEXTERITY", "INTELLIGENCE", "CONSTITUTION", "LUCK", "GOLD"];
        string[] memory uris = ["", "", "", "", "", "", "", "", "", "", "", ""];
        _mintBatch(attrIds, names, symbols, uris);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) external view virtual returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function getCharacterId(string memory name) external view override returns (uint256) {
        return _characterName[name];
    }

    function getCharacters(address owner) external view override returns (uint256[] memory) {
        if (owner == address(0)) {
            owner = _msgSender();
        }
        
        uint256 balance = balanceOf(owner);
        uint256[] result = new uint256[](balance);

        for (uint256 i=0; i<balance; ++i) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }

        return result;
    }

    function getAttr(uint256 tokenId, uint256 attrId) external view override returns (uint256, string memory) {
        require(_exists(tokenId), "Token not exist");
        return (balanceOf(tokenId, attrId), string(textOf(tokenId, attrId)));
    }

    function getBatchAttr(uint256 tokenId, uint256[] memory attrId) external view override returns (uint256[] memory) {
        require(_exists(tokenId), "Token not exist");
        return balanceOfBatch(tokenId, attrIds);
    }

    function getExtendAttr(uint256 tokenId, string memory key) external view override returns (string memory) {
        require(_exists(tokenId), "Token not exist");
        return _extendAttr[tokenId][key];
    }

    function claim(string memory name, EOCCUPATION occupation /* 职业 */, ESEX sex, address recommender) external payable nonReentrant {
        require(msg.value >= Genesis.MINT_PRICE, "Payed too low value");
        require(getCharacterId(name) == 0, "Name already exist");

        if (recommender != address(0)) {
            uint256 reward = msg.value * Genesis.RECOMMENDER_REWARD / 100;
            Address.sendValue(payable(recommender), reward);
            Address.sendValue(Genesis.TREASURY, msg.value - reward);
        } else {
            Address.sendValue(Genesis.TREASURY, msg.value);
        }
        
        uint256 tokenId = ++_totalToken;
        _characterName[name] = tokenId;
        _safeMint(_msgSender(), tokenId);
        _initAttribute(tokenId, name, occupation, sex);

        emit NewCharacter(_msgSender(), recommender, tokenId);
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

    function assignPoints(uint256 tokenId, uint32 strength, uint32 DEXTERITY, uint32 intelligence, uint32 CONSTITUTION) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");

        uint256 totalPoints = uint256(strength) + uint256(DEXTERITY) + uint256(intelligence) + uint256(CONSTITUTION);
        uint256 currPoints = balanceOf(tokenId, POINTS);
        require(totalPoints <= currPoints, "Not enough points");

        _burn(tokenId, uint256(CHARACTERATTR.CHARACTER_POINTS), totalPoints);
        _attach(tokenId, uint256(CHARACTERATTR.CHARACTER_STRENGTH), strength, "", false);
        _attach(tokenId, uint256(CHARACTERATTR.CHARACTER_DEXTERITY), DEXTERITY, "", false);
        _attach(tokenId, uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), intelligence, "", false);
        _attach(tokenId, uint256(CHARACTERATTR.CHARACTER_CONSTITUTION), CONSTITUTION, "", false);
    }

    function washPoints(uint256 tokenId) payable external nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approver");
        require(msg.value >= Genesis.WASH_POINTS_PRICE, "Payed too low value");
        Address.sendValue(Genesis.TREASURY, msg.value);

        uint256[] memory attrIds = [uint256(CHARACTERATTR.CHARACTER_OCCUPATION), uint256(CHARACTERATTR.CHARACTER_LEVEL), 
                                    uint256(CHARACTERATTR.CHARACTER_POINTS), uint256(CHARACTERATTR.CHARACTER_STRENGTH), 
                                    uint256(CHARACTERATTR.CHARACTER_DEXTERITY), uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), 
                                    uint256(CHARACTERATTR.CHARACTER_CONSTITUTION)];
        bytes[] memory texts = ["", "", "", "", "", "", ""];

        uint256[] memory currValue = balanceOfBatch(tokenId, attrIds);
        _burnBatch(tokenId, attrIds, currValue);

        currValue[2] = (currValue[1] - 1) * 5;
        currValue[3] = INIT_ATTR[ currValue[0] ][0];
        currValue[4] = INIT_ATTR[ currValue[0] ][1];
        currValue[5] = INIT_ATTR[ currValue[0] ][2];
        currValue[6] = INIT_ATTR[ currValue[0] ][3];
        _batchAttach(tokenId, attrIds, currValue, texts);
    }

    function _initAttribute(uint256 tokenId, string memory name, EOCCUPATION occupation, ESEX sex) internal {
        uint256[] memory attrIds = [uint256(CHARACTERATTR.CHARACTER_NAME), uint256(CHARACTERATTR.CHARACTER_OCCUPATION), 
                                    uint256(CHARACTERATTR.CHARACTER_SEX), uint256(CHARACTERATTR.CHARACTER_LEVEL), 
                                    uint256(CHARACTERATTR.CHARACTER_EXPERIENCE), uint256(CHARACTERATTR.CHARACTER_POINTS), 
                                    uint256(CHARACTERATTR.CHARACTER_STRENGTH), uint256(CHARACTERATTR.CHARACTER_DEXTERITY), 
                                    uint256(CHARACTERATTR.CHARACTER_INTELLIGENCE), uint256(CHARACTERATTR.CHARACTER_CONSTITUTION), 
                                    uint256(CHARACTERATTR.CHARACTER_LUCK), uint256(CHARACTERATTR.CHARACTER_GOLD)];
        uint256[] memory amounts = [1, uint256(occupation), uint256(sex), 1, 0, 0, INIT_ATTR[occupation][0], INIT_ATTR[occupation][1], INIT_ATTR[occupation][2], INIT_ATTR[occupation][3], 0, 0];
        bytes[] memory texts = [bytes(name), "", "", "", "", "", "", "", "", "", "", ""];

        _batchAttach(tokenId, attrIds, amounts, texts);
    }

    function _upLevel(uint256 tokenId) internal {
        while (true) {
            uint256 currExperience = balanceOf(tokenId, uint256(CHARACTERATTR.CHARACTER_EXPERIENCE));
            uint256 currLevel = balanceOf(tokenId, LEVEL);
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
