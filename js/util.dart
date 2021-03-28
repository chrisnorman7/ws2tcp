import 'dart:html';

/// Output text.
///
/// This function splits the given lines so that they can be added in separate paragraph elements.
///
/// The tab index of each element is set, so you can use tab and shift tab to move between them, and the command box.
void output(

    /// The text to be shown.
    String text) {
  final outputDiv = document.querySelector("#output");
  if (outputDiv == null) {
    return null;
  }
  for (final String line in text.split(RegExp('\r?\n'))) {
    final p = document.createElement('p');
    p.innerText = line;
    if (line.isNotEmpty) {
      p.tabIndex = 0;
    }
    outputDiv.append(p);
  }
  outputDiv.scrollTo(0, outputDiv.scrollHeight);
}

/// Get an element, or throw an error.
///
/// We don't really want to continue if an element is now found, so we throw an exception.
///
/// I feel this is more graceful (and less code) than checking for null everywhere.
Element getElement(String selector) {
  final e = document.querySelector(selector);
  if (e == null) {
    throw Exception('ERROR! No such element $selector.');
  }
  return e;
}
