import 'package:bruss/settings/init.dart';
import 'package:http/http.dart' as http;
import 'data/bruss_type.dart';
import 'dart:convert';

class ApiResponse<T> {
  final int statusCode;
  final List<T>? data;
  final int? total;

  ApiResponse(this.statusCode, this.data, this.total);
  factory ApiResponse.error(int statusCode) => ApiResponse(statusCode, null, null);
  factory ApiResponse.success(List<T> data, int? total) => ApiResponse(200, data, total);

  bool get isSuccess => statusCode == 200;
  bool get isError => !isSuccess;

  List<T> unwrap() {
    if (isError) {
      throw Exception("API response is an error: $statusCode");
    }
    return data!;
  }
}

class BrussRequest<T extends BrussType> {
  final String endpoint;
  final T Function(Map<String, dynamic>) construct;
  String? query;
  final dynamic Function(String raw)? deserializer;

  BrussRequest({required this.endpoint, required this.construct, this.query, this.deserializer});

  static BrussRequest status = BrussRequest(
    endpoint: "",
    construct: (_) => BrussTypeMock.instance,
    deserializer: (_) => [],
  );
}

class BrussTypeMock extends BrussType {
  static final BrussTypeMock instance = BrussTypeMock();
}

class BrussResponseExtra {
  final int total;
  
  BrussResponseExtra(this.total);
}

class ApiException<T> implements Exception {
  final Object error;
  final StackTrace? stack;
  final Future<void> Function()? retry;
  ApiException(this.error, {this.stack, this.retry});

  @override
  String toString() => "API Exception: $error";

  ApiException<T> attachRetry(Future<void> Function() retry) {
    return ApiException(error, stack: stack, retry: retry);
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
        }
        final deserializer = req.deserializer ?? jsonDecode;
        final List<T> ret = deserializer(response.body)
          .map<T>((json) {
            return req.construct(json as Map<String, dynamic>);
          })
          .toList();
        print("API: fetched ${ret.length} items from ${req.endpoint}");
        final xTotalCount = response.headers["x-total-count"];
        final int total;
        if (xTotalCount != null) {
          total = int.parse(xTotalCount);
        } else {
          print("API: WARNING: X-Total-Count header not found, assuming 1");
          total = 1;
        }
        return ApiResponse.success(ret, total);
        // return ApiResponse.error(500);
      // });
      })
      .catchError((error, stack) {
        // finite set of errors, if not, throw the error wrapped in ApiException
        throw ApiException(error, stack: stack);
      });
  }
}

