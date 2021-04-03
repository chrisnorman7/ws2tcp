/// Provides trigger-related classes.
import 'dart:html';

import 'util.dart';

/// The context which is sent to each trigger's function.
class TriggerContext {
  /// The original text.
  final String originalText;

  /// The current regexp match.
  RegExpMatch match;

  /// The text which was originally sent, and can be modified by triggers further down the line.
  ///
  /// This value may be the same as [originalText].
  String text;

  /// Whether or not to suppress the text from being printed.
  bool gag = false;

  /// The triggers which have already been processed.
  final List<Trigger> triggers = <Trigger>[];

  /// Create a context.
  TriggerContext(this.originalText, this.match) : text = originalText;

  /// Update the current [text]].
  ///
  /// If the new text is `null`, the text will remain unchanged.
  void updateText(String? newText) {
    if (newText != null) {
      text = newText;
    }
  }
}

/// A trigger.
class Trigger {
  /// The name of this trigger.
  final String name;

  /// The regular expression which causes this trigger to fire.
  final RegExp re;

  /// The function which will be executed when this trigger fires.
  final void Function(TriggerContext) func;

  /// The priority given to this trigger.
  final int priority;

  /// Whether or not this trigger is enabled.
  bool enabled;

  /// Create a new trigger.
  Trigger(this.name, this.re, this.func,
      {this.priority = 0, this.enabled = true});

  /// Return the name of this trigger.
  @override
  String toString() => name;
}

/// The class which holds all the defined triggers.
class TriggerStorage {
  /// The websocket which commands should be sent down.
  final WebSocket ws;

  /// All triggers.
  final List<Trigger> triggers = <Trigger>[];

  /// Create a trigger store.
  TriggerStorage(this.ws) {
    final textForm = getElement('#textForm') as FormElement;
    final textCommand = getElement('#textCommand') as InputElement;
    final textName = getElement('#textName') as HeadingElement;
    final textEntry = getElement('#textEntry') as TextAreaElement;
    final Trigger gagOneLine =
        Trigger('Gag a line of text', RegExp('.*'), (TriggerContext ctx) {
      ctx.gag = true;
      ctx.triggers.last.enabled = false;
    }, enabled: false);
    triggers.add(gagOneLine);
    textForm.onSubmit.listen((event) {
      event.preventDefault();
      textForm.hidden = true;
      getElement('#command').focus();
      String? text = textEntry.value;
      if (textCommand.value != null) {
        if (text == null) {
          output('<< Cancelled >>');
        } else {
          gagOneLine.enabled = true;
          text = text.replaceAll('\n', '\r\n');
          if (text.endsWith('\r\n') == false) {
            text = '$text\r\n';
          }
          ws.sendString('${textCommand.value}\r\n$text');
        }
      } else {
        output("<< Don't know how to send ${textName.innerText} >>");
      }
    });
    Trigger? textStartTrigger, textLineTrigger;
    textStartTrigger = Trigger('Start gathering text',
        RegExp(r'^\#\$\# edit name: (.+) upload: ([^$]+)$'),
        (TriggerContext ctx) {
      textForm.hidden = false;
      textEntry.value = '';
      textName.innerText = ctx.match.group(1) ?? 'Enter text';
      if (textLineTrigger != null) {
        textLineTrigger.enabled = true;
      }
      if (textStartTrigger != null) {
        textStartTrigger.enabled = false;
      }
      textCommand.value = ctx.match.group(2) ?? '';
      ctx.updateText(ctx.match.group(1));
    });
    textLineTrigger = Trigger('Gather a line of text', RegExp('^([^\$]*)\$'),
        (TriggerContext ctx) {
      if (ctx.originalText == '.') {
        textEntry.focus();
        if (textLineTrigger != null) {
          textLineTrigger.enabled = false;
        }
        if (textStartTrigger != null) {
          textStartTrigger.enabled = true;
        }
      }
      final v = textEntry.value;
      if (v == null || v.isEmpty) {
        textEntry.value = '${ctx.originalText}\n';
      } else {
        textEntry.value = '$v${ctx.originalText}\n';
      }
      ctx.gag = true;
    }, enabled: false);
    triggers.addAll([textStartTrigger, textLineTrigger]);
  }

  /// Get a list of all the currently-enabled triggers.
  List<Trigger> get enabledTriggers {
    final List<Trigger> l =
        triggers.where((element) => element.enabled == true).toList();
    l.sort((Trigger a, Trigger b) => b.priority.compareTo(a.priority));
    return l;
  }
}
