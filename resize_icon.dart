import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/logos/app_icon.png');
  if (!file.existsSync()) {
    print('Icon file not found');
    return;
  }
  final bytes = file.readAsBytesSync();
  final original = img.decodeImage(bytes);
  if (original == null) {
    print('Could not decode image');
    return;
  }

  final width = original.width;
  final height = original.height;

  // Creamos un lienzo transparente del mismo tamano
  final newImage = img.Image(width: width, height: height, numChannels: 4);

  // Escogemos el 60% del tamano original para que no corte Android
  final targetWidth = (width * 0.6).round();
  final targetHeight = (height * 0.6).round();

  // Redimensionamos la original
  final resizedOriginal = img.copyResize(original, width: targetWidth, height: targetHeight, interpolation: img.Interpolation.cubic);

  // Calculamos el centro
  final dstX = (width - targetWidth) ~/ 2;
  final dstY = (height - targetHeight) ~/ 2;

  // Pintamos la imagen redimensionada sobre nuestro nuevo lienzo transparente
  img.compositeImage(newImage, resizedOriginal, dstX: dstX, dstY: dstY);

  // Guardamos
  file.writeAsBytesSync(img.encodePng(newImage));
  print("Icon resized successfully!");
}