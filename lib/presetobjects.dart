import 'package:flutter/material.dart';

LocalUser currentUser = LocalUser(
  // Provide default values or initialize with a dummy user
  firstName: '',
  lastName: '',
  email: '',
  password: '',
  isAdmin: false,
  events: [],
);

class Post {
  late String title;
  late String body;
  late DateTime posted;
  late String poster;
  late String id;

  Post();

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post()
      ..id = json['id'] as String
      ..title = json['title'] as String
      ..body = json['body'] as String
      ..poster = json['poster'] as String
      ..posted = DateTime.parse(json['posted']);
  }
}

class Event {
  late String id;
  late String eventName;
  late String eventInfo;
  late double maxMembers;
  int currentMembers = 0;
  late DateTime? eventDate;
  late TimeOfDay? eventStart;
  late TimeOfDay? eventFinish;
  late List<String> attendees = [];
  late List<String> emails = [];

  // Default constructor
  Event();

  static TimeOfDay? _parseTimeOfDay(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return null;
    }
    final List<String> timeParts = timeString.split(':');
    if (timeParts.length != 2) {
      throw const FormatException('Invalid time format');
    }
    final int hour = int.tryParse(timeParts[0]) ?? 0;
    final int minute = int.tryParse(timeParts[1]) ?? 0;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const FormatException('Hour or minute out of range');
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Named constructor for JSON deserialization
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event()
      ..id = json['id'] as String
      ..eventName = json['eventName'] as String
      ..eventInfo = json['eventInfo'] as String
      ..maxMembers = json['maxMembers'] as double
      ..currentMembers = json['currentMembers'] as int
      ..eventDate = DateTime.parse(json['eventDate'])
      ..eventStart = _parseTimeOfDay(json['eventStart'])
      ..eventFinish = _parseTimeOfDay(json['eventFinish'])
      ..attendees = List<String>.from(json['attendees'])
      ..emails = List<String>.from(json['emails']);
  }
}

class LocalUser {
  String firstName;
  String lastName;
  String email;
  String password;
  bool isAdmin;
  List<String> events = [];

  LocalUser({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.isAdmin,
    required this.events,
  });
}

String timeFixer(int minutes) {
  if (minutes < 10) {
    String correctFormat = "0$minutes";
    return correctFormat;
  }
  return minutes.toString();
}
