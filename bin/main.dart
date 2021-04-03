import 'dart:async';
import 'dart:html';

import 'triggers.dart';
import 'util.dart';

void main() {
  getElement('#loadingDiv').hidden = true;
  getElement('#documentDiv').hidden = false;
  final hostname = getElement('#hostname') as InputElement;
  hostname.value = window.localStorage['hostname'] ?? hostname.value;
  final port = getElement('#port') as InputElement;
  port.value = window.localStorage['port'] ?? port.value;
  final connectString = getElement('#connectString') as InputElement;
  connectString.value =
      window.localStorage['connectString'] ?? connectString.value;
  hostname.focus();
  final commandInput = getElement('#command') as InputElement;
  final hideTextForm = getElement('#hideTextForm') as InputElement;
  hideTextForm.onClick.listen((event) {
    getElement('#textForm').hidden = true;
    commandInput.focus();
  });
  final connectForm = getElement('#connectForm') as FormElement;
  connectForm.onSubmit.listen((event) {
    event.preventDefault();
    window.localStorage['hostname'] = hostname.value ?? '';
    window.localStorage['port'] = port.value ?? '';
    window.localStorage['connectString'] = connectString.value ?? '';
    final connectDiv = getElement('#connectDiv');
    final sendForm = getElement('#sendForm') as FormElement;
    final mainDiv = getElement('#mainDiv');
    final ws = WebSocket(
        'ws://${window.location.hostname}:${window.location.port}/ws');
    final triggers = TriggerStorage(ws);
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
    final cs = connectString.value;
    bool connectStringSent = false;
    ws.onMessage.listen((event) {
      if (event.data is String) {
        if (cs != null && connectStringSent == false) {
          connectStringSent = true;
          Timer(Duration(milliseconds: 100), () => ws.sendString(cs));
        }
        for (String line in event.data.split('\r\n')) {
          TriggerContext? ctx = null;
          for (final Trigger t in triggers.enabledTriggers) {
            final m = t.re.firstMatch(line);
            if (m != null) {
              if (ctx == null) {
                ctx = TriggerContext(line, m);
              }
              ctx.triggers.add(t);
              try {
                t.func(ctx);
              } catch (e, s) {
                output('Error: $e\n\n$s');
                return;
              }
            }
          }
          if (ctx == null) {
            output(line); // No triggers were used.
          } else if (ctx.gag == false) {
            output(ctx.text); // Output whatever the triggers left us.
          } else {
            // The line was gagged, and shouldn't be shown anyway.
          }
        }
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
