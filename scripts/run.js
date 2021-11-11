const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
  const gameContract = await gameContractFactory.deploy(
		["Pikachu", "Charizard", "Blastoise", "Venusaur"],
		[
			"https://img.pokemondb.net/artwork/large/pikachu.jpg", 
			"https://img.pokemondb.net/artwork/large/charizard.jpg", 
			"https://img.pokemondb.net/artwork/large/blastoise.jpg", 
			"https://img.pokemondb.net/artwork/large/venusaur.jpg"
		],
		[85, 125, 200, 150],
		[63, 43, 30, 40],
		[10, 20, 30, 20],
		["Thunderbolt", "Flamethrower", "Hydro Pump", "Vine Whip"],
		[40, 20, 10, 20],
		{
			name: "Mewtwo",
			imageURI: "https://img.pokemondb.net/artwork/large/mewtwo.jpg",
			hp: 300,
			attackDamage: 100,
			defense: 20,
			moveName: "Psychic",
			critChance: 10
		}
	);
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);

	let txn;

	txn = await gameContract.mintCharacterNFT(2);
	await txn.wait();

	txn = await gameContract.attackBoss();
	await txn.wait();

	txn = await gameContract.attackBoss();
	await txn.wait();

	let returnedTokenUri = await gameContract.tokenURI(1);
	console.log("Token URI:", returnedTokenUri);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();