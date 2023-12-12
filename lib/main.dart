import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

bool isMobile() {
  return Platform.isAndroid || Platform.isIOS;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <WordPair>[];

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void deleteFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritesPage();
      default:
        throw UnimplementedError('No widget for index $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      var navBar;
      if (constraints.maxWidth <= 700) {
        navBar = NavigationBar(
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
          ],
          selectedIndex: selectedIndex,
          onDestinationSelected: (value) {
            setState(() {
              selectedIndex = value;
            });
          },
        );
      }
      return Scaffold(
        bottomNavigationBar: navBar,
        body: Row(
          children: [
            if (constraints.maxWidth > 700)
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth > 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  final FocusNode _focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    String faved;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
      faved = 'Liked';
    } else {
      icon = Icons.favorite_border;
      faved = 'Like';
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (FocusNode none, RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyL) {
            appState.toggleFavorite();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.keyN) {
            appState.getNext();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BigCard(pair: pair),
            SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    appState.toggleFavorite();
                  },
                  icon: Icon(icon),
                  label: Text(faved),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    appState.getNext();
                  },
                  child: Text('Next'),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (!isMobile())
              Text('Press L to like, N for next',
                  style: Theme.of(context).textTheme.labelSmall)
          ],
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    var favorites = appState.favorites;

    if (favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet', style: theme.textTheme.displaySmall),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      var axisCount = constraints.maxWidth ~/ 220;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Favorites (${favorites.length})',
                  style: theme.textTheme.displaySmall),
              SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: axisCount,
                  childAspectRatio: 4,
                  children: [
                    for (var pair in favorites)
                      Card(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                appState.deleteFavorite(pair);
                              },
                            ),
                            Text(pair.asPascalCase)
                          ],
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    var styleLight = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontWeight: FontWeight.w200,
    );
    var styleBold = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontWeight: FontWeight.w800,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                pair.first,
                style: styleLight,
                semanticsLabel: pair.asPascalCase,
              ),
              Text(
                pair.second,
                style: styleBold,
                semanticsLabel: pair.asPascalCase,
              ),
            ]),
          )),
    );
  }
}
