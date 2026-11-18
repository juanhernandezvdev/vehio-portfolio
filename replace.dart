import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  for (final file in files) {
    String content = file.readAsStringSync();
    content = content.replaceAll('Garaje Pro', 'Vehio');
    content = content.replaceAll('Colors.amber', 'const Color(0xFFE50914)');
    content = content.replaceAll('0xFFFFB300', '0xFFE50914');
    content = content.replaceAll('0xFFFFC107', '0xFFE50914');
    file.writeAsStringSync(content);
  }
  print('Done replacing!');
}