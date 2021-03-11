import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum ServerStatus { Online, Offline, Connecting }

class SocketService with ChangeNotifier {
  ServerStatus _serverStatus = ServerStatus.Connecting;

  IO.Socket _socket;

  IO.Socket get socket => this._socket;

  get serverStatus => _serverStatus;

  SocketService() {
    _initConfig();
  }

  _initConfig() {
    // Dart client
    this._socket = IO.io('http://localhost:3000', {
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
    });
    socket.on('connect', (_) {
      print('connect');
      notifyListeners();
    });
    this._socket.onConnect((_) {
      _serverStatus = ServerStatus.Online;
      notifyListeners();
    });

    this._socket.onDisconnect((_) {
      _serverStatus = ServerStatus.Offline;
      notifyListeners();
    });

    this._socket.on('nuevo-mensaje', (payload) {
      print('Mensaje recibido: $payload');
      print('Data: ' + payload['nombre'] + ' ' + payload['texto']);
      notifyListeners();
    });
  }
}
