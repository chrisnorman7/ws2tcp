import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http_server/http_server.dart';

/// A proxy serve.
///
/// This server forwards websockets onto old-style TCP connections.

class Connection {
  final WebSocket _ws;
  final Encoding _codec;
  String? _hostname;
  int? _port;
  Socket? _socket;
  StreamSubscription? _socketListener;

  Connection(this._ws, this._codec);

  void onDone() {
    print('Connection closed.');
    _socketListener?.cancel();
  }

  void onError(e, StackTrace s) {
    print('Error: $e');
    print(s);
  }

  void onData(dynamic event) async {
    if (event is String) {
      final h = _hostname;
      final p = _port;
      Socket? s = _socket;
      if (h == null) {
        _hostname = event;
        _ws.add('Hostname is $_hostname.');
      } else if (p == null) {
        _port = int.tryParse(event);
        print('Port is $_port.');
      } else if (s == null) {
        print('Connecting to $h:$p.');
        s = await Socket.connect(h, p);
        _socket = s;
        _socketListener = s.listen((event) {
          _ws.add(_codec.decode(event));
        });
      } else {
        s.add(_codec.encode(event));
      }
    } else {
      print('Cannot handle $event.');
      _ws.close();
    }
  }
}

Future<void> main() async {
  final List<StreamSubscription> subscriptions = [];
  final staticFiles = VirtualDirectory('static');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  final webSocketUri = Uri.parse('/ws');
  print('Server running.');
  final codec = Utf8Codec();
  server.listen((request) async {
    print('${request.method} ${request.uri}');
    if (request.uri == webSocketUri) {
      try {
        final ws = await WebSocketTransformer.upgrade(request);
        print(ws);
        final con = Connection(ws, codec);
        final subscription =
            ws.listen(con.onData, onDone: con.onDone, onError: con.onError);
        subscriptions.add(subscription);
      } catch (e, s) {
        print('Error: $e');
        print(s);
      }
    } else {
      await staticFiles.serveRequest(request);
    }
  });
  subscriptions.forEach((element) => element.cancel());
}
