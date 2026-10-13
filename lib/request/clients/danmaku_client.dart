import 'package:dio/dio.dart';
import 'package:kazumi/request/config/api_endpoints.dart';
import 'package:kazumi/request/core/dio_factory.dart';
import 'package:kazumi/request/core/network_error_mapper.dart';
import 'package:kazumi/utils/dandan_credentials.dart';
import 'package:kazumi/utils/http_headers.dart';
import 'package:kazumi/utils/crypto.dart';

class DanmakuClient {
  DanmakuClient._();

  static final DanmakuClient instance = DanmakuClient._();
  static String get apiBase => ApiEndpoints.dandanAPIDomain;
  static bool get isConfigured =>
      dandanCredentials['id']!.isNotEmpty &&
      dandanCredentials['value']!.isNotEmpty;

  Future<void> testConnection() async {
    if (!isConfigured) throw StateError('请填写 App ID 和 App Secret');
    final data = await get(
      '$apiBase${ApiEndpoints.dandanAPISearchEpisodes}',
      queryParameters: {'anime': '青之箱', 'v2': 'true'},
    );
    if (data is! Map || data['animes'] is! List || data['success'] == false) {
      throw StateError('服务返回了无效响应');
    }
  }

  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic> headers = const {},
    CancelToken? cancelToken,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final uri = Uri.parse(url);
    final requestHeaders = <String, dynamic>{
      'user-agent': getRandomUA(),
      'referer': '',
      'X-Auth': 1,
      'X-AppId': dandanCredentials['id'],
      'X-Timestamp': timestamp,
      'X-Signature': generateDandanSignature(uri.path, timestamp),
      ...headers,
    };

    try {
      final response = await DioFactory.apiDio.get(
        url,
        queryParameters: queryParameters,
        options: Options(headers: requestHeaders),
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }
}
