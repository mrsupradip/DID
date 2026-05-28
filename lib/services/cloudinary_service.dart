import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dbifyccnr';
  static const String _uploadPreset = 'DID_media';
  static const Duration _requestTimeout = Duration(seconds: 30);

  static Future<String> uploadImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    developer.log(
      'Starting Cloudinary image upload: ${imageFile.path}',
      name: 'CloudinaryService',
    );

    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send().timeout(_requestTimeout);
      final responseBody = await streamedResponse.stream.bytesToString();

      developer.log(
        'Cloudinary response status: ${streamedResponse.statusCode}',
        name: 'CloudinaryService',
      );
      developer.log(
        'Cloudinary response body: $responseBody',
        name: 'CloudinaryService',
      );

      if (streamedResponse.statusCode != 200 &&
          streamedResponse.statusCode != 201) {
        throw Exception(
          'Cloudinary upload failed with status ${streamedResponse.statusCode}: $responseBody',
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid Cloudinary response format.');
      }

      final secureUrl = decoded['secure_url'];
      if (secureUrl is! String || secureUrl.isEmpty) {
        throw Exception('Cloudinary did not return a secure_url.');
      }

      developer.log(
        'Cloudinary upload completed successfully: $secureUrl',
        name: 'CloudinaryService',
      );

      return secureUrl;
    } on TimeoutException catch (e) {
      developer.log(
        'Cloudinary upload timed out: $e',
        name: 'CloudinaryService',
        level: 1000,
      );
      throw Exception('Image upload timed out. Please try again.');
    } on SocketException catch (e) {
      developer.log(
        'Cloudinary upload network error: $e',
        name: 'CloudinaryService',
        level: 1000,
      );
      throw Exception('Network error while uploading image.');
    } catch (e, stackTrace) {
      developer.log(
        'Cloudinary upload failed: $e',
        name: 'CloudinaryService',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      throw Exception('Failed to upload image: $e');
    }
  }
}
