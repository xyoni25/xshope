import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_state.dart';
import '../providers/product_state.dart';
import '../widgets/product_search_delegate.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'my_products_screen.dart';
import 'profile_screen.dart';
import 'add_edit_product_screen.dart';

class ProductShowcase extends StatefulWidget {
  const ProductShowcase({super.key});

  @override
  State<ProductShowcase> createState() => _ProductShowcaseState();
}

class _ProductShowcaseState extends State<ProductShowcase> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final productState = Provider.of<ProductState>(context);
    final authState = Provider.of<AuthState>(context);

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
            UserAccountsDrawerHeader(
              accountName: Text(
                authState.userProfile?.name ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(authState.userProfile?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: authState.userProfile?.photoUrl != null
                    ? NetworkImage(authState.userProfile!.photoUrl!)
                    : null,
                child: authState.userProfile?.photoUrl == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
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
              leading: const Icon(Icons.store),
              title: const Text('My Products'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
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
                  applicationVersion: '2.0.0',
                  applicationIcon: const Icon(Icons.shopping_bag),
                  children: [
                    const Text(
                      'A marketplace app where users can buy and sell products.',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Create an account to start selling your own products!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await authState.logout();
              },
            ),
          ],
        ),
      ),
      body: _getSelectedScreen(),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditProductScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
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
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'My Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const FavoritesScreen();
      case 2:
        return const MyProductsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }
}