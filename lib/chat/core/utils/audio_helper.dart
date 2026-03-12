import 'dart:io';

import 'logs_helper.dart';

class AudioHelper {
  static const int maxRecordingDurationSeconds = 120;
  static const int minRecordingDurationSeconds = 1;
  static const String recordingExtension = '.m4a';
  static const String recordingMimeType = 'audio/mp4';

  /// Formats duration in seconds to mm:ss display format.
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Formats duration from Duration object to mm:ss display format.
  static String formatDurationFromDuration(Duration duration) {
    return formatDuration(duration.inSeconds);
  }

  /// Generates a recording file name with timestamp.
  static String generateRecordingFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'voice_message_$timestamp$recordingExtension';
  }

  /// Validates recording duration against minimum and maximum.
  static bool isValidRecordingDuration(int durationSeconds) {
    return durationSeconds >= minRecordingDurationSeconds &&
        durationSeconds <= maxRecordingDurationSeconds;
  }

  /// Returns the recording file path for a given directory and file name.
  static String getRecordingPath(String directory, String fileName) {
    return '$directory/$fileName';
  }

  /// Deletes a recording file safely.
  static Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      LogsHelper.debugLog('Failed to delete recording: $e',
          tag: 'AudioHelper');
      return false;
    }
  }

  /// Converts waveform data to normalized values between 0.0 and 1.0.
  static List<double> normalizeWaveform(List<double> waveform) {
    if (waveform.isEmpty) return [];
    final maxValue = waveform.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return List.filled(waveform.length, 0.0);
    return waveform.map((v) => v / maxValue).toList();
  }
}
