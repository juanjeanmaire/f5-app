import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/message.dart';

class MessagesRepository {
  MessagesRepository(this._dio);

  final Dio _dio;

  /// Manda un mensaje. [memberId] solo lo usan los capitanes, para indicar
  /// a qué conversación están respondiendo — un miembro común siempre
  /// escribe en la suya, no hace falta que lo pase.
  Future<ChatMessage> sendMessage(String groupId, String body, {String? memberId}) async {
    try {
      final response = await _dio.post(
        '/groups/$groupId/messages',
        data: {'body': body, if (memberId != null) 'memberId': memberId},
      );
      return ChatMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// La conversación propia de un miembro con el/los capitán(es).
  Future<List<ChatMessage>> getMyConversation(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId/messages/mine');
      return (response.data as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// El listado de conversaciones que ve el capitán (una por miembro).
  Future<List<MessageThread>> listThreads(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId/messages/threads');
      return (response.data as List)
          .map((e) => MessageThread.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// La conversación completa con un miembro puntual (solo capitanes).
  Future<List<ChatMessage>> getConversation(String groupId, String memberId) async {
    try {
      final response = await _dio.get('/groups/$groupId/messages/$memberId');
      return (response.data as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MessagesRepository(dio);
});
