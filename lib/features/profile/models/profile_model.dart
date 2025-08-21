class ProfileModel {
  final String firstName;
  final String lastName;
  final int id;
  final String role;
  final String mobile;
  final String whatsapp;
  final String email;
  final String jobtitle;
  final String address;
  final String city;
  final String zip;
  final String state;

  ProfileModel({
    required this.firstName,
    required this.lastName,
    required this.id,
    required this.role,
    required this.mobile,
    required this.whatsapp,
    required this.email,
    required this.jobtitle,
    required this.address,
    required this.city,
    required this.zip,
    required this.state,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> map) {
    return ProfileModel(
      firstName: map['first_name'] ?? "empty",
      lastName: map['last_name'] ?? "empty",
      id: map['id'] ?? "empty",
      role: map['role'] ?? "empty",
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
  
  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'role': role,
    'mobile': mobile,
    'whatsapp': whatsapp,
    'email': email,
    'jobtitle': jobtitle,
    'address': address,
    'city': city,
    'zip': zip,
    'state': state,
  };
}
