class ProfileModel {
  final String fullName;
  final int? age;
  final double? weight;
  final double? height;
  final String doctorName;
  final String doctorSpecialty;

  ProfileModel({
    required this.fullName,
    this.age,
    this.weight,
    this.height,
    required this.doctorName,
    required this.doctorSpecialty,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      fullName: json['fullName'] ?? '',
      age: json['age'],
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      doctorName: json['doctorName'] ?? '',
      doctorSpecialty: json['doctorSpecialty'] ?? '',
    );
  }
}