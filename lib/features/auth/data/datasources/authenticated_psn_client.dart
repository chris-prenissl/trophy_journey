import 'package:http/http.dart';

import 'psn_token_store.dart';

class const PsnAuthRequiredException() implements Exception {
  @override
  String toString() => 'Not signed in to PlayStation Network';
}

class AuthenticatedPsnClient({
  required final Client _innerClient,
  required final PsnTokenStore _psnTokenStore,
}) extends BaseClient {
  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final token = await _psnTokenStore.accessToken();
    if (token == null) {
      throw const PsnAuthRequiredException();
    }

    final retry = _copy(request);
    final response = await _innerClient.send(_authorized(request, token));
    if (response.statusCode != 401 || retry == null) {
      return response;
    }

    final refreshed = await _psnTokenStore.refresh();
    if (refreshed == null) {
      return response;
    }

    return _innerClient.send(_authorized(retry, refreshed));
  }

  @override
  void close() {
    _innerClient.close();
    super.close();
  }

  BaseRequest _authorized(BaseRequest request, String token) =>
      request..headers['Authorization'] = 'Bearer $token';

  Request? _copy(BaseRequest request) {
    if (request is! Request) {
      return null;
    }
    return Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = request.bodyBytes
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;
  }
}
