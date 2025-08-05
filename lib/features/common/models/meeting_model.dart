class MeetingModel {
  final int? id;
  final int? clientId;
  final int? userId;
  final String? contactEmail;
  final String? contactMobile;
  final String? comments;
  final String? latitude;
  final String? longitude;
  final String? meetingDate;
  final String? notes;
  final String? visited;
  final String? visitingCard;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Client? client;

  MeetingModel({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.contactEmail,
    required this.contactMobile,
    required this.comments,
    required this.latitude,
    required this.longitude,
    required this.meetingDate,
    required this.notes,
    required this.visited,
    required this.visitingCard,
    required this.createdAt,
    required this.updatedAt,
    required this.client,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'],
      clientId: json['client_id'],
      userId: json['user_id'],
      contactEmail: json['contact_person_email'],
      contactMobile: json['contact_person_mobile'],
      comments: json['comments'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      meetingDate: json['meeting_date'],
      notes: json['notes'],
      visited: json['visited'],
      visitingCard: json['visiting_card'],
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
      client: json['client'] != null ? Client.fromJson(json['client']) : null,
    );
  }
}


class Client {
  final int id;
  final int userId;
  final int companyId;
  final int categoryId;
  final String name;

  Client({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.categoryId,
    required this.name,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? 'Not Known',
    );
  }
}



