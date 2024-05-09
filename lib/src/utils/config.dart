import 'package:envied/envied.dart';

part 'config.g.dart';

@Envied()
abstract class Env {
  @EnviedField(varName: 'MONGO_URL')
  static const String mongoPath = _Env.mongoPath;

  @EnviedField(varName: 'PORT')
  static const String port = _Env.port;

  @EnviedField(varName: 'SECRET_KEY')
  static const String secretKey = _Env.secretKey;
}
