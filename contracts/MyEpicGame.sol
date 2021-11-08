// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

// Helper we wrote to encode in Base64
import "./libraries/Base64.sol";

// Our contract inherits from ERC721, which is the standard NFT contract!
contract MyEpicGame is ERC721 {
  // We'll hold our character's attributes in a struct. Feel free to add
  // whatever you'd like as an attribute! (ex. defense, crit chance, etc).
  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string imageURI;        
    uint hp;
    uint maxHp;
    uint attackDamage;
		uint defense;
		string moveName;
		uint critChance;
  }

  // The tokenId is the NFTs unique identifier, it's just a number that goes
  // 0, 1, 2, 3, etc.
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // A lil array to help us hold the default data for our characters.
  // This will be helpful when we mint new characters and need to know
  // things like their HP, AD, etc.
  CharacterAttributes[] defaultCharacters;

	// We create a mapping from the nft's tokenId => that NFTs attributes.
  mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

	// A mapping from an the NFTs tokenId => address. I can retrieve an owner based on a pokemon ID.
  mapping(uint256 => address) public pokemonToOwner;

	// A mapping from an the address => list of NFT tokenIds. I can retrieve which person owns which pokemon.
  mapping(address => uint256[]) public ownerToPokemons;

  // Data passed in to the contract when it's first created initializing the characters.
  // We're going to actually pass these values in from from run.js.
  constructor(
    string[] memory characterNames,
    string[] memory characterImageURIs,
    uint[] memory characterHp,
    uint[] memory characterAttackDmg,
		uint[] memory characterDefense,
		string[] memory characterMoveName,
		uint[] memory characterCritChance
  )
		ERC721("Pokemon", "POKEMON")
  {
    // Loop through all the characters, and save their values in our contract so
    // we can use them later when we mint our NFTs.
    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i,
        name: characterNames[i],
        imageURI: characterImageURIs[i],
        hp: characterHp[i],
        maxHp: characterHp[i],
        attackDamage: characterAttackDmg[i],
				defense: characterDefense[i],
				moveName: characterMoveName[i],
				critChance: characterCritChance[i]
      }));

      CharacterAttributes memory c = defaultCharacters[i];
      console.log("Done initializing %s w/ HP %s, img %s", c.name, c.hp, c.imageURI);
      console.log("and , move name %s, attack damage %s", c.moveName, c.attackDamage);
    }
		// I increment tokenIds here so that my first NFT has an ID of 1.
		_tokenIds.increment();
  }

  // Users would be able to hit this function and get their NFT based on the
  // characterId they send in!
	function mintCharacterNFT(uint _characterIndex) external {
		// Get current tokenId (starts at 1 since we incremented in the constructor).
    uint256 newItemId = _tokenIds.current();

    // The magical function! Assigns the tokenId to the caller's wallet address.
    _safeMint(msg.sender, newItemId);

    // We map the tokenId => their character attributes. More on this in
    // the lesson below.
    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      hp: defaultCharacters[_characterIndex].hp,
      maxHp: defaultCharacters[_characterIndex].hp,
      attackDamage: defaultCharacters[_characterIndex].attackDamage,
			defense: defaultCharacters[_characterIndex].defense,
			moveName: defaultCharacters[_characterIndex].moveName,
			critChance: defaultCharacters[_characterIndex].critChance
    });

    console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);
    
    // Keep an easy way to see who owns what NFT.
    pokemonToOwner[newItemId] = msg.sender;

    // Increment the tokenId for the next person that uses it.
    _tokenIds.increment();
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

		string memory strHp = Strings.toString(charAttributes.hp);
		string memory strMaxHp = Strings.toString(charAttributes.maxHp);
		string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);
		string memory strDefense = Strings.toString(charAttributes.defense);
		string memory strCritChance = Strings.toString(charAttributes.critChance);


		string memory json = Base64.encode(
			bytes(
				string(
					abi.encodePacked(
						'{"name": "', charAttributes.name,
						' -- NFT #: ', Strings.toString(_tokenId),
						'", "description": "This is an NFT that lets people play in the game Pokemon: Revenge of Mewtwo!", "image": "',
						charAttributes.imageURI,
						'", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
						strAttackDamage,'}, { "trait_type": "Defense", "value": ', 
						strDefense,'}, { "trait_type": "Move Name", "value": "', 
						charAttributes.moveName,'"}, { "trait_type": "Critical Chance", "value": ', strCritChance, '}]}'
					)
				)
			)
		);

		string memory output = string(
			abi.encodePacked("data:application/json;base64,", json)
		);
		
		return output;
	}
}