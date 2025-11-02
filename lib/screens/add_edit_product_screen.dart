import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../providers/auth_state.dart';
import '../providers/product_state.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _inStock = true;
  final List<TextEditingController> _featureControllers = [];
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isPickingImage = false; // Flag to prevent multiple image picker calls

  // Modern color scheme matching login screen
  static const primaryColor = Color(0xFF00BFA5); // Teal green
  static const secondaryColor = Color(0xFF1DE9B6); // Light teal
  static const accentColor = Color(0xFFFF8F00); // Amber
  static const backgroundColor = Color(0xFFF5F5F5); // Off-white
  static const textColor = Color(0xFF263238); // Dark blue-grey

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _descriptionController.text = widget.product!.description;
      _selectedCategory = widget.product!.category;
      _inStock = widget.product!.inStock;
      _imageUrl = widget.product!.imageUrl;

      if (widget.product!.features != null) {
        for (var feature in widget.product!.features!) {
          final controller = TextEditingController(text: feature);
          _featureControllers.add(controller);
        }
      }
    }

    if (_featureControllers.isEmpty) {
      _addFeatureField();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    for (var controller in _featureControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addFeatureField() {
    setState(() {
      _featureControllers.add(TextEditingController());
    });
  }

  void _removeFeatureField(int index) {
    setState(() {
      _featureControllers[index].dispose();
      _featureControllers.removeAt(index);
    });
  }

  Future<void> _selectImage() async {
    // Prevent multiple simultaneous calls to image picker
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image for faster uploads
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product image'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authState = Provider.of<AuthState>(context, listen: false);
    final productState = Provider.of<ProductState>(context, listen: false);

    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to add products'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Upload image if new one selected
      String imageUrl = _imageUrl ?? '';
      if (_imageFile != null) {
        final uploadedUrl = await productState
            .uploadProductImage(_imageFile!, authState.user!.uid)
            .timeout(const Duration(seconds: 30));

        if (uploadedUrl == null) {
          throw Exception('Failed to upload image');
        }

        imageUrl = uploadedUrl;
      }

      // Filter out empty feature fields
      final features = _featureControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final price = double.tryParse(_priceController.text) ?? 0.0;

      bool success;
      if (widget.product == null) {
        // Create new product
        final newProduct = Product(
          id: '', // Will be set by Firestore
          name: _nameController.text.trim(),
          price: price,
          description: _descriptionController.text.trim(),
          imageUrl: imageUrl,
          rating: 0.0, // Default rating for new products
          category: _selectedCategory,
          inStock: _inStock,
          features: features.isNotEmpty ? features : null,
          sellerId: authState.user!.uid,
          sellerName: authState.userProfile?.name ?? 'Unknown',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        success = await productState.addProduct(newProduct);
      } else {
        // Update existing product
        final updatedProduct = widget.product!.copyWith(
          name: _nameController.text.trim(),
          price: price,
          description: _descriptionController.text.trim(),
          imageUrl: imageUrl,
          category: _selectedCategory,
          inStock: _inStock,
          features: features.isNotEmpty ? features : null,
        );

        success = await productState.updateProduct(updatedProduct);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Product added successfully'
                  : 'Product updated successfully',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productState.errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productState = Provider.of<ProductState>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Add Product' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Image picker section with improved styling
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: const [
                              Icon(Icons.image, color: primaryColor),
                              SizedBox(width: 8),
                              Text(
                                'Product Image',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _selectImage,
                          child: Container(
                            height: 220,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: _imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: CircularProgressIndicator(
                                              color: primaryColor,
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.error_outline,
                                                size: 40,
                                                color: Colors.red,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Error loading image',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_photo_alternate,
                                          size: 40,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Tap to add product image',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Recommended: 1200×800 pixels',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Product details section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.inventory_2, color: primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Product Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Product Name',
                            hintText: 'Enter product name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                            prefixIcon: const Icon(
                              Icons.shopping_bag,
                              color: primaryColor,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a product name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  labelText: 'Price',
                                  hintText: 'Enter price',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: backgroundColor,
                                  prefixIcon: const Icon(
                                    Icons.attach_money,
                                    color: primaryColor,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a price';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    // Allow the label to shrink on small widths to prevent overflow
                                    const Flexible(
                                      child: Text(
                                        'In Stock',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Keep the switch at the end but avoid Spacer which can cause overflow
                                    Switch(
                                      value: _inStock,
                                      onChanged: (value) {
                                        setState(() {
                                          _inStock = value;
                                        });
                                      },
                                      activeColor: primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            hintText: 'Select category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                            prefixIcon: const Icon(
                              Icons.category,
                              color: primaryColor,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          items: productState.categories
                              .where((category) => category != 'All')
                              .map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              })
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Enter product description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                            prefixIcon: const Icon(
                              Icons.description,
                              color: primaryColor,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Features section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.star, color: primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Product Features',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _addFeatureField,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _featureControllers.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _featureControllers[index],
                                      decoration: InputDecoration(
                                        labelText: 'Feature ${index + 1}',
                                        hintText: 'Enter product feature',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: backgroundColor,
                                        prefixIcon: const Icon(
                                          Icons.check_circle_outline,
                                          color: primaryColor,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle),
                                    color: Colors.red,
                                    onPressed: () => _removeFeatureField(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (_featureControllers.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No features added yet',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _saveProduct,
                      icon: Icon(
                        widget.product == null
                            ? Icons.add_shopping_cart
                            : Icons.save,
                      ),
                      label: Text(
                        widget.product == null
                            ? 'Add Product'
                            : 'Update Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
