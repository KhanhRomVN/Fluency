import 'dart:convert';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:flutter/services.dart';

class CourseRepository {
  // List of known course files in assets
  static const List<String> _courseFiles = [
    // Based on what we created:
    'lib/features/course/assets/courses/Cambridge_IELTS_18/Cambridge_IELTS_18.json',
    'lib/features/course/assets/courses/Hacker_TOEIC_Start_Listening/Hacker_TOEIC_Start_Listening.json',
    'lib/features/course/assets/courses/Hacker_TOEIC_Start_Reading/Hacker_TOEIC_Start_Reading.json',
    'lib/features/course/assets/courses/Oxford_Reading_Writing_1/Oxford_Reading_Writing_1.json',
  ];

  Future<List<Course>> getCourses() async {
    final List<Course> courses = [];

    for (final filePath in _courseFiles) {
      try {
        final jsonString = await rootBundle.loadString(filePath);
        final Map<String, dynamic> jsonMap =
            json.decode(jsonString) as Map<String, dynamic>;
        courses.add(Course.fromJson(jsonMap));
      } catch (e) {
        // Log error or ignore if file doesn't exist
        print('Error loading course from $filePath: $e');
      }
    }
    return courses;
  }
}
