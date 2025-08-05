class EmployeeReportings {
  final int id;
  final String name;
  final String email;
  final String role;
  final int companyId;
  final String firstName;
  final String lastName;
  final String designation;
  final String mobile;
  final String? profileImage;
  final Department department;
  final int reportingTo;
  final Address address;
  final Settings settings;

  EmployeeReportings({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.companyId,
    required this.firstName,
    required this.lastName,
    required this.designation,
    required this.mobile,
    this.profileImage,
    required this.department,
    required this.reportingTo,
    required this.address,
    required this.settings,
  });

  factory EmployeeReportings.fromJson(Map<String, dynamic> json) {
    return EmployeeReportings(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      companyId: json['company_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      designation: json['designation'],
      mobile: json['mobile'],
      profileImage: json['profile_image'],
      department: Department.fromJson(json['department']),
      reportingTo: json['reporting_to'],
      address: Address.fromJson(json['address']),
      settings: Settings.fromJson(json['settings']),
    );
  }
}


class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
    );
  }
}



class Address {
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? country;
  final String? zip;

  Address({
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.country,
    this.zip,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      line1: json['line1'],
      line2: json['line2'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      zip: json['zip'],
    );
  }
}



class Settings {
  final String locationInterval;
  final List<String>? assignForms;
  final int meetingTarget;
  final int callingTarget;
  final int targetCompletion;
  final String webAccess;
  final List<String>? emailReports;

  Settings({
    required this.locationInterval,
    this.assignForms,
    required this.meetingTarget,
    required this.callingTarget,
    required this.targetCompletion,
    required this.webAccess,
    this.emailReports,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      locationInterval: json['location_interval'],
      assignForms: (json['assign_forms'] as List?)?.cast<String>(),
      meetingTarget: json['meeting_target'],
      callingTarget: json['calling_target'],
      targetCompletion: json['target_completion'],
      webAccess: json['web_access'],
      emailReports: (json['email_reports'] as List?)?.cast<String>(),
    );
  }
}




