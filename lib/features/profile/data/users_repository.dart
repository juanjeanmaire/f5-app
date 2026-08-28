import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../auth/domain/user.dart';

class UsersRepository {
  UsersRepository(this._dio);

  final Dio _dio;

  Future<AppUser> updateProfile({String? name, String? nickname, String? avatarUrl}) async {
    try {
      final response = await _dio.patch(
        '/users/me',
        data: {
          if (name != null) 'name': name,
          if (nickname != null) 'nickname': nickname,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/users/me/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return UsersRepository(dio);
});
