import 'dart:io';

void main() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  String content = file.readAsStringSync();
  content = content.replaceAll('android:label="vehicle_tracker"', 'android:label="Vehio"');
  file.writeAsStringSync(content);
  print('Done Manifest!');
}