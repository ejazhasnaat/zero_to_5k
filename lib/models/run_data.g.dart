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
      endTime: fields[1] as DateTime,
      durationSeconds: fields[2] as int,
      distanceMeters: fields[3] as double,
      paceSecondsPerKm: fields[4] as double,
      caloriesBurned: fields[5] as double,
      route: (fields[6] as List).cast<RoutePoint>(),
      averageSpeedKmh: fields[7] as double?,
      maxSpeedKmh: fields[8] as double?,
      elevationGainMeters: fields[9] as double?,
      elevationLossMeters: fields[10] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, RunData obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.startTime)
      ..writeByte(1)
      ..write(obj.endTime)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.distanceMeters)
      ..writeByte(4)
      ..write(obj.paceSecondsPerKm)
      ..writeByte(5)
      ..write(obj.caloriesBurned)
      ..writeByte(6)
      ..write(obj.route)
      ..writeByte(7)
      ..write(obj.averageSpeedKmh)
      ..writeByte(8)
      ..write(obj.maxSpeedKmh)
      ..writeByte(9)
      ..write(obj.elevationGainMeters)
      ..writeByte(10)
      ..write(obj.elevationLossMeters);
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
      lat: fields[0] as double,
      lng: fields[1] as double,
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
