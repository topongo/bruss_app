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

class BrussApi {
  const BrussApi();

  static Future<ApiResponse<T>> request<T extends BrussType>(T Function(Map<String, dynamic>) construct, String endpoint) async {
    return http.get(Uri.parse("http://127.0.0.1:8000/api/v1/$endpoint"))
      .then((response) {
        switch(response.statusCode) {
          case 200: 
        }
        final List<T> ret = jsonDecode(response.body)
          .map<T>((json) => construct(json as Map<String, dynamic>))
          .toList();
        print("API: fetched ${ret.length} items from $endpoint");
        return ApiResponse.success(ret);
        // return ApiResponse.error(500);
      });
      // })
      // .catchError((error) {
      //   return Future(ApiResponse.error(500));
      // });

    // return construct("""{"id": 505, "label": "Urbano Trento", "type": "u"}""");
    // return construct(utf8.decode(response.bodyBytes));
  }
}

