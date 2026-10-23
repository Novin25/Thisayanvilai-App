class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final int count;
  final String? imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.count,
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String? img;
    if (json['image'] != null && json['image']['src'] != null) {
      img = json['image']['src'];
    }
    return CategoryModel(
      id: json['id'] ?? 0,
      name: (json['name'] ?? '').replaceAll('&amp;', '&'),
      slug: json['slug'] ?? '',
      count: json['count'] ?? 0,
      imageUrl: img,
    );
  }
}
