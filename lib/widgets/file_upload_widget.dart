// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class FileUploadWidget extends StatelessWidget {
//   final String role; // "supervisor" or "student"
//   final String? uploadedFileName;
//   final String? uploadedFileUrl;
//   final VoidCallback onUpload;

//   const FileUploadWidget({
//     super.key,
//     required this.role,
//     this.uploadedFileName,
//     this.uploadedFileUrl,
//     required this.onUpload,
//   });

//   Future<void> _openFile(String url) async {
//     final uri = Uri.parse(url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       throw Exception("Could not launch $url");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (uploadedFileName != null)
//           Card(
//             elevation: 2,
//             margin: const EdgeInsets.only(bottom: 8),
//             child: ListTile(
//               title: Text(
//                 "Uploaded: $uploadedFileName",
//                 style: const TextStyle(fontSize: 14),
//               ),
//               trailing: uploadedFileUrl != null
//                   ? IconButton(
//                       icon: const Icon(Icons.download, color: Colors.blue),
//                       onPressed: () => _openFile(uploadedFileUrl!),
//                     )
//                   : null,
//             ),
//           ),
//         ElevatedButton.icon(
//           style: ElevatedButton.styleFrom(
//             backgroundColor:
//                 role == "supervisor" ? Colors.teal : Colors.deepPurple,
//           ),
//           onPressed: onUpload,
//           icon: const Icon(Icons.upload, color: Colors.white),
//           label: Text(
//             "Upload (${role.toUpperCase()})",
//             style: const TextStyle(color: Colors.white),
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FileUploadWidget extends StatelessWidget {
  final String role; // "supervisor" or "student"
  final String? uploadedFileName;
  final String? uploadedFileUrl;
  final VoidCallback onUpload;

  const FileUploadWidget({
    super.key,
    required this.role,
    this.uploadedFileName,
    this.uploadedFileUrl,
    required this.onUpload,
  });

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ Prevents overflow
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (uploadedFileName != null)
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                "Uploaded: $uploadedFileName",
                style: const TextStyle(fontSize: 14),
                overflow:
                    TextOverflow.ellipsis, // ✅ Prevents long name overflow
                maxLines: 1,
              ),
              trailing:
                  uploadedFileUrl != null
                      ? IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        onPressed: () => _openFile(uploadedFileUrl!),
                      )
                      : null,
            ),
          ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                role == "supervisor" ? Colors.teal : Colors.deepPurple,
          ),
          onPressed: onUpload,
          icon: const Icon(Icons.upload, color: Colors.white),
          label: Text(
            "Upload (${role.toUpperCase()})",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
