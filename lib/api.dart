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

  BrussRequest({required this.endpoint, required this.construct, this.query});
}

class BrussApi {
  const BrussApi();

  static Future<ApiResponse<T>> request<T extends BrussType>(BrussRequest<T> req) async {
    final apiUrl = await Settings().getApiUrl();
    return http.get(Uri.parse("$apiUrl${req.endpoint}${req.query ?? ""}"))
      .then((response) {
        switch(response.statusCode) {
          case 200: 
        }
        final List<T> ret = jsonDecode(response.body)
          .map<T>((json) {
            // print("DEBUG: constructing $json");
            return req.construct(json as Map<String, dynamic>);
          })
          .toList();
        print("API: fetched ${ret.length} items from ${req.endpoint}");
        return ApiResponse.success(ret);
        // return ApiResponse.error(500);
      // });
      })
      .catchError((error) {
        print("API: error fetching ${req.endpoint}: $error");
        return ApiResponse<T>.error(500);
      });

    // return construct("""{"id": 505, "label": "Urbano Trento", "type": "u"}""");
    // return construct(utf8.decode(response.bodyBytes));
  }
}

