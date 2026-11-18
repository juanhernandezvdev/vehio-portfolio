import 'dart:io';

void main() {
  final file = File('lib/auth/login_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('const Color(0xFFE50914).shade100', 'const Color(0x33E50914)');
  file.writeAsStringSync(content);

  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  for (final f in files) {
    String c = f.readAsStringSync();
    // remove unnecessary const around const Color(...) that are already in a const context
    c = c.replaceAll('const const Color(0xFFE50914)', 'const Color(0xFFE50914)');
    c = c.replaceAll('color: const Color(0xFFE50914)', 'color: const Color(0xFFE50914)');
    f.writeAsStringSync(c);
  }
}