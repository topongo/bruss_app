import 'package:drift/drift.dart';
import 'package:bruss/data/area_type.dart';

class AreaCache extends Table {
  IntColumn get id => integer()();
  TextColumn get label => text()();
  IntColumn get type => intEnum<AreaType>()();

  DateTimeColumn get lastUpdated => dateTime()();
}
