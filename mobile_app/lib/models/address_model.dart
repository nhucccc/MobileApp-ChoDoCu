class AddressModel {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String street;
  final String district;
  final String city;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.street,
    required this.district,
    required this.city,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id'],
        fullName: json['fullName'],
        phoneNumber: json['phoneNumber'],
        street: json['street'],
        district: json['district'],
        city: json['city'],
        isDefault: json['isDefault'] ?? false,
      );

  String get fullAddress => '$street, $district, $city';
  String get displayLine => '$fullName - $phoneNumber\n$fullAddress';
}
