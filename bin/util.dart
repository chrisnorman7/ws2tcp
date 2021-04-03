import 'dart:html';

/// Output text.
///
/// If `text` isn't empty, the tab index of the resulting element is set, so you can tab through the various lines of output.
void output(

    /// The text to be shown.
    String text) {
  final outputDiv = document.querySelector("#output");
  if (outputDiv == null) {
    return null;
  }
  final p = document.createElement('p');
  p.innerText = text;
  if (text.isNotEmpty) {
    p.tabIndex = 0;
  }
  outputDiv.append(p);
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
