import 'package:bpjtteknik/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_plugin_pdf_viewer/flutter_plugin_pdf_viewer.dart';

class HelpPage extends StatefulWidget {
  final url;

  HelpPage({
    this.url
  });

  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  bool _isLoading = true;
  PDFDocument document;

  @override
  void initState() {
    super.initState();
    loadDocument();
  }

  loadDocument() async {
      document = await PDFDocument.fromURL(widget.url);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help'),
        backgroundColor: colorPrimary,
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