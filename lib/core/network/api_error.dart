class ApiError implements Exception {
  final int? status;
  final String message;
  final Map<String, String> fieldErrors;
  final String kind;

  const ApiError({
    this.status,
    required this.message,
    this.fieldErrors = const {},
    required this.kind,
  });

  @override
  String toString() => message;
}
