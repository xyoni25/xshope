import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ProductState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XShope - Product Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
          secondary: Colors.orangeAccent,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent,
          brightness: Brightness.dark,
          secondary: Colors.orangeAccent,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const ProductShowcase(),
    );
  }
}

class ProductState extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> get products => _products;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Set<String> _favorites = {};
  Set<String> get favorites => _favorites;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  List<String> _categories = ['All'];
  List<String> get categories => _categories;

  List<Product> get filteredProducts {
    return _products.where((product) {
      // Filter by category
      if (_selectedCategory != 'All' && product.category != _selectedCategory) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return product.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            product.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }

      return true;
    }).toList();
  }

  ProductState() {
    loadProducts();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorites') ?? [];
    _favorites = Set<String>.from(favList);
    notifyListeners();
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites.toList());
  }

  void toggleFavorite(String productName) {
    if (_favorites.contains(productName)) {
      _favorites.remove(productName);
    } else {
      _favorites.add(productName);
    }
    saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String productName) {
    return _favorites.contains(productName);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Updated to use your actual GitHub repository
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/xyoni25/xshope/main/products.json',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = jsonDecode(response.body);
        _products = productsJson.map((json) => Product.fromJson(json)).toList();

        // Extract categories
        final Set<String> categorySet = {'All'};
        for (var product in _products) {
          if (product.category != null) {
            categorySet.add(product.category!);
          }
        }
        _categories = categorySet.toList();

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage =
            'Failed to load products. Status code: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error loading products: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}

class Product {
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final double rating;
  final String? category;
  final bool inStock;
  final List<String>? features;

  Product({
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.rating,
    this.category,
    this.inStock = true,
    this.features,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      category: json['category'] as String?,
      inStock: json['inStock'] as bool? ?? true,
      features: json['features'] != null
          ? List<String>.from(json['features'] as List)
          : null,
    );
  }
}

class ProductShowcase extends StatefulWidget {
  const ProductShowcase({super.key});

  @override
  State<ProductShowcase> createState() => _ProductShowcaseState();
}

class _ProductShowcaseState extends State<ProductShowcase> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = Provider.of<ProductState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'XSHOPE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(productState),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              productState.loadProducts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing products...')),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.shopping_bag,
                      size: 40,
                      color: Colors.teal,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'XShope Store',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Categories',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ...productState.categories
                .map(
                  (category) => ListTile(
                    dense: true,
                    title: Text(category),
                    selected: productState.selectedCategory == category,
                    onTap: () {
                      productState.setCategory(category);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'XShope',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.shopping_bag),
                  children: [
                    const Text(
                      'A product showcase app with products hosted on GitHub and deployed via Netlify.',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: _selectedIndex == 0
          ? _buildHomeScreen(productState)
          : _buildFavoritesScreen(productState),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(ProductState productState) {
    if (productState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productState.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(productState.errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => productState.loadProducts(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Opacity(
                      opacity: 0.2,
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/assets/banner.jpg',
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Featured Products',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover our exclusive collection',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Scroll to products
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Explore Now'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  productState.selectedCategory == 'All'
                      ? 'All Products'
                      : productState.selectedCategory,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: productState.selectedCategory,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      productState.setCategory(newValue);
                    }
                  },
                  items: productState.categories.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        productState.filteredProducts.isEmpty
            ? const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No products available',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = productState.filteredProducts[index];
                    return ProductCard(product: product);
                  }, childCount: productState.filteredProducts.length),
                ),
              ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Our Products',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All products are carefully selected and curated to ensure the highest quality. We pride ourselves on offering unique items that stand out from the crowd.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final Uri url = Uri.parse(
                        'https://github.com/YOUR_USERNAME/YOUR_REPO',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open repository'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.code),
                    label: const Text('View Repository'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesScreen(ProductState productState) {
    final favoriteProducts = productState.products
        .where((product) => productState.isFavorite(product.name))
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

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final productState = Provider.of<ProductState>(context);
    final isFavorite = productState.isFavorite(product.name);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                      ),
                      onPressed: () {
                        productState.toggleFavorite(product.name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavorite
                                  ? '${product.name} removed from favorites'
                                  : '${product.name} added to favorites',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        product.rating.toString(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Center(
                child: Text(
                  'View Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final productState = Provider.of<ProductState>(context);
    final isFavorite = productState.isFavorite(product.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            color: Colors.red,
            onPressed: () {
              productState.toggleFavorite(product.name);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            product.rating.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.category != null) ...[
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(product.category!),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (product.features != null &&
                      product.features!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...product.features!
                        .map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate {
  final ProductState productState;

  ProductSearchDelegate(this.productState);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = productState.products.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.description.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (query.isEmpty) {
      return const Center(child: Text('Type to search for products'));
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: const TextStyle(fontSize: 18),
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
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ProductCard(product: results[index]);
      },
    );
  }
}
