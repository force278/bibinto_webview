import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter/platform_interface.dart'; // Импорт платформенного интерфейса
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<List<String>> _androidFilePicker(
    webview_flutter_android.FileSelectorParams params) async {
  if (params.acceptTypes.any((type) => type == 'image/*')) {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
        source: ImageSource.camera); // или ImageSource.gallery

    if (photo == null) {
      return [];
    }

    final imageData = await photo.readAsBytes();
    final compressedImage = await FlutterImageCompress.compressWithList(
      imageData,
      minWidth: 500,
      quality: 90,
    );

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/image_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final file = File(filePath);
    await file.writeAsBytes(compressedImage, flush: true);

    return [file.uri.toString()];
  }

  return [];
}

void main() {
  runApp(const MaterialApp(home: WebViewExample()));
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://bibinto.com'));
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      // Используем cast, чтобы установить обработчик выбора файлов
      final controller = (_controller.platform
          as webview_flutter_android.AndroidWebViewController);
      controller.setOnShowFileSelector(_androidFilePicker);
    }

    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
