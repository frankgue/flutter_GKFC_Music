import 'dart:async';
import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayer2/audioplayer2.dart';
import 'package:volume/volume.dart';

import 'models/music.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'GKFC Music'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Musique> musicList = [
    new Musique(
        titre: "Grave",
        auteur: "Eddy depatro",
        imageUrl: "assets/cv_photo.png",
        musicUrl: "https://www.matieuio.fr/tutoriels/musiques/grave.mp3"),
    new Musique(
        titre: "Nuvole Biance",
        auteur: "Ludovic Berti",
        imageUrl: "assets/gkfc_background.png",
        musicUrl:
            "https://www.matieuio.fr/tutoriels/musiques/nuvole_bianche.mp3"),
    new Musique(
        titre: "These Days",
        auteur: "Rudimental",
        imageUrl: "assets/noir_blanc.png",
        musicUrl: "https://www.matieuio.fr/tutoriels/musiques/these_days.mp3"),
  ];

  AudioPlayer audioPlayer;
  StreamSubscription positionSubscription;
  StreamSubscription stateSubscription;

  Musique actualMusic;
  Duration position = new Duration(seconds: 0);
  Duration duree = new Duration(seconds: 30);
  PlayerState statut = PlayerState.STOPPED;

  int index = 1;
  bool mute = false;
  int maxVol = 0, currentVol = 0;

  @override
  void initState() {
    super.initState();
    actualMusic = musicList[index];
    confidAudioPlayer();
    initPlatformState();
    updateVolume();
  }

  @override
  Widget build(BuildContext context) {

    double largeur = MediaQuery.of(context).size.width;
    int newVol = getVolumePourcentage().toInt();

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.title),
          elevation: 20.0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 200,
                margin: EdgeInsets.only(top: 20.0),
                color: Colors.red,
                child: Image.asset(actualMusic.imageUrl),
              ),
              Container(
                margin: EdgeInsets.only(top: 20.0),
                child: Text(
                  actualMusic.titre,
                  textScaleFactor: 2,
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 5.0),
                child: Text(
                  actualMusic.auteur,
                  textScaleFactor: 2,
                ),
              ),
              Container(
                height: largeur/5,
                margin: EdgeInsets.only(left: 10.0, right: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.fast_rewind),
                      onPressed: rewind,
                    ),
                    IconButton(
                      icon: (statut != PlayerState.PLAYING) ? Icon(Icons.play_arrow) : Icon(Icons.pause),
                      onPressed: (statut != PlayerState.PLAYING) ? play : pause,
                      iconSize: 50.0,
                    ),
                    IconButton(
                      icon: (mute) ? Icon(Icons.headset_off) : Icon(Icons.headset),
                      onPressed: muted,
                    ),
                    IconButton(
                      icon: Icon(Icons.fast_forward),
                      onPressed: forward,
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 10.0, right: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    textWithStyle(fromDuration(position), 0.8),
                    textWithStyle(fromDuration(duree), 0.8),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 10.0, right: 10.0),
                child: Slider(
                  value: position.inSeconds.toDouble(),
                  min: 0.0,
                  max: duree.inSeconds.toDouble(),
                  inactiveColor: Colors.grey[500],
                  activeColor: Colors.deepPurpleAccent,
                  onChanged: (double d){
                    setState(() {
                      audioPlayer.seek(d);
                    });
                  },
                ),
              ),
              Container(
                height: largeur/5,
                margin: EdgeInsets.only(left: 5.0, right: 5.0, top: 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.remove),
                      iconSize: 18,
                      onPressed: () {
                        if(!mute){
                         setVol(currentVol);
                         updateVolume();
                        }
                      },
                    ),
                    Slider(
                      value: (mute) ? 0.0 : currentVol.toDouble(),
                      min: 0.0,
                      max: maxVol.toDouble(),
                      inactiveColor: (mute) ? Colors.red : Colors.grey[500],
                      activeColor: (mute) ? Colors.red : Colors.blue,
                      onChanged: (double d){
                        setState(() {
                          if(!mute){
                            setVol(d.toInt());
                            updateVolume();
                          }
                        });
                      },
                    ),
                    Text(
                        (mute) ? "Mute " : '$newVol.%'
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      iconSize: 18,
                      onPressed: () {
                        if(!mute){
                          setVol(maxVol);
                          updateVolume();
                        }
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ));
  }

  double getVolumePourcentage() {
    return (currentVol / maxVol) * 100;
  }

  ///Initialiser le volume
  Future<void> initPlatformState() async {
    await Volume.controlVolume(AudioManager.STREAM_MUSIC);
  }

  ///Update le volume
  updateVolume() async {
    maxVol = await Volume.getMaxVol;
    currentVol = await Volume.getVol;
    setState(() {});
  }

  ///Definir le volume
  setVol(int i) async {
    await Volume.setVol(i);
  }

  ///Gestion des text avec Style
  Text textWithStyle(String data, double scale) {
    return new Text(
      data,
      textScaleFactor: scale,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.black, fontSize: 15.0),
    );
  }

  ///Gestion des boutons
  IconButton bouton(IconData icon, double taille, ActionMusic action) {
    return new IconButton(
      icon: new Icon(icon),
      iconSize: taille,
      color: Colors.white,
      onPressed: () {
        switch (action) {
          case ActionMusic.PLAY:
            play();
            break;
          case ActionMusic.PAUSE:
            pause();
            break;
          case ActionMusic.REWIND:
            rewind();
            break;
          case ActionMusic.FORWARD:
            forward();
            break;
          default:
            break;
        }
      },
    );
  }

  ///Configuration de l'audioPlayer
  void confidAudioPlayer() {
    audioPlayer = new AudioPlayer();
    positionSubscription = audioPlayer.onAudioPositionChanged.listen((pos) {
      setState(() {
        position = pos;
      });
      if (position >= duree) {
        position = new Duration(seconds: 0);
        //Passer a la musique suivante
      }
    });
    stateSubscription = audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == AudioPlayerState.PLAYING) {
        setState(() {
          duree = audioPlayer.duration;
        });
      } else if (state == AudioPlayerState.STOPPED) {
        setState(() {
          statut = PlayerState.STOPPED;
        });
      }
    }, onError: (message) {
      print(message);
      setState(() {
        statut = PlayerState.STOPPED;
        duree = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    });
  }

  Future play() async {
    await audioPlayer.play(actualMusic.musicUrl);
    setState(() {
      statut = PlayerState.PLAYING;
    });
  }

  Future pause() async {
    await audioPlayer.pause();
    setState(() {
      statut = PlayerState.PAUSED;
    });
  }

  Future muted() async {
    await audioPlayer.mute(!mute);
    setState(() {
      mute = !mute;
    });
  }

  /// Passer a la musique suivante

  void forward() {
    if (index == musicList.length - 1) {
      index = 0;
    } else {
      index++;
    }
    actualMusic = musicList[index];
    audioPlayer.stop();
    confidAudioPlayer();
    play();
  }

  /// Retour a la musique précedente

  void rewind() {
    if (position > Duration(seconds: 3)) {
      audioPlayer.seek(0.0);
    } else {
      if (index == 0) {
        index = musicList.length - 1;
      } else {
        index--;
      }
    }
    actualMusic = musicList[index];
    audioPlayer.stop();
    confidAudioPlayer();
    play();
  }

  String fromDuration(Duration duration) {
    return duree.toString().split('.').first;
  }
}

enum ActionMusic { PLAY, PAUSE, REWIND, FORWARD }

enum PlayerState {
  PLAYING,
  STOPPED,
  PAUSED,
}
