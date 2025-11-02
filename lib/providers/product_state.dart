import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class ProductState extends ChangeNotifier {
  List<Product> _products = [];
  List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Home',
    'Sports',
    'Books',
    'Beauty',
    'Automotive',
  ];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String _errorMessage = '';
  Set<String> _favorites = {};

  List<Product> get products => _products;
  List<Product> get filteredProducts {
    if (_selectedCategory == 'All') {
      return _products;
    }
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  ProductState() {
    loadProducts();
    _loadFavorites();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      _products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();

      // Extract categories
      final Set<String> categorySet = {
        'All',
        'Electronics',
        'Clothing',
        'Home',
        'Sports',
        'Books',
        'Beauty',
        'Automotive',
      };
      for (var product in _products) {
        if (product.category != null) {
          categorySet.add(product.category!);
        }
      }
      _categories = categorySet.toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading products: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Product>> getUserProducts(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      _errorMessage = 'Error loading user products: $e';
      return [];
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('products')
          .add(product.toMap())
          .timeout(const Duration(seconds: 10));

      // Update product with generated ID
      final newProduct = Product(
        id: docRef.id,
        name: product.name,
        price: product.price,
        description: product.description,
        imageUrl: product.imageUrl,
        rating: product.rating,
        category: product.category,
        inStock: product.inStock,
        features: product.features,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );

      _products.add(newProduct);

      // Update categories if needed
      if (product.category != null && !_categories.contains(product.category)) {
        _categories.add(product.category!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          'Error adding product: ${e.toString().contains('TimeoutException') ? 'Request timed out. Please check your connection and try again.' : e}';
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .update(product.toMap());

      // Update local state
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _products[index] = product;
      }

      // Update categories if needed
      if (product.category != null && !_categories.contains(product.category)) {
        _categories.add(product.category!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating product: $e';
      return false;
    }
  }

  Future<bool> deleteProduct(String productId, String sellerId) async {
    try {
      // Check if user is the seller
      final product = _products.firstWhere((p) => p.id == productId);
      if (product.sellerId != sellerId) {
        _errorMessage = 'You can only delete your own products';
        return false;
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();

      // Update local state
      _products.removeWhere((p) => p.id == productId);

      // Remove from favorites if present
      if (_favorites.contains(productId)) {
        _favorites.remove(productId);
        _saveFavorites();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting product: $e';
      return false;
    }
  }

  Future<String?> uploadProductImage(File imageFile, String userId) async {
    try {
      // Create a unique filename
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child(fileName);

      await storageRef.putFile(imageFile).timeout(const Duration(seconds: 30));
      return await storageRef.getDownloadURL().timeout(
        const Duration(seconds: 10),
      );
    } catch (e) {
      _errorMessage =
          'Error uploading image: ${e.toString().contains('TimeoutException') ? 'Upload timed out. Please check your connection and try again.' : e}';
      return null;
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Favorites management
  bool isFavorite(String productId) {
    return _favorites.contains(productId);
  }

  void toggleFavorite(String productId) {
    if (_favorites.contains(productId)) {
      _favorites.remove(productId);
    } else {
      _favorites.add(productId);
    }
    _saveFavorites();
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList('favorites') ?? [];
      _favorites = Set<String>.from(favoritesList);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', _favorites.toList());
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }
}
