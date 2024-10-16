import 'package:bruss/settings/init.dart';
import 'package:http/http.dart' as http;
import 'data/bruss_type.dart';
import 'dart:convert';

class ApiResponse<T> {
  final int statusCode;
  final List<T>? data;

  ApiResponse(this.statusCode, this.data);
  factory ApiResponse.error(int statusCode) => ApiResponse(statusCode, null);
  factory ApiResponse.success(List<T> data) => ApiResponse(200, data);

  bool get isSuccess => statusCode == 200;
  bool get isError => !isSuccess;
}

class BrussRequest<T extends BrussType> {
  final String endpoint;
  final T Function(Map<String, dynamic>) construct;
  final String? query;
  final dynamic Function(String raw)? deserializer;

  const BrussRequest({required this.endpoint, required this.construct, this.query, this.deserializer});

  static BrussRequest status = BrussRequest(
    endpoint: "",
    construct: (_) => BrussTypeMock.instance,
    deserializer: (_) => [],
  );
}

class BrussTypeMock extends BrussType {
  static final BrussTypeMock instance = BrussTypeMock();
}

class ApiException<T> implements Exception {
  final Object error;
  final Future<void> Function()? retry;
  ApiException(this.error, {this.retry});

  @override
  String toString() => "API Exception: $error";

  ApiException<T> attachRetry(Future<void> Function() retry) {
    return ApiException(error, retry: retry);
  }

  factory ApiException.fromResponse(ApiResponse<T> response) {
    return ApiException("API returned status code ${response.statusCode}");
  }
}

class BrussApi {
  const BrussApi();

  static Future<ApiResponse<T>> request<T extends BrussType>(BrussRequest<T> req) async {
    final apiUrl = await Settings().get("api.url");
    final url = Uri.parse("$apiUrl${req.endpoint}${req.query ?? ""}");
    print("API: fetching from $url");
    return http.get(url)
      .then((response) {
        switch(response.statusCode) {
          case 200: 
        }
        if (req.deserializer != null) {
          print("DEBUG: using custom deserializer");
        }
        final deserializer = req.deserializer ?? jsonDecode;
        final List<T> ret = deserializer(response.body)
          .map<T>((json) {
            print("DEBUG: constructing $json");
            return req.construct(json as Map<String, dynamic>);
          })
          .toList();
        print("API: fetched ${ret.length} items from ${req.endpoint}");
        return ApiResponse.success(ret);
        // return ApiResponse.error(500);
      // });
      })
      .catchError((error) {
        // finite set of errors, if not, throw the error wrapped in ApiException
        throw ApiException(error);
      });

    // return construct("""{"id": 505, "label": "Urbano Trento", "type": "u"}""");
    // return construct(utf8.decode(response.bodyBytes));
  }
}

