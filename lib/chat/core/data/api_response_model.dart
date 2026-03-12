class ApiResponseModel {
  final bool isSuccessful;
  final dynamic data;
  final String? message;
  final String? error;

  ApiResponseModel({
    required this.isSuccessful,
    this.data,
    this.message,
    this.error,
  });
}
