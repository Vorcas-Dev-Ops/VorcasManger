import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/document_repository.dart';
import '../domain/document_model.dart';

class DocumentListScreen extends ConsumerWidget {
  const DocumentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider);
    final employeeId = user?.employeeId ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: FutureBuilder<List<DocumentModel>>(
        future: ref.read(documentRepositoryProvider).getDocuments(employeeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) return const Center(child: Text('No documents found'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return ListTile(
                leading: Icon(_getFileIcon(doc.type), color: AppTheme.primaryAccent),
                title: Text(doc.title),
                subtitle: Text('Uploaded on: ${doc.createdAt.substring(0, 10)}'),
                trailing: IconButton(icon: const Icon(Icons.download_outlined), onPressed: () {}),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Pick file and upload
        },
        child: const Icon(Icons.upload_file),
      ),
    );
  }

  IconData _getFileIcon(String type) {
    if (type.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (type.contains('image')) return Icons.image_outlined;
    return Icons.insert_drive_file_outlined;
  }
}
