// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LevelModelAdapter extends TypeAdapter<LevelModel> {
  @override
  final int typeId = 0;

  @override
  LevelModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LevelModel(
      id: fields[0] as int,
      title: fields[1] as String,
      difficultyIndex: fields[2] as int,
      stars: fields[3] as int,
      isCompleted: fields[4] as bool,
      isUnlocked: fields[5] as bool,
      bestTimeSeconds: fields[6] as int?,
      bestMoves: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, LevelModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.difficultyIndex)
      ..writeByte(3)
      ..write(obj.stars)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.isUnlocked)
      ..writeByte(6)
      ..write(obj.bestTimeSeconds)
      ..writeByte(7)
      ..write(obj.bestMoves);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
