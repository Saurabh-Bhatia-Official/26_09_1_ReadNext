import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/form_field_model.dart';

class FormState {
  final Map<String, PdfFormFieldModel> fields;

  const FormState({this.fields = const {}});

  List<PdfFormFieldModel> getFieldsForPage(int page) {
    return fields.values.where((f) => f.pageNumber == page).toList();
  }

  FormState copyWith({Map<String, PdfFormFieldModel>? fields}) {
    return FormState(fields: fields ?? this.fields);
  }
}

class FormNotifier extends Notifier<FormState> {
  @override
  FormState build() {
    return const FormState();
  }

  void setFields(List<PdfFormFieldModel> newFields) {
    final map = {for (final f in newFields) f.id: f};
    state = state.copyWith(fields: map);
  }

  void updateValue(String fieldId, String value) {
    if (state.fields.containsKey(fieldId)) {
      final updated = state.fields[fieldId]!.copyWith(value: value);
      final newMap = Map<String, PdfFormFieldModel>.from(state.fields);
      newMap[fieldId] = updated;
      state = state.copyWith(fields: newMap);
    }
  }

  void clearForm() {
    state = const FormState();
  }
}

final formProvider = NotifierProvider<FormNotifier, FormState>(FormNotifier.new);
