import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(FluteMusicPlayer());
}

class FluteMusicPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  List<Map<String, String>> songs = [
    {'title': 'Ya Ali - DJMaza.Com', 'artist': 'Zubeen'},
    {'title': 'Ek Do Teen - DJMaza.Info', 'artist': 'Parry G, Shreya Ghoshal'},
    {'title': '16 yeh dil diwana hai', 'artist': ''},
    {'title': '20 Chala bhi aa o jaane wale', 'artist': ''},
    {'title': '09 jhil mil sitaron ka', 'artist': ''},
    {'title': '04 ek daal pe tota bole', 'artist': ''},
    {'title': '22 Saathiya nahin jana', 'artist': ''},
    {'title': '23 mujhe teri mohabbat ka', 'artist': ''},
    {'title': '07 Yeh dil tum bin', 'artist': ''},
    {'title': '08 Ye parbaton ke', 'artist': ''},
  ];

  int? playingIndex;


  void shuffleSongs() {
    setState(() {
      songs.shuffle(Random());
    });
  }

  void togglePlayPause(int index) {
    setState(() {
      if (playingIndex == index) {
        playingIndex = null;
      } else {
        playingIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flute Music Player'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          bool isPlaying = playingIndex == index;
          return ListTile(
            leading: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: isPlaying ? Colors.red : Colors.green,
              ),
              onPressed: () {
                togglePlayPause(index);
              },
            ),
            title: Text(songs[index]['title']!),
            subtitle: Text(songs[index]['artist']!),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: shuffleSongs,
        backgroundColor: Colors.purple,
        child: Icon(Icons.shuffle),
      ),
    );
  }
}
