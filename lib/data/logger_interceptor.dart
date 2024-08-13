import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http_interceptor/http/interceptor_contract.dart';
import 'package:http_interceptor/models/request_data.dart';
import 'package:http_interceptor/models/response_data.dart';

class LoggerInterceptor extends InterceptorContract {
  @override
  Future<RequestData> interceptRequest({required RequestData data}) {
    data.headers.addAll({'Content-Type': 'application/json'});
    debugPrint(_cURLRepresentation(data));
    return Future.value(data);
  }

  @override
  Future<ResponseData> interceptResponse({required ResponseData data}) {
    debugPrint(data.toString());
    return Future.value(data);
  }

  String _cURLRepresentation(RequestData request) {
    List<String> components = ['\$ curl -i'];

    components.add('-X ${request.method}');

    request.headers.forEach((k, v) {
      if (k.toLowerCase() != 'cookie') {
        components.add('-H \'$k: $v\'');
      }
    });

    if (request.body != null) {
      var data = jsonEncode(request.body);
      data = data.replaceAll('\'', '\\\'');
      components.add('-d \'$data\'');
    }

    components.add('\'${request.url}\'');

    return components.join('\\\n\t');
  }
}
