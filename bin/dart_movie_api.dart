import 'dart:convert';
import 'dart:io';
import 'package:dart_movie_api/src/constants/app_const.dart';
import 'package:dart_movie_api/src/extensions/http_ext.dart';
import 'package:dart_movie_api/src/middlewares/auth_middleware.dart';
import 'package:dart_movie_api/src/middlewares/cors_middleware.dart';
import 'package:dart_movie_api/src/models/token_secret.dart';
import 'package:dart_movie_api/src/service/auth_services.dart';
import 'package:dart_movie_api/src/service/db_service.dart';
import 'package:dart_movie_api/src/service/movie_service.dart';
import 'package:dart_movie_api/src/service/password_service.dart';
import 'package:dart_movie_api/src/service/provider.dart';
import 'package:dart_movie_api/src/service/token_service.dart';
import 'package:dart_movie_api/src/utils/config.dart';
import 'package:dart_movie_api/src/utils/email_validator.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

Future<void> main(List<String> arguments) async {
  await initData();
  final app = Router();
  final port = Env.port;
  final dbInst = Provider.of.fetch<DbService>();
  await dbInst.openDb();

  // app.get('/', (Request request) {
  //   return Response.ok(
  //     json.encode({'message': 'Get End Point Testing OKEY !!!'}),
  //     headers: {'Content-type': 'application/json'},
  //   );
  // });

  app.mount(
    '/movies',
    MovieService(store: dbInst.getStore(AppConstants.movieCollections)).router,
  );

  app.mount(
    '/auth',
    AuthServices(
      store: dbInst.getStore(AppConstants.userCollections),
      secret: Env.secretKey,
    ).router,
  );

  app.all('/<routeName|.*>', (Request request, String routeName) {
    final indexFile = File('public/main.html').readAsStringSync();
    return Response.ok(indexFile, headers: CustomHeader.html.getType);
  });

  final handler = Pipeline() //
      .addMiddleware(corsMiddleware())
      .addMiddleware(authMidleware())
      .addHandler(app.call);

  await serve(handler, InternetAddress.anyIPv4, int.parse(port));
}

Future<void> initData() async {
  Provider.of
    ..register(DbService, () => DbService())
    ..register(RegexValidator, () => RegexValidator(regExpSource: AppConstants.emailRegex))
    ..register(PasswordService, () => PasswordService())
    ..register(TokenSecret, () => TokenSecret())
    ..register(
        TokenService,
        () => TokenService(
              store: Provider.of.fetch<DbService>().getStore(AppConstants.tokenCollections),
            ));
}
