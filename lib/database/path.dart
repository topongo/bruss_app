import 'package:drift/drift.dart';

import '../data/area_type.dart';

class SequenceConverter extends TypeConverter<List<int>, String> {
  const SequenceConverter();

  @override
  List<int> fromSql(String fromDb) {
    return fromDb.split(',').map(int.parse).toList();
  }

  @override
  String toSql(List<int> value) {
    return value.join(',');
  }
}

class PathCache extends Table {
  TextColumn get id => text()();
  IntColumn get type => intEnum<AreaType>()();
  TextColumn get rty => text()();
  TextColumn get sequence => text().map(const SequenceConverter())();

  BoolColumn get isFavorite => boolean().nullable()();

  DateTimeColumn get lastUpdated => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}
