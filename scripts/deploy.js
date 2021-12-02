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
		[40, 20, 100, 20],
		{
			name: "Mewtwo",
			imageURI: "https://img.pokemondb.net/artwork/large/mewtwo.jpg",
			hp: 300,
			attackDamage: 100,
			defense: 20,
			moveName: "Psychic",
			critChance: 10
		},
		"0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B",
		"0x01BE23585060835E02B77ef475b0Cc51aA1e0709",
		"0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311"
	);
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);
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