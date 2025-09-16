import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class CloudinaryService {
  final String cloudName = 'dcpqnspkp'; // double-check spelling

  final String uploadPreset = 'fyp_connect'; // ✅ corrected

  Future<String?> uploadFile(File file) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
    );

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mimeParts = mimeType.split('/');

    final request =
        http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            await http.MultipartFile.fromPath(
              'file',
              file.path,
              contentType: MediaType(mimeParts[0], mimeParts[1]),
              filename: path.basename(file.path),
            ),
          );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);
      return json['secure_url'];
    } else {
      print("Cloudinary upload failed: ${response.statusCode}");
      return null;
    }
  }
}
