// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RunDataAdapter extends TypeAdapter<RunData> {
  @override
  final int typeId = 3;

  @override
  RunData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RunData(
      startTime: fields[0] as DateTime,
      durationSeconds: fields[1] as int,
      distanceMeters: fields[2] as double,
      paceSecondsPerKm: fields[3] as double,
      caloriesBurned: fields[4] as double,
      route: (fields[5] as List).cast<RoutePoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, RunData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.startTime)
      ..writeByte(1)
      ..write(obj.durationSeconds)
      ..writeByte(2)
      ..write(obj.distanceMeters)
      ..writeByte(3)
      ..write(obj.paceSecondsPerKm)
      ..writeByte(4)
      ..write(obj.caloriesBurned)
      ..writeByte(5)
      ..write(obj.route);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RoutePointAdapter extends TypeAdapter<RoutePoint> {
  @override
  final int typeId = 4;

  @override
  RoutePoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutePoint(
      fields[0] as double,
      fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, RoutePoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.lat)
      ..writeByte(1)
      ..write(obj.lng);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutePointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
