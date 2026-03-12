import '../../../core/data/api_response_model.dart';
import '../../../core/utils/shared_preference_helper.dart';
import '../service/auth/auth_remote_service.dart';
import '../types/employment_types.dart';

class UserRepository {
  final AuthRemoteService authService;

  UserRepository({
    required this.authService,
  });

  bool isUserManager() {
    return SharedPreferenceHelper.getInt(PreferenceKeys.userEmploymentType) ==
        EmploymentTypes.SALES_MANAGER;
  }

  void setUserEmploymentType(int? type) async {
    await SharedPreferenceHelper.setInt(
        PreferenceKeys.userEmploymentType, type ?? EmploymentTypes.SALES_REP);
  }

  Future<ApiResponseModel> logout() async {
    return await authService.logout();
  }
}
