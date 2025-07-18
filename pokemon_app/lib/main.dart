import 'package:flutter/material.dart';

void main() {
  runApp(PokemonApp());
}

class Pokemon {
  final String name;
  final String imageUrl;
  final double height;
  final double weight;
  final List<String> types;
  final List<String> weaknesses;
  final String nextEvolution;

  Pokemon({
    required this.name,
    required this.imageUrl,
    required this.height,
    required this.weight,
    required this.types,
    required this.weaknesses,
    required this.nextEvolution,
  });
}

class PokemonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Poke App',
      theme: ThemeData(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: PokemonListScreen(),
    );
  }
}

class PokemonListScreen extends StatelessWidget {
  final List<Pokemon> pokemonList = [
    Pokemon(
      name: 'Bulbasaur',
      imageUrl: 'assets/bulbasaur.png', // Local asset
      height: 0.7,
      weight: 6.9,
      types: ['Grass', 'Poison'],
      weaknesses: ['Fire', 'Flying', 'Ice', 'Psychic'],
      nextEvolution: 'Ivysaur',
    ),
    Pokemon(
      name: 'Ivysaur',
      imageUrl: 'assets/ivysaur.png', // Local asset
      height: 0.99,
      weight: 13.0,
      types: ['Grass', 'Poison'],
      weaknesses: ['Fire', 'Flying', 'Ice', 'Psychic'],
      nextEvolution: 'Venusaur',
    ),
    Pokemon(
      name: 'Charmander',
      imageUrl: 'assets/charmander.png', // Local asset
      height: 0.6,
      weight: 8.5,
      types: ['Fire'],
      weaknesses: ['Water', 'Ground', 'Rock'],
      nextEvolution: 'Charmeleon',
    ),
    Pokemon(
      name: 'Charmeleon',
      imageUrl: 'assets/charmeleon.png', // Local asset
      height: 1.1,
      weight: 19.0,
      types: ['Fire'],
      weaknesses: ['Water', 'Ground', 'Rock'],
      nextEvolution: 'Charizard',
    ),
    Pokemon(
      name: 'Charizard',
      imageUrl: 'assets/charizard.png', // Local asset
      height: 1.7,
      weight: 90.5,
      types: ['Fire', 'Flying'],
      weaknesses: ['Water', 'Electric', 'Rock'],
      nextEvolution: 'None',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Poke App'),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(10.0),
        itemCount: pokemonList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        itemBuilder: (context, index) {
          final pokemon = pokemonList[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PokemonDetailScreen(pokemon: pokemon),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    pokemon.imageUrl, // Use Image.asset for local assets
                    height: 80,
                    width: 80,
                  ),
                  SizedBox(height: 10),
                  Text(
                    pokemon.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PokemonDetailScreen extends StatelessWidget {
  final Pokemon pokemon;

  PokemonDetailScreen({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pokemon.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                pokemon.imageUrl, // Use Image.asset for local assets
                height: 150,
                width: 150,
              ),
            ),
            SizedBox(height: 20),
            Text(
              pokemon.name,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Height: ${pokemon.height} m'),
            Text('Weight: ${pokemon.weight} kg'),
            SizedBox(height: 10),
            Text('Types:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: pokemon.types.map((type) => TypeChip(type: type)).toList(),
            ),
            SizedBox(height: 10),
            Text('Weakness:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.0,
              children: pokemon.weaknesses.map((weakness) => WeaknessChip(weakness: weakness)).toList(),
            ),
            SizedBox(height: 20),
            Text('Next Evolution:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(pokemon.nextEvolution),
          ],
        ),
      ),
    );
  }
}

class TypeChip extends StatelessWidget {
  final String type;
  final Map<String, Color> typeColors = {
    'Grass': Colors.green,
    'Poison': Colors.purple,
    'Fire': Colors.red,
    'Flying': Colors.blue,
    'Ice': Colors.lightBlue,
    'Psychic': Colors.pink,
    'Water': Colors.blue,
    'Ground': Colors.brown,
    'Rock': Colors.grey,
  };

  TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(type),
      backgroundColor: typeColors[type] ?? Colors.grey,
    );
  }
}

class WeaknessChip extends StatelessWidget {
  final String weakness;

  WeaknessChip({required this.weakness});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(weakness),
      backgroundColor: Colors.redAccent,
    );
  }
}
