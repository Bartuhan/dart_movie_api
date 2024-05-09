import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dart_movie_api/src/models/token_pair.dart';
import 'package:dart_movie_api/src/models/token_secret.dart';
import 'package:dart_movie_api/src/service/provider.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';

class TokenService {
  final DbCollection store;

  TokenService({required this.store});

  String generateJWT(
    String subject,
    String issuer,
    String secret, {
    String? jwtId,
    Duration expiry = const Duration(minutes: 10),
  }) {
    final jwt = JWT({
      'iat': DateTime.now().millisecondsSinceEpoch,
    }, issuer: issuer, jwtId: jwtId, subject: subject);

    return jwt.sign(SecretKey('12345'), expiresIn: expiry);
  }

  JWT verifyJWT(String token, String secret) {
    try {
      final jwt = JWT.verify(token, SecretKey(secret));
      return jwt;
    } on JWTExpiredException {
      throw Exception('JWT Expired...');
    } on JWTInvalidException {
      throw Exception('JWT Invalid...');
    }
  }

  Future<TokenPair> createTokenPair(String userId) async {
    final tokenSecretService = Provider.of.fetch<TokenSecret>();
    final secret = tokenSecretService.getSecret;
    final tokenId = Uuid().v4();
    final aToken = generateJWT(userId, 'http://localhost', secret, jwtId: tokenId);

    const refreshTokenExpiry = Duration(minutes: 5);
    final rToken = generateJWT(userId, 'http://localhost', secret, expiry: refreshTokenExpiry, jwtId: tokenId);

    await addTokenPair(tokenId, aToken, rToken);
    return TokenPair(aToken: aToken, rToken: rToken);
  }

  Future<void> addTokenPair(String tokenId, String aToken, String rToken) async {
    store.insertOne({'tokenId': tokenId, 'aToken': aToken, 'rToken': rToken});
  }

  Future<dynamic> removeToken(String tokenId) async {
    return await store.deleteOne({'tokenId': tokenId});
  }
}
