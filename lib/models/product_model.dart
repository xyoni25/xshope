import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  Product copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    bool? inStock,
    String? category,
    double? rating,
    List<String>? features,
    String? sellerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      inStock: inStock ?? this.inStock,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      features: features ?? this.features,
      sellerName: sellerName ?? this.sellerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  final String id;
  final String sellerId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final bool inStock;
  final String? category;
  final double? rating;
  final List<String>? features;
  final String? sellerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.inStock,
    this.category,
    this.rating,
    this.features,
    this.sellerName,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      inStock: data['inStock'] ?? true,
      category: data['category'],
      rating: (data['rating'] ?? 0).toDouble(),
      features: (data['features'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      sellerName: data['sellerName'],
      createdAt: (data['createdAt'] != null)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] != null)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'inStock': inStock,
      'category': category,
      'rating': rating,
      'features': features,
      'sellerName': sellerName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
