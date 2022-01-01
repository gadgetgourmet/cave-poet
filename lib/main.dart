import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Card {
  String easyword = "";
  String hardword = "";
  bool used = false;

  Card(this.easyword, this.hardword);
}

// final cards = [
//   Card("Turtle", "Turtle Soup"),
//   Card("Roll", "Rock 'n' Roll"),
//   Card("Kill", "Roadkill"),
//   Card("Neck", "Necktie"),
//   Card("Lip", "Lipstick"),
//   Card("Watch", "Pocket Watch")
// ];

var cards = <Card>[];

int numTeams = 2;
List<int> teamScores = [0, 0, 0];
List<String> teamNames = ["GRUNTs: ", "UGHs: ", "BONKs: "];
List<String> teamStrings = ["", "", ""];
int currentTeam = 0;
int currentCard = 0;

updateTeamStrings() {
  for (var i = 0; i < numTeams; i++) {
    teamStrings[i] = teamNames[i] + teamScores[i].toString();
  }
}

const int maxSeconds = 60;
int secondsRemaining = maxSeconds;

AudioCache audioplayer = AudioCache();

void main() {
  runApp(const MyApp());
}

// set up cards
loadCards() async {
  final rawCardData = await rootBundle.loadString('assets/wordlist.csv');
  // debugPrint(rawCardData);
  List<List<dynamic>> csvData = const CsvToListConverter().convert(rawCardData);
  csvData.forEach((element) {
    cards.add(Card(element[0], element[1]));
  });
  cards.shuffle();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // set up cards
    loadCards();
    updateTeamStrings();

    return MaterialApp(
      title: 'Cave Poet',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.brown,
      ),
      home: const MyHomePage(title: 'Cave Poet'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? _timer;

  final ButtonStyle teamPlayingButtonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(Colors.green.shade300));

  final ButtonStyle teamWatchingButtonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(Colors.grey.shade300));

  startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining == 0) {
        setState(() {
          timer.cancel();
          secondsRemaining = maxSeconds;
          audioplayer.play("buzzer.mp3");
          if (currentTeam == 0) {
            currentTeam = 1;
          } else {
            currentTeam = 0;
          }
          chooseNewCard();
          // debugPrint("timer done");
        });
      } else {
        setState(() {
          secondsRemaining--;
          // debugPrint("timer $secondsRemaining");
        });
      }
    });
  }

  chooseNewCard() {
    // check if all cards are used.  If so, reset all cards to unused
    currentCard++;
    if (currentCard >= cards.length) {
      cards.shuffle();
      currentCard = 0;
    }
  }

  onPressedWrong() {
    setState(() {
      teamScores[currentTeam] = teamScores[currentTeam] - 1;
      if (teamScores[currentTeam] < 0) teamScores[currentTeam] = 0;

      teamStrings[currentTeam] =
          teamNames[currentTeam] + teamScores[currentTeam].toString();

      chooseNewCard();
    });
  }

  onPressedEasy() {
    setState(() {
      teamScores[currentTeam] = teamScores[currentTeam] + 1;
      teamStrings[currentTeam] =
          teamNames[currentTeam] + teamScores[currentTeam].toString();
      chooseNewCard();
    });
  }

  onPressedHard() {
    setState(() {
      teamScores[currentTeam] += 3;
      teamStrings[currentTeam] =
          teamNames[currentTeam] + teamScores[currentTeam].toString();
      chooseNewCard();
    });
  }

  onPressedTeam1() {
    setState(() {
      currentTeam = 0;
    });
  }

  onPressedTeam2() {
    setState(() {
      currentTeam = 1;
    });
  }

  handleMenuClick(String value) {
    switch (value) {
      case 'Reset Game':
        setState(() {
          teamScores.fillRange(0, teamScores.length, 0);
          updateTeamStrings();
          currentTeam = 0;
          secondsRemaining = maxSeconds;
          _timer?.cancel();
        });

        break;
      case 'How to Play':
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text("How to Play"),
                  content: const Text(
                      "Play in 2 teams.  You can get your teammates to guess either the one point or 3 point word."),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("OK")),
                  ],
                ));
        break;
      case 'About':
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text("About"),
                  content: const Text(
                    "Written by Chester Liu\n\n\u00a9 2021",
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("OK")),
                  ],
                ));
        break;
    }
  }

