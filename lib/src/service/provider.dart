typedef FacoryType = Map<dynamic, Function>;
typedef RepositoryType = Map<dynamic, dynamic>;

class Provider {
  final FacoryType _factory = {};
  final RepositoryType _repository = {};

  // Unique Instance için Singleton prensibi
  Provider._sharedInstance();
  static final Provider _instance = Provider._sharedInstance();
  static Provider get of => _instance;

  register(name, Function object) => _factory[name] = object;
  _add(name) => _repository[name] = _factory[name]!();

  T fetch<T>() => _repository.containsKey(T) ? _repository[T] : _add(T);
}
