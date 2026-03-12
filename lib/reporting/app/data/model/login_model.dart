class LoginModel {
  int? status;
  String? message;
  Data? data;

  LoginModel({this.status, this.message, this.data});

  LoginModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? accessToken;
  //int? id;
  int? orgId;
  int? parentBranch;
  String? notificationId;
  String? name;
  String? email;
  String? phoneNumber;
  String? hireDate;
  int? role;
  int? status;
  int? hasAutoscheduleStarted;
  String? createdAt;
  String? updatedAt;
  String? deviceId;

  Data({
    this.accessToken,
    //this.id,
    this.orgId,
    this.parentBranch,
    this.notificationId,
    this.name,
    this.email,
    this.phoneNumber,
    this.hireDate,
    this.role,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.hasAutoscheduleStarted,
    this.deviceId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    accessToken = json['IdToken'];
    //id = json['Id'];
    orgId = json['OrganizationId'];
    parentBranch = json['ParentBranch'];
    notificationId = json['NotificationId'];
    name = json['Name'];
    email = json['Email'];
    phoneNumber = json['PhoneNumber'];
    hireDate = json['HireDate'];
    role = json['EmployeePosition'];
    status = json['Status'];
    createdAt = json['CreatedAt'];
    updatedAt = json['UpdatedAt'];
    hasAutoscheduleStarted = json['HasAutoscheduleStarted'];
    deviceId = json['DeviceId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['IdToken'] = this.accessToken;
    //data['Id'] = this.id;
    data['OrganizationId'] = this.orgId;
    data['ParentBranch'] = this.parentBranch;
    data['NotificationId'] = this.notificationId;
    data['Name'] = this.name;
    data['Email'] = this.email;
    data['PhoneNumber'] = this.phoneNumber;
    data['HireDate'] = this.hireDate;
    data['EmployeePosition'] = this.role;
    data['Status'] = this.status;
    data['CreatedAt'] = this.createdAt;
    data['UpdatedAt'] = this.updatedAt;
    data['HasAutoscheduleStarted'] = this.hasAutoscheduleStarted;
    data['DeviceId'] = this.deviceId;
    return data;
  }
}
