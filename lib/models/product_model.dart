class ProductModel {
  final int id;
  final String name;
  final String slug;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final String description;
  final String shortDescription;
  final String imageUrl;
  final String stockStatus;
  final List<String> categories;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.description,
    required this.shortDescription,
    required this.imageUrl,
    required this.stockStatus,
    required this.categories,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String img = '';
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      img = json['images'][0]['src'] ?? '';
    }

    List<String> cats = [];
    if (json['categories'] != null) {
      for (var cat in json['categories']) {
        cats.add(cat['name']?.toString() ?? '');
      }
    }

    // Clean html tags from short description
    String cleanShortDesc = (json['short_description'] ?? '')
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
        .trim();

    return ProductModel(
      id: json['id'] ?? 0,
      name: (json['name'] ?? '').replaceAll('&amp;', '&'),
      slug: json['slug'] ?? '',
      price: json['price']?.toString() ?? '0',
      regularPrice: json['regular_price']?.toString() ?? '',
      salePrice: json['sale_price']?.toString() ?? '',
      onSale: json['on_sale'] ?? false,
      description: json['description'] ?? '',
      shortDescription: cleanShortDesc,
      imageUrl: img,
      stockStatus: json['stock_status'] ?? 'instock',
      categories: cats,
    );
  }

  double get priceNumeric => double.tryParse(price) ?? 0.0;
  double get regularPriceNumeric => double.tryParse(regularPrice) ?? priceNumeric;
  bool get inStock => stockStatus == 'instock';
}
