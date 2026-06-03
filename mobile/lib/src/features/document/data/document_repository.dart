import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';
import '../domain/document_model.dart';

part 'document_repository.g.dart';

class DocumentRepository {
  final Dio _dio;

  DocumentRepository(this._dio);

  Future<List<DocumentModel>> getDocuments(int employeeId) async {
    final response = await _dio.get('/document/$employeeId');
    return (response.data as List).map((json) => DocumentModel.fromJson(json)).toList();
  }

  Future<void> uploadDocument(int employeeId, String title, String fileUrl, String type) async {
    await _dio.post('/document/upload', data: {
      'employee_id': employeeId,
      'title': title,
      'file_url': fileUrl,
      'type': type,
    });
  }
}

@riverpod
DocumentRepository documentRepository(DocumentRepositoryRef ref) {
  return DocumentRepository(ref.watch(dioClientProvider));
}
