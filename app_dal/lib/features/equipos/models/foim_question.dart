import 'package:flutter/foundation.dart';

class FoimQuestion {
  const FoimQuestion({
    required this.id,
    required this.functionLabel,
    required this.question,
    required this.target,
  });

  final int id;
  final String functionLabel;
  final String question;
  final int target;

  factory FoimQuestion.fromMap(Map<String, dynamic> map) {
    return FoimQuestion(
      id: _asInt(map['id']),
      functionLabel: _asString(map['function']),
      question: _asString(map['question']),
      target: _asInt(map['target']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    final s = value.toString();
    return s.trim();
  }
}

class Foim03Answer {
  const Foim03Answer({
    required this.questionId,
    required this.answer,
    required this.description,
  });

  final int questionId;
  final String answer; // "B" or "M"
  final String description;

  Map<String, dynamic> toJson() {
    return {
      'foim_question_id': questionId,
      'answer': answer,
      'description': description,
      'status': 'Nuevo',
    };
  }
}
