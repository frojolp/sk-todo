import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import "package:flutter_speed_dial/flutter_speed_dial.dart";
import 'package:path_provider/path_provider.dart';

class TodoListe extends StatefulWidget {
  @override
  _TodoListeState createState() => _TodoListeState();
}

class _TodoListeState extends State<TodoListe> {
  File jsonFile;
  Directory dir;
  String filename = "lokalerSpeicher.json";
  bool fileExists = false;
  Map<String, List<dynamic>> jsonmap;

  bool haken = false;
  String hakentext = "abgehakte Einträge ausblenden";

  bool archiv = false;
  String archivtext = "alte Einträge ausblenden";

  //allgemeine Liste
  List<String> _todoItems = [];
  List<String> _todoImg = [];
  List<DateTime> _todoDate = [];
  List<String> _todoDatets = [];

  // Liste nach nicht abgehackt sortiert
  List<String> _todoItemsnothaked = [];
  List<String> _todoImgnothaked = [];
  List<DateTime> _todoDatenothaked = [];
  List<int> _todonothakedindex = [];

  // Liste nach dem Archiv sortiert
  List<String> _todoItemsarchived = [];
  List<String> _todoImgarchived = [];
  List<DateTime> _todoDatearchived = [];
  List<int> _todoarchivedindex = [];

  //Liste nach haken und archiv sortiert
  List<String> _todoItemsnothakedarchived = [];
  List<String> _todoImgnothakedarchived = [];
  List<DateTime> _todoDatenothakedarchived = [];
  List<int> _todonothakedarchivedindex = [];

  File createFile(Map<String, List> content) {
    File file;
    if (dir == null) {
      print('DEBUG: dir ist nicht definiert');
      file = new File(filename);
    } else {
      file = new File(dir.path + "/" + filename);
    }
    file.createSync();
    fileExists = true;
    file.writeAsStringSync(jsonEncode(content));
    return file;
  }

  void writeToFile() {
    print("Writing to File");
    if (_todoDate.length != 0) {
      for (int l = 0; l < _todoDate.length; l++) {
        _todoDatets.add(_todoDate[l].toString());
      }
    }
    //jsonmap = {"Liste": _todoItems, "Datum": _todoDatets, "Img": _todoImg};
    jsonmap = {"Liste": _todoItems, "Img": _todoImg};
    if (fileExists) {
      print("File Exists");
      jsonFile.writeAsStringSync(jsonEncode(jsonmap));
      print(jsonmap);
    } else {
      createFile(jsonmap);
    }
  }

  void initState() {
    super.initState();

    if (!kIsWeb) {
      //dir = await path_provider.getApplicationDocumentsDirectory();
      getApplicationDocumentsDirectory().then((Directory directory) {
        dir = directory;
        jsonFile = new File(dir.path + "/" + filename);
        fileExists = jsonFile.existsSync();
        if (fileExists) {
          this.setState(
              () => jsonmap = jsonDecode(jsonFile.readAsStringSync()));
          _getItems();
        }
      });
    }
  }

  _getItems() {
    if (jsonmap["Liste"] != [""]) {
      List<String> _todoItemss = jsonmap["Liste"];
      List<String> _todoDatetss = jsonmap["Datum"];
      List<String> _todoImgs = jsonmap["Img"];
      _todoDatets = _todoDatetss;
      _todoItems = _todoItemss;
      _todoImg = _todoImgs;
      print(_todoImgs);
      print(_todoItemss);
      print(_todoDatetss);

      for (int l = 0; l < _todoDatets.length; l++) {
        _todoDate[l] = DateTime.parse(_todoDatets[l]);
      }
    }
  }

