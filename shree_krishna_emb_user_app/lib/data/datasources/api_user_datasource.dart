import 'package:dio/dio.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

// API implementation (for future migration to Node.js/Supabase)
class ApiUserDataSource {
  final Dio _dio;
  final String _baseUrl;

  ApiUserDataSource({
    required Dio dio,
    String baseUrl = 'https://api.yourapp.com',
  }) : _dio = dio,
       _baseUrl = baseUrl;

  Future<UserModel> getUserById(String userId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/users/$userId',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return UserModel.fromApiJson(response.data);
      } else if (response.statusCode == 404) {
        throw ServerException(
          message: 'User not found',
          code: 'USER_NOT_FOUND',
        );
      } else {
        throw ServerException(
          message: 'Failed to fetch user: ${response.statusCode}',
          code: '${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Network timeout: ${e.message}');
      }
      throw ServerException(
        message: 'API Error: ${e.message}',
        code: '${e.response?.statusCode}',
        originalError: e,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to fetch user', originalError: e);
    }
  }

  Future<List<UserModel>> getAllUsers({
    int? limit,
    String? lastDocumentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': ?limit,
        'lastId': ?lastDocumentId,
      };

      final response = await _dio.get(
        '$_baseUrl/users',
        queryParameters: queryParams,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['users'] ?? [];
        return data
            .map((user) => UserModel.fromApiJson(user as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch users: ${response.statusCode}',
          code: '${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Network timeout: ${e.message}');
      }
      throw ServerException(
        message: 'API Error: ${e.message}',
        code: '${e.response?.statusCode}',
        originalError: e,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to fetch users', originalError: e);
    }
  }

  Future<UserModel> createUser(UserModel user) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/users',
        data: user.toApiJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 201) {
        return UserModel.fromApiJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to create user: ${response.statusCode}',
          code: '${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Network timeout: ${e.message}');
      }
      throw ServerException(
        message: 'API Error: ${e.message}',
        code: '${e.response?.statusCode}',
        originalError: e,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to create user', originalError: e);
    }
  }

  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/users/${user.id}',
        data: user.toApiJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return UserModel.fromApiJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update user: ${response.statusCode}',
          code: '${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Network timeout: ${e.message}');
      }
      throw ServerException(
        message: 'API Error: ${e.message}',
        code: '${e.response?.statusCode}',
        originalError: e,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to update user', originalError: e);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final response = await _dio.delete(
        '$_baseUrl/users/$userId',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to delete user: ${response.statusCode}',
          code: '${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Network timeout: ${e.message}');
      }
      throw ServerException(
        message: 'API Error: ${e.message}',
        code: '${e.response?.statusCode}',
        originalError: e,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to delete user', originalError: e);
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/users/search',
        queryParameters: {'q': query},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? [];
        return data
            .map((user) => UserModel.fromApiJson(user as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to search users: ${response.statusCode}',
          code: '${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Network timeout: ${e.message}');
      }
      throw ServerException(
        message: 'API Error: ${e.message}',
        code: '${e.response?.statusCode}',
        originalError: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to search users',
        originalError: e,
      );
    }
  }
}
