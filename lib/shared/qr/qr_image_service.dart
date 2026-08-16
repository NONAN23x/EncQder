import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'qr_style.dart';

abstract final class QrImageService {
  static Future<File> createPng(
    BuildContext context, {
    required String data,
    required String fileName,
  }) async {
    final encoded = QrStyle.encode(data);
    final bytes = await QrImage(encoded).toImageAsBytes(
      size: 1024,
      decoration: QrStyle.decoration(context),
      configuration: createLocalImageConfiguration(context),
    );
    if (bytes == null) {
      throw StateError('The QR renderer returned no image data.');
    }
    final directory = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${directory.path}/$safeName.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file;
  }
}
