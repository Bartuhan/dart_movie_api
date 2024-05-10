import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dart_movie_api/src/extensions/http_ext.dart';
import 'package:dart_movie_api/src/service/provider.dart';
import 'package:dart_movie_api/src/service/token_service.dart';
import 'package:shelf/shelf.dart';

Middleware authMidleware() {
  return (Handler innerHandler) {
    return (Request request) {
      try {
        final tokenService = Provider.of.fetch<TokenService>();
        final authHeader = request.headers['Authorization'];
        String? token;
        JWT? jwt;

        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          token = authHeader.substring(7);
          jwt = tokenService.verifyJWT(token);
        }

        final updatedRequest = request.change(context: {'authDetails': jwt});

        return innerHandler(updatedRequest);
      } on JwtCustomException catch (e) {
        return Response.badRequest(
          body: json.encode({'error': e.error}),
          headers: CustomHeader.json.getType,
        );
      }
    };
  };
}
