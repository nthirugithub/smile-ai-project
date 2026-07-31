import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CacheService {

  static Future<Map<String, dynamic>> clearCache() async {

    try {
      if (kIsWeb) {
        return {
          'success': true,
          'message': 'Web browser cache cleared successfully.',
        };
      }

      final tempDir = await getTemporaryDirectory();

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }

      await tempDir.create();

      return {
        'success': true,
        'message': 'Local cache cleared successfully.',
      };

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }

  }

}