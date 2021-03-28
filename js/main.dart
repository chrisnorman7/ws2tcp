import 'dart:html';

import 'util.dart';

void main() {
  final loadingDiv = getElement('#loadingDiv');
  loadingDiv.hidden = true;
  final documentDiv = getElement('#documentDiv');
  documentDiv.hidden = false;
  final hostname = getElement('#hostname') as InputElement;
  hostname.value = window.localStorage['hostname'] ?? hostname.value;
  final port = getElement('#port') as InputElement;
  port.value = window.localStorage['port'] ?? port.value;
  hostname.focus();
  final connectForm = getElement('#connectForm') as FormElement;
  connectForm.onSubmit.listen((event) {
    event.preventDefault();
    window.localStorage['hostname'] = hostname.value ?? '';
    window.localStorage['port'] = port.value ?? '';
    final connectDiv = getElement('#connectDiv');
    final sendForm = getElement('#sendForm') as FormElement;
    final mainDiv = getElement('#mainDiv');
    final commandInput = getElement('#command') as InputElement;
    final ws = WebSocket(
        'ws://${window.location.hostname}:${window.location.port}/ws');
    ws.onOpen.listen((event) {
      connectDiv.hidden = true;
      mainDiv.hidden = false;
      commandInput.focus();
      output('<< Connected >>>>');
      final h = hostname.value;
      if (h != null) {
        ws.sendString(h);
      }
      final p = port.value;
      if (p != null) {
        ws.sendString(p);
      }
    });
    ws.onMessage.listen((event) {
      if (event.data is String) {
        output(event.data);
      } else {
        output('<< Unexpected data: ${event.data} >>');
      }
    }, onDone: () {
      connectDiv.hidden = false;
      hostname.focus();
      output('<< Disconnected >>');
    });
    sendForm.onSubmit.listen((event) {
      event.preventDefault();
      final command = commandInput.value;
      if (command != null) {
        ws.sendString(command);
        commandInput.value = null;
      }
    });
  });
}
