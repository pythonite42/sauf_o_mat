import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';

typedef MessageHandler = void Function(Map<String, dynamic> data);

class ServerManager {
  static final ServerManager _instance = ServerManager._internal();
  factory ServerManager() => _instance;

  late WebSocketChannel _channel;
  final List<MessageHandler> _listeners = [];

  ServerManager._internal();

  Future<void> connect(String url) async {
    final socket = await WebSocket.connect(url);
    _channel = IOWebSocketChannel(socket);

    _channel.stream.listen((message) {
      try {
        final decoded = jsonDecode(utf8.decode(message as Uint8List));
        for (var listener in _listeners) {
          listener(decoded);
          debugPrint("listened to: $decoded");
        }
      } catch (e) {
        debugPrint("❌ Error decoding message: $e");
      }
    }, onError: (error) {
      debugPrint("❌ WebSocket error: $error");
    }, onDone: () {
      debugPrint("⚠️ WebSocket connection closed.");
    });
  }

  void addListener(MessageHandler handler) {
    _listeners.add(handler);
  }

  void removeListener(MessageHandler handler) {
    _listeners.remove(handler);
  }

  void send(Map<String, dynamic> data) {
    _channel.sink.add(jsonEncode(data));
  }

  void dispose() {
    _channel.sink.close();
    _listeners.clear();
  }
}
