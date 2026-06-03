import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';
import '../domain/employee_model.dart';

part 'employee_repository.g.dart';

class EmployeeRepository {
  final Dio _dio;

  EmployeeRepository(this._dio);

  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await _dio.get('/employee/');
      final List data = response.data;
      return data.map((json) => EmployeeModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<EmployeeModel> getEmployeeById(int id) async {
    try {
      final response = await _dio.get('/employee/$id');
      return EmployeeModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createEmployee(Map<String, dynamic> employeeData) async {
    try {
      await _dio.post('/employee/', data: employeeData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEmployee(int id, Map<String, dynamic> employeeData) async {
    try {
      await _dio.put('/employee/$id', data: employeeData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _dio.delete('/employee/$id');
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
EmployeeRepository employeeRepository(EmployeeRepositoryRef ref) {
  return EmployeeRepository(ref.watch(dioClientProvider));
}
