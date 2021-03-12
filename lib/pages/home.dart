import 'dart:io';

import 'package:band_names/Models/band.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    super.initState();
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-bands', _handleActiveBands);
  }

  _handleActiveBands(dynamic payload) async {
    this.bands = await Future.value(
        (payload as List).map((band) => Band.fromMap(band)).toList());

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: Text(
          'BandNames',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10.0),
            child: socketService.serverStatus == ServerStatus.Online
                ? Icon(Icons.check_circle, color: Colors.blue[300])
                : Icon(Icons.offline_bolt, color: Colors.red),
          )
        ],
      ),
      body: Center(
        child: Column(
          children: [
            _showChart(),
            Expanded(
              child: ListView.builder(
                itemCount: bands.length,
                itemBuilder: (BuildContext context, int index) =>
                    _bandTile(bands[index]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        elevation: 1,
        onPressed: addNewBand,
      ),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        print('id: ${band.id}');
        //Emit: delete-band
        String bandId = band.id;
        setState(() {
          bands.remove(band);
        });
        socketService.socket.emit('delete-band', {'id': bandId});
      },
      background: Container(
        padding: EdgeInsets.only(left: 10.0),
        color: Colors.red,
        child: Align(
          child: ListTile(
            leading: Text(
              'Delete Band',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0, 2)),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(band.name),
        trailing: Text(
          '${band.votes}',
          style: TextStyle(fontSize: 20.0),
        ),
        onTap: () async =>
            socketService.socket.emit('vote-band', {'id': band.id}),
      ),
    );
  }

  addNewBand() {
    String inputName = '';

    if (Platform.isAndroid) {
      return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Add a new Band'),
            content: TextField(
              onChanged: (value) {
                inputName = value;
              },
            ),
            actions: [
              MaterialButton(
                color: Colors.blue,
                child: Text('Add'),
                onPressed: () {
                  addBandToList(inputName);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    } else {
      return showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('Add a new Band'),
            content: CupertinoTextField(
              onChanged: (value) {
                inputName = value;
              },
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Add'),
                onPressed: () => addBandToList(inputName),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text('Dismiss'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        },
      );
    }
  }

  void addBandToList(String bandName) {
    if (bandName.isNotEmpty) {
      //Emitir add-band
      SocketService socketService =
          Provider.of<SocketService>(context, listen: false);
      socketService.socket.emit('add-band', {'name': bandName});
      setState(() {});
    }
  }

  Widget _showChart() {
    Map<String, double> dataMap = new Map();
    //  {
    //   "Flutter": 5,
    //   "React": 3,
    //   "Xamarin": 2,
    //   "Ionic": 2,
    // };
    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    return Container(
      width: double.infinity,
      height: 200,
      child: PieChart(
        dataMap: dataMap,
        colorList: [
          Colors.blue[100],
          Colors.blue[300],
          Colors.blue[400],
          Colors.blue,
          Colors.blue[600],
          Colors.blue[800]
        ],
        ringStrokeWidth: 5,
        chartValuesOptions: ChartValuesOptions(
            decimalPlaces: 0,
            showChartValueBackground: false,
            chartValueStyle: TextStyle(color: Colors.black)),
      ),
    );
  }
}
