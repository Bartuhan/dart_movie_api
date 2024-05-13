import 'dart:convert';
import 'dart:io';

import 'package:dart_movie_api/src/extensions/http_ext.dart';
import 'package:dart_movie_api/src/middlewares/check_authorization.dart';
import 'package:dart_movie_api/src/middlewares/check_token_middleware.dart';
import 'package:dart_movie_api/src/models/movie.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

class MovieService {
  final DbCollection store;

  MovieService({required this.store});
  Handler get router {
    final app = Router();

    app.get('/', (Request request) async {
      final allMovies = await store //
          .find()
          .map<Movie>((m) => Movie.fromJson(m))
          .cast<Movie>()
          .toList();

      final moviesLenght = allMovies.length;

      return Response.ok(
        json.encode({'length': moviesLenght, 'movies': allMovies}),
        headers: CustomHeader.json.getType,
      );
    });

    app.post('/add', (Request request) async {
      final payload = json.decode(await request.readAsString()) as Map<String, dynamic>;
      final movieId = Uuid().v4().substring(0, 8);
      final movie = Movie(
        movieId: movieId,
        title: payload['title'] as String,
        year: payload['year'] as int,
        rating: payload['rating'] as double,
      );
      final currentMovie = await store.findOne(where.eq('title', payload['title'] as String));
      if (currentMovie != null) {
        return Response.badRequest(
          body: json.encode({'error': 'Movie already exist...'}),
          headers: CustomHeader.json.getType,
        );
      }
      await store.insertOne(movie.toJson());
      return Response(
        HttpStatus.ok,
        body: json.encode({'message': 'A Movie added', 'name': movie.title}),
        headers: CustomHeader.json.getType,
      );
    });

    app.delete('/delete/<movieId|.*>', (Request request, String? movieId) async {
      final movie = await store.findOne(where.eq('movieId', movieId));
      if (movie == null || movieId == null) {
        return Response.notFound(
          json.encode({'error': 'Movie not found'}),
          headers: CustomHeader.json.getType,
        );
      }
      await store.deleteOne(where.eq('movieId', movieId));
      return Response.ok(
        json.encode({'message': 'Movie was deleted...'}),
        headers: CustomHeader.json.getType,
      );
    });

    final handler = Pipeline() //
        .addMiddleware(checkAuthorization())
        .addMiddleware(checkToken(store))
        .addHandler(app.call);

    return handler;
  }
}
