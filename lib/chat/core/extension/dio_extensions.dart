import 'package:dio/dio.dart';
import 'package:get/get.dart' as get_x;
import 'package:get/get_core/src/get_main.dart';

import '../../app/routes/app_pages.dart';
import '../theme/color.dart';
import '../data/api_response_model.dart';
import '../data/data_state.dart';
import '../utils/dialog_helper.dart';
import '../utils/logs_helper.dart';
import '../utils/network_helper.dart';
import '../utils/shared_preference_helper.dart';
import '../values/app_strings.dart';
import '../values/constants/app_constants.dart';
import 'response_extensions.dart';

const String _tag = "safeApiCall";

extension DioExtensions on Dio {
  Future<ApiResponseModel> safeApiCall({
    required Future<Response> Function() request,
    bool useDefaultErrorHandler = true,
    String? customErrorMessage,
  }) async {
    var result = await safeApiResponseCall(
        request: request, useDefaultErrorHandler: useDefaultErrorHandler);
    switch (result) {
      case DataSuccess<Response>():
        return ApiResponseModel(
          isSuccessful: true,
          data: result.data?.data,
          message: result.data?.data is Map
              ? result.data?.data['message']
              : null,
        );
      case DataFailed():
        return ApiResponseModel(isSuccessful: false, error: result.error);
    }
  }

  Future<DataState<Response>> safeApiResponseCall({
    required Future<Response> Function() request,
    bool useDefaultErrorHandler = true,
    String? customErrorMessage,
  }) async {
    var hasNetwork = await NetworkHelper.hasNetworkConnection();

    if (!hasNetwork) {
      if (useDefaultErrorHandler) {
        Get.snackbar(
          Keys.You_are_Offline.tr,
          Keys.Please_connect_to_internet.tr,
          colorText: AppColor.white,
          backgroundColor: AppColor.primary,
        );
      }
      return DataFailed(error: Keys.Please_connect_to_internet.tr);
    }

    String errorMessage = Keys.Some_error_occurred.tr;
    String detailedError = "";
    int? statusCode;
    try {
      var result = await request();
      statusCode = result.statusCode;
      if (result.isSuccessful(statusCode)) {
        return DataSuccess(data: result);
      }
      if (result.data is Map && result.data['message'] != null) {
        errorMessage = result.data['message'];
      }
    } on DioException catch (dioException) {
      LogsHelper.debugLog(tag: _tag, "Api error: DioException");
      LogsHelper.debugLog(
          tag: _tag,
          "Api error: requestOptions = ${dioException.requestOptions}");
      LogsHelper.debugLog(
          tag: _tag, "Api error: response = ${dioException.response}");
      LogsHelper.debugLog(
          tag: _tag, "Api error: type = ${dioException.type}");
      LogsHelper.debugLog(
          tag: _tag, "Api error: error = ${dioException.error}");
      LogsHelper.debugLog(
          tag: _tag, "Api error: message = ${dioException.message}");

      detailedError = dioException.message ?? "";
      if (dioException.type == DioExceptionType.badResponse) {
        var result = dioException.response;
        statusCode = result?.statusCode;
        if (result?.data != null) {
          if (DebugConfig.testMode) {
            if (detailedError.isNotEmpty) detailedError += "\n";
            detailedError += "Uri: ${dioException.requestOptions.uri}";
            detailedError += "\n\n";
            detailedError +=
                "Headers: ${dioException.requestOptions.headers}";
            detailedError += "\n\n";
            detailedError +=
                "QueryParams: ${dioException.requestOptions.queryParameters}";
            detailedError += "\n\n";
            detailedError +=
                "RequestData: ${dioException.requestOptions.data}";
            detailedError += "\n\n";
            detailedError += "Response: ${result?.data}";
          }
          if (result?.data is Map &&
              result?.data['message'] != null &&
              statusCode != 500) {
            errorMessage = result?.data['message'] ?? "";
          } else if (statusCode == 401) {
            errorMessage = Keys.Session_Expired.tr;
          } else {
            errorMessage += "\nError Code = $statusCode";
          }
        }
      }

      if (dioException.type == DioExceptionType.connectionError) {
        errorMessage = Keys
            .Unable_to_process_your_request_due_to_poor_internet_connection.tr;
      }
    } on Exception catch (_) {
      // Swallow exception, use default error message
    } catch (_) {
      // Swallow error, use default error message
    }

    if (useDefaultErrorHandler) {
      Function()? onSessionExpire;
      if (statusCode == 401 || statusCode == 403) {
        onSessionExpire = () {
          try {
            SharedPreferenceHelper.clear();
            get_x.Get.offAllNamed(ChatAppRoutes.SIGN_IN);
          } catch (_) {}
        };
      }
      DialogHelper.showSimpleMessage(
        Keys.Message.tr,
        customErrorMessage ?? errorMessage,
        onTap: onSessionExpire,
      );
    }

    return DataFailed(error: errorMessage);
  }
}
