import 'package:drift/drift.dart';
import 'package:bruss/data/area_type.dart';

class RouteCache extends Table {
  IntColumn get id => integer()();
  IntColumn get type => integer()();
  IntColumn get area => integer()();
  IntColumn get areaType => intEnum<AreaType>()();
  TextColumn get color => text()();
  TextColumn get name => text()();
  TextColumn get code => text()();

  BoolColumn get isFavorite => boolean().nullable()();

  DateTimeColumn get lastUpdated => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id, areaType};
}