  //erstellt den Körper der Liste
  Widget _erstelleTodoListe() {
    return new ListView.builder(
      // ignore: missing_return
      itemBuilder: (context, index) {
        //guckt ob haken an und Archiv aus ist (variante 1)
        if (haken && !archiv) {
          if (index < _todoItemsnothaked.length) {
            //nutzt die Liste der ausgeblendet haken
            return _erstelleTodoEintrag(
              _todoItemsnothaked[index],
              index,
              _todoImgnothaked[index],
              _todoDatenothaked[index],
            );
          }

          //guckt ob archiv an und haken aus ist (variante 2)
        } else if (!haken && archiv) {
          if (index < _todoItemsarchived.length) {
            return _erstelleTodoEintrag(
              _todoItemsarchived[index],
              index,
              _todoImgarchived[index],
              _todoDatearchived[index],
            );
          }

          //guckt ob archiv und haken an sind (variante 3)
        } else if (haken && archiv) {
          if (index < _todoItemsnothakedarchived.length) {
            return _erstelleTodoEintrag(
              _todoItemsnothakedarchived[index],
              index,
              _todoImgnothakedarchived[index],
              _todoDatenothakedarchived[index],
            );
          }

          //guckt ob beides aus ist (Variante 4)
        } else {
          if (index < _todoItems.length) {
            return _erstelleTodoEintrag(
              _todoItems[index],
              index,
              _todoImg[index],
              _todoDate[index],
            );
          }
        }
      },
    );
  }

