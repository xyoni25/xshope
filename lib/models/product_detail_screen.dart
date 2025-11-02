import 'package:flutter/material.dart';
import 'product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Center(child: Text('Product Detail Screen Placeholder')),
    );
  }
}
