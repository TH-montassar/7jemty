class SalonModel {
  final int id;
  final int patronId;
  final String name;
  final String? description;
  final String? address;
  final String distance;
  final String image;
  final String rating;

  SalonModel({
    required this.id,
    required this.patronId,
    required this.name,
    this.description,
    this.address,
    required this.distance,
    required this.image,
    required this.rating,
  });

  factory SalonModel.fromJson(Map<String, dynamic> json) {
    return SalonModel(
      id: json['id'] ?? 0,
      patronId: json['patronId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'],
      distance: json['distance'] ?? 'Unknown',
      image:
          json['image'] ??
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
      rating: json['rating'] ?? '4.5',
    );
  }
}
