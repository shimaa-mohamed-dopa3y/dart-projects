import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Set the theme's primary color to blue
      ),
      debugShowCheckedModeBanner: false,

      home: StartupNameGenerator(),
    );
  }
}

class StartupNameGenerator extends StatelessWidget {
  final List<String> startupNames = List.generate(50, (index) => 'StartupName $index');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Startup Name Generator'),
        backgroundColor: Colors.blue, // Set app bar color to blue
      ),

      body: ListView.separated(
        itemCount: startupNames.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(startupNames[index]),
          );
        },
        separatorBuilder: (context, index) => Divider( // Add a divider between items
          color: Colors.grey,  // Divider color
          thickness: 1,  // Divider thickness
        ),
      ),

    );
  }
}
