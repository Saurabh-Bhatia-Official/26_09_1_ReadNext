import 'package:flutter/material.dart';

enum FormFieldType {
  text,
  checkbox,
  dropdown,
}

class PdfFormFieldModel {
  final String id;
  final int pageNumber;
  final String name;
  final FormFieldType type;
  final String value;
  final Rect rect;
  final List<String> options;

  const PdfFormFieldModel({
    required this.id,
    required this.pageNumber,
    required this.name,
    required this.type,
    required this.value,
    required this.rect,
    this.options = const [],
  });

  PdfFormFieldModel copyWith({
    String? id,
    int? pageNumber,
    String? name,
    FormFieldType? type,
    String? value,
    Rect? rect,
    List<String>? options,
  }) {
    return PdfFormFieldModel(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      rect: rect ?? this.rect,
      options: options ?? this.options,
    );
  }
}
