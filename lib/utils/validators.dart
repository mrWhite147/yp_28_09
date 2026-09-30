class Validators {
  static String? required(dynamic value) {
    if (value == null || (value is String && value.trim().isEmpty) || (value is List && value.isEmpty)) {
      return 'Обязательное поле';
    }
    return null;
  }

  static String? email(dynamic value) {
    if (value == null || value.toString().isEmpty) return null; 
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value.toString())) return 'Неверный формат email';
    return null;
  }

  static String? positiveNumber(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    final num = double.tryParse(value.toString().replaceAll(',', '.'));
    if (num == null) return 'Введите число';
    if (num < 0) return 'Значение не может быть отрицательным';
    return null;
  }

  static String? Function(T?) combine<T>(List<String? Function(dynamic)> validators) {
    return (T? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}