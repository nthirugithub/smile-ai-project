import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

import 'api_service.dart';

class BackupService {

  static Future<Map<String, dynamic>> backupReports({
    required int userId,
  }) async {
    try {

      final response = await ApiService.getReports(
        userId: userId,
      );

      if (!response['success']) {
        return response;
      }
      final backupData = {
        'app': 'SmileSync',
        'version': '1.0',
        'backup_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'total_reports': response['reports'].length,
        'reports': response['reports'],
      };

      final jsonString = const JsonEncoder.withIndent('  ')
          .convert(backupData);
      final bytes = Uint8List.fromList(
        utf8.encode(jsonString),
      );
      await FileSaver.instance.saveFile(
        name: 'SmileSync_Backup',
        bytes: bytes,
        ext: 'json',
        mimeType: MimeType.other,
      );

      return {
        'success': true,
        'message': 'Backup completed successfully.',
      };


    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }

  }

}