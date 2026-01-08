import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Imports de Syncfusion
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';

class ReporteScreen extends StatefulWidget {
  const ReporteScreen({
    super.key,
    this.format,
    this.serviceId,
    this.reportUrl,
  }) : assert(
          (reportUrl != null) || (format != null && serviceId != null),
          'Define reportUrl or both format and serviceId',
        );

  final String? format;
  final int? serviceId;
  final String? reportUrl;

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  // WebView
  late final WebViewController _webViewController;
  
  // Estado
  String? _pdfPath;
  bool _isDownloading = false;
  bool _isPdfReady = false;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _cleanTempFile();
    super.dispose();
  }

  void _initWebView() {
    final url = Uri.parse(_resolveReportUrl());

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..addJavaScriptChannel(
        'FlutterPdfChannel',
        onMessageReceived: (message) {
          _handlePdfMessage(message.message);
        },
      )
      ..loadRequest(url);
  }

  Future<void> _handlePdfMessage(String base64Data) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final cleanBase64 = base64Data.replaceAll('\n', '').replaceAll('\r', '');
      final bytes = base64.decode(cleanBase64);
      
      final dir = await getTemporaryDirectory();
      // Nombre único para evitar caché
      final safeId = (widget.serviceId ?? widget.reportUrl.hashCode).abs();
      final fileName = 'reporte_${safeId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      setState(() {
        _pdfPath = file.path;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar PDF: $e')),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _cleanTempFile() async {
    final path = _pdfPath;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignorar errores de limpieza
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPdf = _pdfPath != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte'),
        actions: [
          if (showPdf)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _pdfPath = null;
                  _isPdfReady = false;
                });
                _webViewController.reload();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // 1. WebView (Oculto o cargando)
          if (!showPdf)
            WebViewWidget(controller: _webViewController),

          // 2. Visor PDF Profesional (Syncfusion)
          if (showPdf)
            SfPdfViewerTheme(
              // AQUÍ PERSONALIZAS EL COLOR DE FONDO (Gris Oscuro)
              data: SfPdfViewerThemeData(
                backgroundColor: const Color(0xFF212121),
                progressBarColor: Colors.orange, // Opcional: Color de carga
              ),
              child: SfPdfViewer.file(
                File(_pdfPath!),
                
                // Configuración Visual
                pageLayoutMode: PdfPageLayoutMode.continuous, // Scroll vertical continuo
                pageSpacing: 8, // Espacio entre páginas (8px)
                canShowScrollHead: true, // Muestra burbuja con # de página al hacer scroll rápido
                
                onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                  setState(() {
                    _totalPages = details.document.pages.count;
                    _isPdfReady = true;
                  });
                },
                onPageChanged: (PdfPageChangedDetails details) {
                  setState(() {
                    // Syncfusion devuelve la página base 1
                    _currentPage = details.newPageNumber;
                  });
                },
              ),
            ),

          // 3. Indicador de carga (Overlay)
          if (_isDownloading || (!showPdf && !_isPdfReady))
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Generando reporte PDF...", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

          // 4. Indicador de Página (Flotante)
          if (showPdf && _isPdfReady)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Página $_currentPage de $_totalPages',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _resolveReportUrl() {
    if (widget.reportUrl != null) return widget.reportUrl!;
    return 'https://ddg.com.mx/dashboard/${widget.format}/${widget.serviceId}/reporte';
  }
}