//  If we dispose the widget, need to stop the timer
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Row(
          children: [
            Image.asset('assets/caveman-32.png'),
            const SizedBox(
              width: 10,
            ),
            Text(widget.title),
          ],
        ),
        toolbarHeight: 50,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              onSelected: handleMenuClick,
              itemBuilder: (BuildContext context) {
                return {'Reset Game', 'How to Play', 'About'}.map((choice) {
                  return PopupMenuItem<String>(
                      value: choice, child: Text(choice));
                }).toList();
              },
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Row of Teams with scores
          Wrap(
            children: [
              // Team 1
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: ElevatedButton(
                  style: (currentTeam == 0)
                      ? teamPlayingButtonStyle
                      : teamWatchingButtonStyle,
                  onPressed: onPressedTeam1,
                  child: Text(
                    teamStrings[0],
                    style: const TextStyle(color: Colors.black, fontSize: 20),
                  ),
                ),
              ),
              // Team 2
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: ElevatedButton(
                  style: (currentTeam == 1)
                      ? teamPlayingButtonStyle
                      : teamWatchingButtonStyle,
                  onPressed: onPressedTeam2,
                  child: Text(
                    teamStrings[1],
                    style: const TextStyle(color: Colors.black, fontSize: 20),
                  ),
                ),
              ),
              // Team 3
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              //   child: ElevatedButton(
              //     style: (currentTeam == 2)
              //         ? teamPlayingButtonStyle
              //         : teamWatchingButtonStyle,
              //     onPressed: onPressedTeam3,
              //     child: Text(
              //       teamStrings[2],
              //       style: const TextStyle(color: Colors.black, fontSize: 20),
              //     ),
              //   ),
              // ),
            ],
          ),
          // Timer row //////////////////////////////////////////////
          Container(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
            color: Colors.grey.shade200,
            // margin: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  "   Timer",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(
                  width: 20,
                ),
                ElevatedButton(
                  onPressed:
                      (secondsRemaining == maxSeconds) ? startTimer : null,
                  child: const Text("Start"),
                ),
                Text(
                  "   Seconds Remaining = $secondsRemaining",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Progress bar row //////////////////////////////////////
          SizedBox(
            height: 10,
            child: LinearProgressIndicator(
              minHeight: 10,
              value: (1 - secondsRemaining / maxSeconds),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
          // Card row //////////////////////////////////////////////
          Expanded(
            child: Container(
              color: Colors.amber.shade100,
              child: Center(
                child: SizedBox(
                  height: 500,
                  width: 300,
                  child: Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 20),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.grey.shade300,
                            side:
                                const BorderSide(color: Colors.brown, width: 5),
                            elevation: 15,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30))),
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.brown,
                              child: Center(
                                child: Text(
                                  "1",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "EarlyMan",
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              (secondsRemaining == maxSeconds)
                                  ? "Choose Team"
                                  : cards[currentCard].easyword,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.brown,
                                  fontFamily: "EarlyMan",
                                  fontStyle: FontStyle.normal,
                                  fontSize: 40,
                                  letterSpacing: 3),
                            ),
                            // HARD WORD //////////////////////////
                            Text(
                              (secondsRemaining == maxSeconds)
                                  ? "Click Start"
                                  : cards[currentCard].hardword,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontFamily: "EarlyMan",
                                fontSize: 40,
                                letterSpacing: 3,
                              ),
                            ),
                            const CircleAvatar(
                              backgroundColor: Colors.blueGrey,
                              child: Center(
                                child: Text(
                                  "3",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "EarlyMan",
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ),
                ),
              ),
            ),
          ),
          // Answer row ////////////////////////////////////////
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      (secondsRemaining != maxSeconds) ? onPressedWrong : null,
                  child: const Text("No! / Skip (-1)"),
                  style: ElevatedButton.styleFrom(primary: Colors.red),
                ),
                ElevatedButton(
                  onPressed:
                      (secondsRemaining != maxSeconds) ? onPressedEasy : null,
                  child: const Text("Got Easy (+1)"),
                  style: ElevatedButton.styleFrom(primary: Colors.brown),
                ),
                ElevatedButton(
                  onPressed:
                      (secondsRemaining != maxSeconds) ? onPressedHard : null,
                  child: const Text("Got Hard (+3)"),
                  style: ElevatedButton.styleFrom(primary: Colors.blueGrey),
                )
              ],
            ),
          )
        ],
      ),

      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
