import '../types/message_type.dart';

class MediaAttachmentModel {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String fileName;
  final String? mimeType;
  final int? fileSize;
  final int? width;
  final int? height;
  final int? durationInSeconds;
  final MessageType mediaType;
  final String? localPath;
  final bool isUploaded;

  MediaAttachmentModel({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.fileName,
    this.mimeType,
    this.fileSize,
    this.width,
    this.height,
    this.durationInSeconds,
    required this.mediaType,
    this.localPath,
    this.isUploaded = true,
  });

  factory MediaAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MediaAttachmentModel(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String?,
      fileSize: json['fileSize'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      durationInSeconds: json['durationInSeconds'] as int?,
      mediaType: MessageType.fromValue(json['mediaType'] as String),
      localPath: json['localPath'] as String?,
      isUploaded: json['isUploaded'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'width': width,
      'height': height,
      'durationInSeconds': durationInSeconds,
      'mediaType': mediaType.value,
      'localPath': localPath,
      'isUploaded': isUploaded,
    };
  }

  MediaAttachmentModel copyWith({
    String? id,
    String? url,
    String? thumbnailUrl,
    String? fileName,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
    int? durationInSeconds,
    MessageType? mediaType,
    String? localPath,
    bool? isUploaded,
  }) {
    return MediaAttachmentModel(
      id: id ?? this.id,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      mediaType: mediaType ?? this.mediaType,
      localPath: localPath ?? this.localPath,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  bool get isImage => mediaType == MessageType.image;
  bool get isAudio => mediaType == MessageType.audio;
  bool get isDocument => mediaType == MessageType.document;
}
