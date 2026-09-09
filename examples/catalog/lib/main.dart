import 'package:flutter/material.dart';

void main() => runApp(const CatalogApp());

class CatalogApp extends StatelessWidget {
  const CatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Foundation Catalog',
      home: Scaffold(
        body: Center(child: Text('Flutter Foundation catalog scaffold')),
      ),
    );
  }
}
