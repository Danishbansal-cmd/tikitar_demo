class ProfileModel {
  late String? firstName;
  late String? lastName;
  late String? mobile;
  late String? whatsapp;
  late String? email;
  late String? jobtitle;
  late String? address;
  late String? city;
  late String? zip;
  late String? state;

  ProfileModel({
    this.firstName,
    this.lastName,
    this.mobile,
    this.whatsapp,
    this.email,
    this.jobtitle,
    this.address,
    this.city,
    this.zip,
    this.state,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> map) {
    return ProfileModel(
      firstName: map['first_name'] ?? "empty",
      lastName: map['last_name'] ?? "empty",
      mobile: map['mobile'] ?? "0000000000",
      whatsapp: map['whatsapp'] ?? "empty",
      email: map['email'] ?? "empty",
      jobtitle: map['designation'] ?? "empty",
      address: map['address']!['line1'] ?? "empty",
      city: map['address']!['city'] ?? "empty",
      zip: map['address']!['zip'] ?? "empty",
      state: map['address']!['state'] ?? "empty",
    );
  }
}
