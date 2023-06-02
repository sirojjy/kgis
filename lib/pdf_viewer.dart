import 'package:bpjtteknik/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_plugin_pdf_viewer/flutter_plugin_pdf_viewer.dart';

class PdfViewerPage extends StatefulWidget {
  final pdfUrl;
  final pdfPath;

  PdfViewerPage({
    this.pdfUrl,
    this.pdfPath,
  });

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  bool _isLoading = true;
  PDFDocument document;

  @override
  void initState() {
    super.initState();
    loadDocument();
  }

  loadDocument() async {
    if (widget.pdfUrl == null) {
      print(widget.pdfPath);
      document = await PDFDocument.fromFile(widget.pdfPath);
    } else {
      document = await PDFDocument.fromURL(widget.pdfUrl);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.1,
        backgroundColor: colorPrimary,
        title: Text("Preview PDF"),
      ),
      body: Center(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : PDFViewer(
                  document: document,
                  showPicker: false,
                )
              ),
    );
  }
}