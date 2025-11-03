import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:bubbly/common/functions/debounce_action.dart';
import 'package:bubbly/common/manager/logger.dart';
import 'package:bubbly/common/manager/session_manager.dart';
import 'package:bubbly/common/service/utils/params.dart';
import 'package:bubbly/screen/session_expired_screen/session_expired_screen.dart';
import 'package:bubbly/utilities/const_res.dart';

class CancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void dispose() {
    _isCancelled = false;
  }
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final Map<CancelToken, http.Client> _activeClients = {};

  var header = {Params.apikey: apiKey};

  Future<T> call<T>({
    required String url,
    Map<String, dynamic>? param,
    CancelToken? cancelToken,
    bool cancelAuthToken = false,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    final client = http.Client();
    if (cancelToken != null && cancelToken.isCancelled) {
      _activeClients[cancelToken] = client;
    }

    Map<String, String> params = {};
    param?.removeWhere(
            (key, value) => value == null || value == 'null' || value == '');
    param?.forEach((key, value) {
      params[key] = "$value";
    });

    if (!cancelAuthToken) {
      header[Params.authToken] = SessionManager.instance.getAuthToken();
    }

    // طباعة تفاصيل الطلب كاملة
    _logFullRequest(url, header, params);

    try {
      final response =
      await client.post(Uri.parse(url), headers: header, body: params);

      // طباعة تفاصيل الاستجابة كاملة
      _logFullResponse(response);

      if (cancelToken?.isCancelled ?? false) {
        if (kDebugMode) {
          print("Request cancelled: $url");
        }
        throw Exception('Request was cancelled');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse =
        jsonDecode(response.body) as Map<String, dynamic>;

        if (decodedResponse['message'] == 'this user is freezed!') {
          DebounceAction.shared.call(() {
            Get.offAll(
                    () => const SessionExpiredScreen(type: SessionType.freeze));
          });
          return decodedResponse as T;
        }

        if (decodedResponse['status'] == false) {
          Loggers.error('API RESPONSE : ${decodedResponse['message']}');
        }

        // Use the provided `fromJson` function to parse the response
        if (fromJson != null) {
          return fromJson(decodedResponse);
        }

        // If no `fromJson` is provided, return the raw response
        return decodedResponse as T;
      } else if (response.statusCode == 401) {
        Loggers.error('Unauthorized Error 401: ${response.statusCode}');
        DebounceAction.shared.call(() {
          Get.offAll(
                  () => const SessionExpiredScreen(type: SessionType.unauthorized));
        });
        throw Exception("Unauthorized Error: ${response.statusCode}");
      } else if (response.statusCode == 404) {
        Loggers.error('Please check baseURL in const.dart file');
        throw Exception("URL Error: ${response.statusCode} - $url");
      } else {
        final errorBody = response.body;
        final errorMessage = _extractErrorMessage(errorBody);
        Loggers.error('HTTP Error: $errorMessage');
        // Handle HTTP errors
        throw Exception(
            "HTTP Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } on HttpException {
      throw Exception('Could not connect to the server');
    } on FormatException catch (e) {
      // Handle JSON decoding errors
      Loggers.error("Invalid JSON format: ${e.message}");
      throw Exception("Invalid JSON format: ${e.message}");
    } on Exception catch (e) {
      Loggers.error("Unexpected error : $e");
      rethrow;
    } finally {
      _cleanupClient(cancelToken);
    }
  }

  void _logFullRequest(String url, Map<String, String> headers, Map<String, String> params) {
    Loggers.info("========== REQUEST DETAILS ==========");
    Loggers.info("URL: $url");
    Loggers.info("METHOD: POST");
    Loggers.info("HEADERS: ${const JsonEncoder.withIndent('  ').convert(headers)}");
    Loggers.info("BODY PARAMETERS: ${params.isEmpty ? "Empty" : const JsonEncoder.withIndent('  ').convert(params)}");
    Loggers.info("====================================");
  }

  void _logFullResponse(http.Response response) {
    Loggers.info("========== RESPONSE DETAILS ==========");
    Loggers.info("STATUS CODE: ${response.statusCode}");
    Loggers.info("REASON PHRASE: ${response.reasonPhrase}");
    Loggers.info("RESPONSE HEADERS: ${const JsonEncoder.withIndent('  ').convert(response.headers)}");

    // طباعة الاستجابة مع التنسيق الجميل
    String responseBody = response.body;
    try {
      // محاولة تحويل الاستجابة إلى JSON منسق
      final decodedJson = jsonDecode(responseBody);
      String prettyJson = const JsonEncoder.withIndent('  ').convert(decodedJson);
      Loggers.info("RESPONSE BODY (JSON): \n$prettyJson");
    } catch (e) {
      // في حالة لم تكن الاستجابة JSON، اطبعها كما هي
      Loggers.info("RESPONSE BODY (RAW): \n$responseBody");
    }

    Loggers.info("RESPONSE LENGTH: ${responseBody.length} characters");
    Loggers.info("=====================================");
  }

  String _extractErrorMessage(String responseBody) {
    final regex = RegExp(
      r'<!--\s*(.*?)\s*#0 ', // Matches everything between <!-- and #0
      dotAll: true,
    );
    final match = regex.firstMatch(responseBody);
    return match?.group(1)?.trim() ??
        "Unknown error occurred: ${_shorten(responseBody)}";
  }

  /// Shortens the response body if no specific error is found
  String _shorten(String responseBody) {
    const maxLength = 100;
    return responseBody.length > maxLength
        ? "${responseBody.substring(0, maxLength)}..."
        : responseBody;
  }

  Future<T> callGet<T>({required String url}) async {
    Loggers.info("========== GET REQUEST DETAILS ==========");
    Loggers.info("URL: $url");
    Loggers.info("METHOD: GET");
    Loggers.info("==========================================");

    http.Response response =
    await http.get(Uri.parse('http://ip-api.com/json/'));

    _logFullResponse(response);

    return jsonDecode(response.body);
  }

  Future<T> multiPartCallApi<T>({
    required String url,
    Map<String, dynamic>? param,
    required Map<String, List<XFile?>> filesMap,
    Function(double percentage)? onProgress,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    final client = http.Client();
    if (cancelToken != null) {
      _activeClients[cancelToken] = client;
    }

    final request = MultipartRequest(
      'POST',
      Uri.parse(url),
      onProgress: (bytes, totalBytes) {
        if (onProgress != null) {
          onProgress(bytes / totalBytes);
        }
      },
    );

    Map<String, String> params = {};
    param?.removeWhere((key, value) => value == null || value == 'null');
    param?.forEach((key, value) {
      params[key] = "$value";
    });

    request.fields.addAll(params);
    request.headers.addAll(header);

    filesMap.forEach((keyName, files) {
      for (var xFile in files) {
        if (xFile != null && xFile.path.isNotEmpty) {
          final file = File(xFile.path);
          final multipartFile = http.MultipartFile(
              keyName, file.readAsBytes().asStream(), file.lengthSync(),
              filename: xFile.name);
          request.files.add(multipartFile);
        }
      }
    });

    // طباعة تفاصيل الطلب المتعدد الأجزاء
    _logMultipartRequest(url, request);

    try {
      final responseStream = await client.send(request);

      if (cancelToken?.isCancelled ?? false) {
        if (kDebugMode) {
          Loggers.error("Request cancelled: $url");
        }
        throw Exception('Request was cancelled');
      }

      final responseStr = await responseStream.stream.bytesToString();
      final decodedResponse = jsonDecode(responseStr) as Map<String, dynamic>;

      // طباعة تفاصيل الاستجابة للطلب المتعدد الأجزاء
      _logMultipartResponse(responseStream, responseStr, decodedResponse);

      if (decodedResponse['status'] == false) {
        Loggers.error(decodedResponse['message']);
      }
      // Use the provided `fromJson` function to parse the response
      if (fromJson != null) {
        return fromJson(decodedResponse);
      }

      // If no `fromJson` is provided, return the raw response
      return decodedResponse as T;
    } finally {
      _cleanupClient(cancelToken);
    }
  }

  void _logMultipartRequest(String url, MultipartRequest request) {
    Loggers.info("========== MULTIPART REQUEST DETAILS ==========");
    Loggers.info("URL: $url");
    Loggers.info("METHOD: POST (Multipart)");
    Loggers.info("HEADERS: ${const JsonEncoder.withIndent('  ').convert(request.headers)}");
    Loggers.info("FIELDS: ${request.fields.isEmpty ? "Empty" : const JsonEncoder.withIndent('  ').convert(request.fields)}");

    if (request.files.isNotEmpty) {
      Loggers.info("FILES:");
      for (var file in request.files) {
        Loggers.info("  - Field: ${file.field}");
        Loggers.info("    Filename: ${file.filename}");
        Loggers.info("    Length: ${file.length} bytes");
        Loggers.info("    Content-Type: ${file.contentType}");
      }
    } else {
      Loggers.info("FILES: Empty");
    }

    Loggers.info("CONTENT LENGTH: ${request.contentLength} bytes");
    Loggers.info("===============================================");
  }

  void _logMultipartResponse(http.StreamedResponse response, String responseStr, Map<String, dynamic> decodedResponse) {
    Loggers.info("========== MULTIPART RESPONSE DETAILS ==========");
    Loggers.info("STATUS CODE: ${response.statusCode}");
    Loggers.info("REASON PHRASE: ${response.reasonPhrase}");
    Loggers.info("RESPONSE HEADERS: ${const JsonEncoder.withIndent('  ').convert(response.headers)}");

    // طباعة الاستجابة مع التنسيق الجميل
    String prettyJson = const JsonEncoder.withIndent('  ').convert(decodedResponse);
    Loggers.info("RESPONSE BODY (JSON): \n$prettyJson");

    Loggers.info("RESPONSE LENGTH: ${responseStr.length} characters");
    Loggers.info("================================================");
  }

  void _cleanupClient(CancelToken? cancelToken) {
    if (cancelToken != null) {
      _activeClients[cancelToken]?.close();
      _activeClients.remove(cancelToken);
    }
  }

  Future<void> useAndDeleteFile(File file) async {
    try {
      // Use the file as needed
      Loggers.warning('File path: ${file.path}');

      // Delete the file after use
      if (await file.exists()) {
        await file.delete();
        Loggers.success('File deleted from: ${file.path}');
      }
    } catch (e) {
      Loggers.error('Error: $e');
    }
  }
}

class MultipartRequest extends http.MultipartRequest {
  MultipartRequest(
      super.method,
      super.url, {
        this.onProgress,
      });

  final void Function(int bytes, int totalBytes)? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytes = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytes += data.length;
        if (onProgress != null) {
          onProgress!(bytes, total);
        }
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}