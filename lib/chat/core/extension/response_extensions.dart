import 'package:dio/dio.dart';

bool _isCodeSuccessful(int? code) {
  if (code == null) return false;
  return code >= 200 && code <= 299;
}

extension ResponseExtensions on Response {
  bool isSuccessful(int? code) {
    return _isCodeSuccessful(code);
  }
}

extension ResponseBodyExtensions on ResponseBody {
  bool isSuccessful(int? code) {
    return _isCodeSuccessful(code);
  }
}
