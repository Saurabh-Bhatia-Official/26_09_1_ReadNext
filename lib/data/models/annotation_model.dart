import 'dart:convert';
import 'package:flutter/material.dart';

enum AnnotationType {
  highlight,
  underline,
  strikethrough,
  textBox,
  ink,
  stickyNote,
  rectangle,
  circle,
  line,
  arrow,
  signature,
  stamp,
}

class DrawingPoint {
  final double x;
  final double y;

  const DrawingPoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory DrawingPoint.fromJson(Map<String, dynamic> json) =>
      DrawingPoint((json['x'] as num).toDouble(), (json['y'] as num).toDouble());

  Offset toOffset() => Offset(x, y);
}

class AnnotationModel {
  final String id;
  final String documentPath;
  final int pageNumber;
  final AnnotationType type;
  final Color color;
  final double opacity;
  final double strokeWidth;
  final Rect rect;
  final List<DrawingPoint> points;
  final String text;
  final String author;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnotationModel({
    required this.id,
    required this.documentPath,
    required this.pageNumber,
    required this.type,
    required this.color,
    this.opacity = 1.0,
    this.strokeWidth = 2.0,
    required this.rect,
    this.points = const [],
    this.text = '',
    this.author = 'User',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AnnotationModel copyWith({
    String? id,
    String? documentPath,
    int? pageNumber,
    AnnotationType? type,
    Color? color,
    double? opacity,
    double? strokeWidth,
    Rect? rect,
    List<DrawingPoint>? points,
    String? text,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnotationModel(
      id: id ?? this.id,
      documentPath: documentPath ?? this.documentPath,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      rect: rect ?? this.rect,
      points: points ?? this.points,
      text: text ?? this.text,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentPath': documentPath,
      'pageNumber': pageNumber,
      'type': type.name,
      'color': color.toARGB32(),
      'opacity': opacity,
      'strokeWidth': strokeWidth,
      'rect': {
        'left': rect.left,
        'top': rect.top,
        'right': rect.right,
        'bottom': rect.bottom,
      },
      'points': points.map((p) => p.toJson()).toList(),
      'text': text,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AnnotationModel.fromJson(Map<String, dynamic> json) {
    final rectMap = json['rect'] as Map<String, dynamic>;
    final rect = Rect.fromLTRB(
      (rectMap['left'] as num).toDouble(),
      (rectMap['top'] as num).toDouble(),
      (rectMap['right'] as num).toDouble(),
      (rectMap['bottom'] as num).toDouble(),
    );

    final pointsList = (json['points'] as List<dynamic>?)
            ?.map((p) => DrawingPoint.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return AnnotationModel(
      id: json['id'] as String,
      documentPath: json['documentPath'] as String,
      pageNumber: json['pageNumber'] as int,
      type: AnnotationType.values.byName(json['type'] as String),
      color: Color(json['color'] as int),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      rect: rect,
      points: pointsList,
      text: json['text'] as String? ?? '',
      author: json['author'] as String? ?? 'User',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory AnnotationModel.fromJsonString(String str) =>
      AnnotationModel.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
