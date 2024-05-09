import 'package:dart_movie_api/src/utils/config.dart';

class TokenSecret {
  String get getSecret => Env.secretKey;
}
