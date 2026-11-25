class ApiErrorResponse {
  final String? timestamp;
  final int status;
  final String? error;
  final String? message;
  final Map<String, String> fieldErrors;

  const ApiErrorResponse({
    this.timestamp,
    required this.status,
    this.error,
    this.message,
    this.fieldErrors = const {},
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fieldErrors'];
    final fields = <String, String>{};
    if (rawFields is Map) {
      for (final entry in rawFields.entries) {
        fields[entry.key.toString()] = entry.value.toString();
      }
    }

    return ApiErrorResponse(
      timestamp: json['timestamp']?.toString(),
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse(json['status']?.toString() ?? '') ?? 0,
      error: json['error']?.toString(),
      message: json['message']?.toString(),
      fieldErrors: fields,
    );
  }
}
