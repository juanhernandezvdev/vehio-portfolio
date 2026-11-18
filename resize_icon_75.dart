import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/logos/app_icon.png');
  if (!file.existsSync()) {
    print('Icon file not found');
    return;
  }
  final bytes = file.readAsBytesSync();
  var image = img.decodeImage(bytes);
  if (image == null) {
    print('Could not decode image');
    return;
  }

  // 1. Encontrar los bordes reales del logo (ignorando el fondo transparente)
  int minX = image.width, minY = image.height, maxX = 0, maxY = 0;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.a > 0) { // Si no es transparente
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (minX > maxX || minY > maxY) {
    print('Image is completely transparent');
    return;
  }

  // 2. Recortar la imagen para obtener solo el logo sin márgenes
  final cropped = img.copyCrop(image, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);

  // 3. Crear un nuevo lienzo del tamaño original (ej. 1024x1024)
  final canvasWidth = image.width;
  final canvasHeight = image.height;

  // 4. Calcular el 75% del lienzo
  final maxCanvasDim = canvasWidth < canvasHeight ? canvasWidth : canvasHeight;
  final targetMaxDim = (maxCanvasDim * 0.75).round();

  // 5. Escalar el logo recortado para que su lado mayor mida exactamente el 75%
  double scale = targetMaxDim / (cropped.width > cropped.height ? cropped.width : cropped.height);
  int targetW = (cropped.width * scale).round();
  int targetH = (cropped.height * scale).round();

  final resizedLogo = img.copyResize(cropped, width: targetW, height: targetH, interpolation: img.Interpolation.cubic);

  // 6. Pegar el logo escalado en el centro del lienzo transparente
  final newImage = img.Image(width: canvasWidth, height: canvasHeight, numChannels: 4);
  final dstX = (canvasWidth - targetW) ~/ 2;
  final dstY = (canvasHeight - targetH) ~/ 2;

  img.compositeImage(newImage, resizedLogo, dstX: dstX, dstY: dstY);

  // Guardar
  file.writeAsBytesSync(img.encodePng(newImage));
  print("Icon auto-cropped and resized to 75% successfully!");
}