// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

// Helper we wrote to encode in Base64
import "./libraries/Base64.sol";

// Our contract inherits from ERC721, which is the standard NFT contract!
contract MyEpicGame is ERC721, VRFConsumerBase {

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

	struct PokemonNFTAttributes {
    string name;
    string imageURI;        
    uint hp;
    uint maxHp;
    uint attackDamage;
		uint defense;
		string moveName;
		uint critChance;
		uint256 tokenId;
  }

	struct BigBossArguments {
		string name;
		string imageURI;
		uint hp;
		uint attackDamage;
		uint defense;
		string moveName;
		uint critChance;
	}

	struct BigBoss {
		string name;
		string imageURI;
		uint hp;
		uint maxHp;
		uint attackDamage;
		uint defense;
		string moveName;
		uint critChance;
	}

	BigBoss public bigBoss;

  // The tokenId is the NFTs unique identifier, it's just a number that goes
  // 0, 1, 2, 3, etc.
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // A lil array to help us hold the default data for our pokemon.
  // This will be helpful when we mint new characters and need to know the pokemon's stats
  CharacterAttributes[] defaultCharacters;

	// A mapping from the nft's tokenId => that NFTs attributes.
  mapping(uint256 => CharacterAttributes) public pokemonAttributes;

	// A mapping from an the NFTs tokenId => address. I can retrieve an owner based on a pokemon ID.
  mapping(uint256 => address) public pokemonToOwner;

	//stores the results of the random generator to the tokenid of the attacking pokemon
	mapping(bytes32 => uint256) private requestToPokemon;

	// A mapping from an the address => list of NFT tokenIds. I can retrieve which person owns which pokemon.
  mapping(address => uint256[]) public ownerToPokemons;

	//keyHash identifies the chainlink oracle we will get random numbers from
	//fee identifies the fee in LINK we will pay to the oracles
	bytes32 private keyHash;
	uint256 private fee;

	event AttackComplete(uint newBossHp, uint newPlayerHp, uint256 tokenId);
	event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
	event PokemonRevived(uint256 tokenId, uint newPokemonHealth);

  // Data passed in to the contract when it's first created initializing the characters.
  // We're going to actually pass these values in from from run.js.
  constructor(
    string[] memory characterNames,
    string[] memory characterImageURIs,
    uint[] memory characterHp,
    uint[] memory characterAttackDmg,
		uint[] memory characterDefense,
		string[] memory characterMoveName,
		uint[] memory characterCritChance,
		BigBossArguments memory bossData,
		address _vrfCoordinator,
		address _link,
		bytes32 _keyHash
  )
		ERC721("Pokemon", "POKEMON")
		VRFConsumerBase(_vrfCoordinator, _link)
  {
		bigBoss = BigBoss({
			name: bossData.name,
			imageURI: bossData.imageURI,
			hp: bossData.hp,
			maxHp: bossData.hp,
			attackDamage: bossData.attackDamage,
			defense: bossData.defense,
			moveName: bossData.moveName,
			critChance: bossData.critChance
		});

		console.log("Done initializing boss %s w/ HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);


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
		keyHash = _keyHash;
		fee = 0.1 * 10**18; // 0.1 LINK
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
    pokemonAttributes[newItemId] = CharacterAttributes({
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

		ownerToPokemons[msg.sender].push(newItemId);

    // Increment the tokenId for the next person that uses it.
    _tokenIds.increment();
		emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
	}

	function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
		uint256 d100Value = (randomness%100)+1;
    uint256 tokenId = requestToPokemon[requestId];
		attackBossV2(tokenId, d100Value);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		CharacterAttributes memory charAttributes = pokemonAttributes[_tokenId];

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

	function attackBoss(uint256 _tokenId) public {
		address owner = pokemonToOwner[_tokenId];
		require(msg.sender == owner);
		CharacterAttributes storage pokemon = pokemonAttributes[_tokenId];
		console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", pokemon.name, pokemon.hp, pokemon.attackDamage);
		console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);
		require (pokemon.hp > 0, "Error: pokemon is out of HP");
		require (bigBoss.hp > 0, "Error: Mewtwo is out of HP");

		if (bigBoss.hp < pokemon.attackDamage) {
			bigBoss.hp = 0;
		} else {
			bigBoss.hp = bigBoss.hp - pokemon.attackDamage;
		}

		if (pokemon.hp < bigBoss.attackDamage) {
			pokemon.hp = 0;
		} else {
			pokemon.hp = pokemon.hp - bigBoss.attackDamage;
		}

		console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);
  	console.log("Boss attacked player's pokemon. New pokemon hp: %s\n", pokemon.hp);
		emit AttackComplete(bigBoss.hp, pokemon.hp, _tokenId);
	}

		function attackBossV2(uint256 _tokenId, uint256 _randomness) public {
		address owner = pokemonToOwner[_tokenId];
		require(msg.sender == owner);
		CharacterAttributes storage pokemon = pokemonAttributes[_tokenId];
		console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", pokemon.name, pokemon.hp, pokemon.attackDamage);
		console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);
		require (pokemon.hp > 0, "Error: pokemon is out of HP");
		require (bigBoss.hp > 0, "Error: Mewtwo is out of HP");

		if (bigBoss.hp < pokemon.attackDamage) {
			bigBoss.hp = 0;
		} else {
			bigBoss.hp = bigBoss.hp - pokemon.attackDamage;
		}

		if (pokemon.hp < bigBoss.attackDamage) {
			pokemon.hp = 0;
		} else {
			pokemon.hp = pokemon.hp - bigBoss.attackDamage;
		}

		if (_randomness <= pokemon.critChance) {
			console.log("CRITICAL HIT for ", pokemon.name, " for",  pokemon.attackDamage);
		}

		console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);
  	console.log("Boss attacked player's pokemon. New pokemon hp: %s\n", pokemon.hp);
		emit AttackComplete(bigBoss.hp, pokemon.hp, _tokenId);
	}

	function revivePokemon(uint256 _tokenId) public {
		address owner = pokemonToOwner[_tokenId];
		require(msg.sender == owner);
		CharacterAttributes storage pokemon = pokemonAttributes[_tokenId];
		require (pokemon.hp == 0, "Error: pokemon is out of HP");

		pokemon.hp = pokemon.maxHp;

		console.log("Player revived ", pokemon.name);
		emit PokemonRevived(pokemon.hp, _tokenId);
	}

	function checkIfUserHasNFTs() public view returns (PokemonNFTAttributes[] memory) {
		uint256[] memory tokenIds = ownerToPokemons[msg.sender];
		PokemonNFTAttributes[] memory pokemon = new PokemonNFTAttributes[](tokenIds.length);
		for(uint i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			CharacterAttributes memory charAtr = pokemonAttributes[tokenId];
			PokemonNFTAttributes memory pokemonNFTAttributes = PokemonNFTAttributes(charAtr.name, charAtr.imageURI,
				charAtr.hp, charAtr.maxHp, charAtr.attackDamage, charAtr.defense, charAtr.moveName, charAtr.critChance, tokenId
			);
			pokemon[i] = pokemonNFTAttributes;
		}
		return pokemon;
	}

	function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
		return defaultCharacters;
	}

	function getBigBoss() public view returns (BigBoss memory) {
		return bigBoss;
	}
}