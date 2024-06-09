import 'package:drift/drift.dart';
import 'package:bruss/data/area_type.dart';
import 'position_converter.dart';

class StopCache extends Table {
  IntColumn get id => integer()();
  TextColumn get code => text()();
  TextColumn get description => text()();
  TextColumn get position => text().map(const PositionConverter())();
  IntColumn get altitude => integer()();
  TextColumn get name => text()();
  TextColumn get town => text().nullable()();
  IntColumn get type => intEnum<AreaType>()();
  BoolColumn get wheelchairBoarding => boolean().nullable()();

  BoolColumn get isFavorite => boolean().nullable()();

  DateTimeColumn get lastUpdated => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id, type};
}
