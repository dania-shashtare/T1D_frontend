class ProfileModel {
  final String fullName;
  final int? age;
  final double? weight;
  final double? height;

  final String doctorName;
  final String doctorSpecialty;

  final double? breakfastDose;
  final double? lunchDose;
  final double? dinnerDose;
  final double? lantusDose;

  final String correctionFactor;
  final String carbRatio;

  final bool hasFoodAllergy;
  final String allergyDetails;

  ProfileModel({
    required this.fullName,
    this.age,
    this.weight,
    this.height,
    required this.doctorName,
    required this.doctorSpecialty,
    this.breakfastDose,
    this.lunchDose,
    this.dinnerDose,
    this.lantusDose,
    required this.correctionFactor,
    required this.carbRatio,
    required this.hasFoodAllergy,
    required this.allergyDetails,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return ProfileModel(
      fullName: json['fullName'] ?? '',
      age: json['age'],
      weight: toDouble(json['weight']),
      height: toDouble(json['height']),

      doctorName: json['doctorName'] ?? '',
      doctorSpecialty: json['doctorSpecialty'] ?? '',

      breakfastDose: toDouble(json['breakfastDose']),
      lunchDose: toDouble(json['lunchDose']),
      dinnerDose: toDouble(json['dinnerDose']),
      lantusDose: toDouble(json['lantusDose']),

      correctionFactor: json['correctionFactor']?.toString() ?? '',
      carbRatio: json['carbRatio']?.toString() ?? '',

      hasFoodAllergy: json['hasFoodAllergy'] == true,
      allergyDetails: json['allergyDetails']?.toString() ?? '',
    );
  }
}