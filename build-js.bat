@echo off
del static\*.js*
dart compile js -o static\main.dart.js bin\main.dart
