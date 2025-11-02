import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_state.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productState = Provider.of<ProductState>(context);
    
    final favoriteProducts = productState.products
        .where((product) => productState.isFavorite(product.id))
        .toList();

    if (favoriteProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No favorites yet', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(
              'Add some products to your favorites',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: favoriteProducts.length,
      itemBuilder: (context, index) {
        return ProductCard(product: favoriteProducts[index]);
      },
    );
  }
}