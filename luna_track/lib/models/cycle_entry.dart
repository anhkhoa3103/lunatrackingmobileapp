import 'package:hive/hive.dart';

part 'cycle_entry.g.dart';

@HiveType(typeId: 0)
class CycleEntry extends HiveObject {
  @HiveField(0)
  late DateTime date;

  @HiveField(1)
  late String flow; // none, light, medium, heavy

  @HiveField(2)
  late List<String> moods;

  @HiveField(3)
  late List<String> symptoms;

  @HiveField(4)
  late String energy; // low, medium, high

  @HiveField(5)
  late String sleep; // poor, ok, good

  @HiveField(6)
  late String notes;

  CycleEntry({
    required this.date,
    required this.flow,
    required this.moods,
    required this.symptoms,
    required this.energy,
    required this.sleep,
    required this.notes,
  });
}