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
		[230, 150, 70, 125],
		[10, 20, 30, 20],
		["Thunderbolt", "Flamethrower", "Hydro Pump", "Vine Whip"],
		[40, 20, 10, 20]
	);
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);

	let txn;
	// We only have three characters.
	// an NFT w/ the character at index 2 of our array.
	txn = await gameContract.mintCharacterNFT(2);
	await txn.wait();

	// Get the value of the NFT's URI.
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