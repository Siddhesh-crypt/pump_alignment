class Validators {
  Validators._();

  static String? requiredDouble(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName must be a valid number';
    }
    return null;
  }

  static String? nonZeroDouble(String? value, String fieldName) {
    final base = requiredDouble(value, fieldName);
    if (base != null) return base;
    final parsed = double.parse(value!.trim());
    if (parsed == 0) return '$fieldName cannot be zero';
    return null;
  }
}