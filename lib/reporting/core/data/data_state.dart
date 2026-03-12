import 'package:get/get.dart';

import '../values/app_strings.dart';

sealed class DataState<T> {}

class DataSuccess<T> extends DataState<T> {
  final T? data;

  DataSuccess({required this.data});
}

class DataFailed<T> extends DataState<T> {
  final String error;

  DataFailed({String? error}) : error = error ?? Keys.Some_error_occurred.tr;
}