  //Methode zum für den Pop zum löschen eines Eintrags
  void _eintragEntfernDialog(int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text("Eintrag ${_todoItems[index]} entfernen?"),
            actions: [
              new TextButton(
                  onPressed: () {
                    _eintragEntfernen(index);
                    Navigator.of(context).pop();
                  },
                  child: Text("Entfernen")),
              new TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Abbrechen")),
            ],
          );
        });
  }

  //Methode zum löschen eines Eintrags
  void _eintragEntfernen(int index) {
    setState(() {
      //variante 1
      if (haken && !archiv) {
        //löscht die gefilternten Einträge
        _todoItemsnothaked.removeAt(index);
        _todoImgnothaked.removeAt(index);
        _todoDatenothaked.removeAt(index);
        //löscht die normalen Einträge
        _todoItems.removeAt(_todonothakedindex[index]);
        _todoImg.removeAt(_todonothakedindex[index]);
        _todoDate.removeAt(_todonothakedindex[index]);
        _sortall();

        //variante 2
      } else if (!haken && archiv) {
        //löscht die gefilternten Einträge
        _todoItemsarchived.removeAt(index);
        _todoImgarchived.removeAt(index);
        _todoDatearchived.removeAt(index);
        //löscht die normalen Einträge
        _todoItems.removeAt(_todoarchivedindex[index]);
        _todoImg.removeAt(_todoarchivedindex[index]);
        _todoDate.removeAt(_todoarchivedindex[index]);
        _sortall();

        //variante 3
      } else if (haken && archiv) {
        //löscht die gefilternten Einträge
        _todoItemsnothakedarchived.removeAt(index);
        _todoImgnothakedarchived.removeAt(index);
        _todoDatenothakedarchived.removeAt(index);
        //löscht die normalen Einträge
        _todoItems.removeAt(_todonothakedarchivedindex[index]);
        _todoImg.removeAt(_todonothakedarchivedindex[index]);
        _todoDate.removeAt(_todonothakedarchivedindex[index]);
        _sortall();

        //variante 4
      } else {
        //löscht die normalen Einträge
        _todoItems.removeAt(index);
        _todoImg.removeAt(index);
        _todoDate.removeAt(index);
        _sortall();
      }
    });
  }

  //entfernt den Haken (macht ihn grau)
  void _notfinished(int index) {
    setState(() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return new AlertDialog(
              title:
                  new Text("Eintrag ${_todoItems[index]} nicht mehr Abhaken?"),
              actions: [
                new TextButton(
                    onPressed: () {
                      setState(() {
                        //ändert das Bild zum grauen Bild
                        _todoImg[index] = "assets/Images/Haken grau SK.png";
                        Navigator.of(context).pop();
                        _sortall();
                      });
                    },
                    child: Text("Entfernen")),
                new TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Abrechen")),
              ],
            );
          });
    });
  }

  void _finished(int index) {
    setState(() {
      //variante 1
      if (haken && !archiv) {
        //ändert das gefilterte Bild
        _todoImgnothaked[index] = "assets/Images/Haken SK.png";
        //ändert das ungefilterte Bild
        _todoImg[_todonothakedindex[index]] = "assets/Images/Haken SK.png";

        //variante 2
      } else if (!haken && archiv) {
        //ändert das gefilterte Bild
        _todoImg[_todoarchivedindex[index]] = "assets/Images/Haken SK.png";
        //ändert das ungefilterte Bild
        _todoImgarchived[index] = "assets/Images/Haken SK.png";

        //variante 3
      } else if (haken && archiv) {
        //ändert das gefilterte Bild
        _todoImg[_todonothakedarchivedindex[index]] =
            "assets/Images/Haken SK.png";
        //ändert das ungefilterte Bild
        _todoImgnothakedarchived[index] = "assets/Images/Haken SK.png";

        //variante 4
      } else if (!haken && !archiv) {
        //ändert das ungefilterte Bild
        _todoImg[index] = "assets/Images/Haken SK.png";
      }
      _sortall();
      writeToFile();
    });
  }

  //Körper der Liste
  Widget _erstelleTodoEintrag(
      String todoText, int index, String img, DateTime date) {
    // Formatierung des angezeigten Datums
    String datefin = "${date.day}.${date.month}.${date.year}";
    return new Slidable(
      direction: Axis.horizontal,
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.5,
      child: InkWell(
        child: Container(
          height: 50,
          width: 200,
          decoration: BoxDecoration(color: Colors.white),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  //name des Eintrags aus der gegeben Liste (V1,V2,V3,V4)
                  "$todoText",
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                //Datum des Eintrags aus der gegeben Liste (V1,V2,V3,V4)
                "Fällig bis: $datefin",
                style: TextStyle(fontSize: 13.0),
              ),
            ),
            //Ändern des Bildes durch Drücken des Bildes
            GestureDetector(
              onTap: () {
                if (haken) {
                  if (_todoImg[_todonothakedindex[index]] ==
                      "assets/Images/Haken grau SK.png") {
                    _finished(index);
                  } else {
                    _notfinished(index);
                  }
                } else if (_todoImg[index] ==
                    "assets/Images/Haken grau SK.png") {
                  _finished(index);
                } else {
                  _notfinished(index);
                }
              },
              child: Image.asset(
                img,
              ),
            ),
          ]),
        ),
        onTap: () => _eintragEntfernDialog(index),
      ),
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: "Delete",
          color: Colors.red,
          icon: Icons.delete,
          onTap: () {
            _eintragEntfernDialog(index);
          },
        )
      ],
    );
  }

  //füllen der unsortierten Liste mit automatischer Datumssortierung
  //Erstellung der Sortierten Listen
  void _neuerTodoEintrag(String eintrag, DateTime datum) {
    if (eintrag.length > 0) {
      if (_todoItems.length != 0) {
        DateTime fruehst = _todoDate.firstWhere(
            (element) => datum.isBefore(element),
            orElse: () => datum);
        int wo = _todoDate.indexOf(fruehst);
        if (wo != -1) {
          setState(() {
            _todoItems.insert(wo, eintrag);
            _todoImg.insert(wo, "assets/Images/Haken grau SK.png");
            _todoDate.insert(wo, datum);
          });
        } else {
          setState(() {
            _todoItems.add(eintrag);
            _todoImg.add("assets/Images/Haken grau SK.png");
            _todoDate.add(datum);
          });
        }
      } else {
        setState(() {
          _todoItems.add(eintrag);
          _todoImg.add("assets/Images/Haken grau SK.png");
          _todoDate.add(datum);
        });
      }
    }
    //erstellt alle sortierten Listen
    _sortall();
    writeToFile();
  }

  //lässt einen das Datum auswählen
  Future<void> _datumsangabe(BuildContext context, String name) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null) {
      _neuerTodoEintrag(name, picked);
      Navigator.pop(context);
    }
  }

  //eingabe des namen des Eintrags
  void _neuerEigenerTodoEintrag() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return new Scaffold(
          appBar: new AppBar(title: new Text("Neues Element hinzufügen")),
          body: new TextField(
            autofocus: true,
            onSubmitted: (val) {
              _datumsangabe(context, val);
            },
            decoration: new InputDecoration(
                hintText: "Geben sie ein was sie erledigen wollen",
                contentPadding: const EdgeInsets.all(16.0)),
          ));
    }));
  }

  //ändert den Text im Dropdown Menü beim Haken
  _hakenbooltext() {
    setState(() {
      if (haken) {
        hakentext = "abgehakte Einträge ausblenden";
        haken = false;
      } else {
        hakentext = "abgehakte Einträge einblenden";
        haken = true;
      }
    });
  }

  //ändert den Text im Dropdown Menü beim Archiv
  _archivbooltext() {
    setState(() {
      if (archiv) {
        archiv = false;
        archivtext = "alte Einträge ausblenden";
      } else {
        archiv = true;
        archivtext = "alte Einträge einblenden";
      }
    });
  }

  //erstellt die sortierte Archivliste (blendet alle Einträge in der Vergangenheit aus)
  _archivsort() {
    _todoDatearchived = [];
    _todoItemsarchived = [];
    _todoImgarchived = [];
    _todoarchivedindex = [];
    DateTime heute = DateTime.now();
    int jahr = heute.year;
    int monat = heute.month;
    int tag = heute.day;
    tag--;
    DateTime today = new DateTime(jahr, monat, tag);
    int archivsortlaenge = _todoDate.length;
    for (int archivsortstelle = 0;
        archivsortstelle < archivsortlaenge;
        archivsortstelle++) {
      if (_todoDate[archivsortstelle].isAfter(today)) {
        _todoImgarchived.add(_todoImg[archivsortstelle]);
        _todoItemsarchived.add(_todoItems[archivsortstelle]);
        _todoDatearchived.add(_todoDate[archivsortstelle]);
        _todoarchivedindex.add(archivsortstelle);
      }
    }
  }

  //erstellt die sortierte Hakenliste (blendet alle abgehakten Einträge aus)
  _hakensort() {
    _todoDatenothaked = [];
    _todoItemsnothaked = [];
    _todoImgnothaked = [];
    _todonothakedindex = [];
    int hakensortlaenge = _todoImg.length;
    for (var hakensortstelle = 0;
        hakensortstelle < hakensortlaenge;
        hakensortstelle = hakensortstelle + 1) {
      if (_todoImg[hakensortstelle] == "assets/Images/Haken grau SK.png") {
        _todoImgnothaked.add(_todoImg[hakensortstelle]);
        _todoItemsnothaked.add(_todoItems[hakensortstelle]);
        _todoDatenothaked.add(_todoDate[hakensortstelle]);
        _todonothakedindex.add(hakensortstelle);
      }
    }
  }

  //erstellt die sortierte Haken- und Archivliste (blendet alle abgehakten und vergangenen Einträge aus)
  _archivhakensort() {
    _todoDatenothakedarchived = [];
    _todoItemsnothakedarchived = [];
    _todoImgnothakedarchived = [];
    _todonothakedarchivedindex = [];
    DateTime heute = DateTime.now();
    int jahr = heute.year;
    int monat = heute.month;
    int tag = heute.day;
    tag--;
    DateTime today = new DateTime(jahr, monat, tag);
    int hakenarchivsortlaenge = _todoItems.length;
    for (int hakenarchivsortstelle = 0;
        hakenarchivsortstelle < hakenarchivsortlaenge;
        hakenarchivsortstelle++) {
      if (_todoImg[hakenarchivsortstelle] ==
              "assets/Images/Haken grau SK.png" &&
          _todoDate[hakenarchivsortstelle].isAfter(today)) {
        _todoImgnothakedarchived.add(_todoImg[hakenarchivsortstelle]);
        _todoItemsnothakedarchived.add(_todoItems[hakenarchivsortstelle]);
        _todoDatenothakedarchived.add(_todoDate[hakenarchivsortstelle]);
        _todonothakedarchivedindex.add(hakenarchivsortstelle);
      }
    }
  }

  //erstellt/aktualisiert alle sortierten Listen
  _sortall() {
    _hakensort();
    _archivsort();
    _archivhakensort();
  }

  //baut die Hauptstruktur der App auf
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Todo Liste"),
        ),
        body: _erstelleTodoListe(),
        floatingActionButton:
            SpeedDial(animatedIcon: AnimatedIcons.menu_close, children: [
          SpeedDialChild(
              child: Icon(Icons.create_rounded),
              label: "Neuen Eintrag erstellen",
              onTap: _neuerEigenerTodoEintrag),
          SpeedDialChild(
            child: Icon(Icons.archive),
            label: archivtext,
            onTap: () {
              _archivbooltext();
              _sortall();
              writeToFile();
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.check_circle_outlined),
            label: hakentext,
            onTap: () {
              _sortall();
              _hakenbooltext();
              writeToFile();
            },
          )
        ]));
  }
}
