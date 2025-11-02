import 'package:flutter/material.dart';
import 'product_model.dart';

class AddEditProductScreen extends StatelessWidget {
  final Product? product;
  const AddEditProductScreen({Key? key, this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Center(child: Text('Add/Edit Product Screen Placeholder')),
    );
  }
}
