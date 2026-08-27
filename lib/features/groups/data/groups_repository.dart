import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/group.dart';
import '../domain/group_membership.dart';

class GroupsRepository {
  GroupsRepository(this._dio);

  final Dio _dio;

  Future<Group> createGroup(String name) async {
    try {
      final response = await _dio.post('/groups', data: {'name': name});
      return Group.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Devuelve la membership recién creada, con el grupo anidado
  /// (el backend hace include: { group: true } en este endpoint).
  Future<GroupMembership> joinGroup(String inviteCode) async {
    try {
      final response = await _dio.post('/groups/join', data: {'inviteCode': inviteCode});
      return GroupMembership.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Group> getGroup(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId');
      return Group.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<GroupMembership>> listMyGroups() async {
    try {
      final response = await _dio.get('/groups/mine');
      return (response.data as List)
          .map((e) => GroupMembership.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Devuelve las memberships de un grupo, con el usuario anidado
  /// (el backend hace include: { user: true } en este endpoint).
  Future<List<GroupMembership>> listMembers(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId/members');
      return (response.data as List)
          .map((e) => GroupMembership.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> promoteToAdmin(String groupId, String targetUserId) async {
    try {
      await _dio.patch('/groups/$groupId/members/$targetUserId/promote');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GroupsRepository(dio);
});
