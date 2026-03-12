import 'package:bluebird_p2_project/reporting/app/routes/app_pages.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' as get_x;
import 'package:get/get_core/src/get_main.dart';

import '../data/api_response_model.dart';
import '../data/data_state.dart';
import '../utils/dialog_helper.dart';
import '../utils/logs_helper.dart';
import '../utils/network_helper.dart';
import '../utils/shared_preference_helper.dart';
import '../values/app_strings.dart';
import '../values/constants/api_fields.dart';
import '../values/constants/app_constants.dart';
import 'response_extensions.dart';

const String tag = "safeApiCall";

extension DioExtensions on Dio {
  // Central way to call API safely
  // Validates if the response is successful or not
  // In case of error has the ability to extract error message
  // And provides ApiResponseModel back to caller with data & message in case of success and errorMessage in case of error
  // And if useDefaultErrorHandler, shows the error message in Alert Dialog
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
          message: result.data?.data[ApiFields.message],
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
            Keys.You_are_Offline.tr, Keys.Please_connect_to_internet.tr,
            colorText: Colors.white, backgroundColor: const Color(0xFF2445CD));
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
      errorMessage = result.data[ApiFields.message];
    } on DioException catch (dioException) {
      LogsHelper.debugLog(tag: tag, "Api error: DioException");
      LogsHelper.debugLog(
          tag: tag,
          "Api error: requestOptions = ${dioException.requestOptions}");
      LogsHelper.debugLog(
          tag: tag, "Api error: response = ${dioException.response}");
      LogsHelper.debugLog(tag: tag, "Api error: type = ${dioException.type}");
      LogsHelper.debugLog(tag: tag, "Api error: error = ${dioException.error}");
      LogsHelper.debugLog(
          tag: tag, "Api error: message = ${dioException.message}");
      LogsHelper.debugLog(
          tag: tag, "Api error: stackTrace = ${dioException.stackTrace}");

      detailedError = dioException.message ?? "";
      if (dioException.type == DioExceptionType.badResponse) {
        // Received response code that is not in range of 200..299
        // Should extract error if available in response or show appropriate message
        var result = dioException.response;
        statusCode = result?.statusCode;
        if (result?.data != null) {
          if (AppConfig.testMode) {
            if (detailedError.isNotEmpty) {
              detailedError += "\n";
            }
            detailedError += ("Uri: ${dioException.requestOptions.uri}");
            detailedError += "\n\n";
            detailedError +=
                ("Headers: ${dioException.requestOptions.headers}");
            detailedError += "\n\n";
            detailedError +=
                ("QueryParams: ${dioException.requestOptions.queryParameters}");
            detailedError += "\n\n";
            detailedError +=
                ("RequestData: ${dioException.requestOptions.data}");
            detailedError += "\n\n";
            detailedError += ("Response: ${result?.data}");
          }
          if (result?.data is Map &&
              result?.data[ApiFields.message] != null &&
              statusCode != 500) {
            errorMessage = (result?.data[ApiFields.message] ?? "");
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
        // Failed to establish connection with server, probably due to server down.
        // Probable message: Couldn't process your request due to some problem with your internet connection
      }
    } on Exception catch (e) {
      // errorMessage = e.toString();
    } catch (error) {
      // errorMessage = error.toString();
    }

    if (useDefaultErrorHandler) {
      Function()? onSessionExpire;
      if (statusCode == 401) {
        onSessionExpire = () {
          try {
            SharedPreferenceHelper.clear();
            get_x.Get.offAllNamed(AppRoutes.SIGN_IN);
          } catch (error) {}
        };
      }
      if (statusCode == 403) {
        onSessionExpire = () {
          try {
            SharedPreferenceHelper.clear();
            get_x.Get.offAllNamed(AppRoutes.SIGN_IN);
          } catch (error) {}
        };
      }
      if (AppConfig.testMode) {
        DialogHelper.showSimpleMessageWithTestMode(
          'Alert',
          (customErrorMessage ?? errorMessage),
          testModeMessage: detailedError,
          onTap: onSessionExpire,
        );
      } else {
        DialogHelper.showSimpleMessage(
          Keys.Message.tr,
          (customErrorMessage ?? errorMessage),
          onTap: onSessionExpire,
        );
      }
    }

    return DataFailed(error: errorMessage);
  }
}
