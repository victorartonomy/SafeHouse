// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encrypted_file_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EncryptedFileModelAdapter extends TypeAdapter<EncryptedFileModel> {
  @override
  final int typeId = 0;

  @override
  EncryptedFileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EncryptedFileModel(
      id: fields[0] as String,
      originalName: fields[1] as String,
      encryptedPath: fields[2] as String,
      createdAt: fields[4] as DateTime,
      categoryId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EncryptedFileModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalName)
      ..writeByte(2)
      ..write(obj.encryptedPath)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.categoryId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncryptedFileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
