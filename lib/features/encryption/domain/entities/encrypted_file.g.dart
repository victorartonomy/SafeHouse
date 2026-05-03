// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encrypted_file.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EncryptedFileAdapter extends TypeAdapter<EncryptedFile> {
  @override
  final int typeId = 0;

  @override
  EncryptedFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EncryptedFile(
      id: fields[0] as String,
      originalName: fields[1] as String,
      encryptedPath: fields[2] as String,
      secretKey: fields[3] as String,
      createdAt: fields[4] as DateTime,
      categoryId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EncryptedFile obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalName)
      ..writeByte(2)
      ..write(obj.encryptedPath)
      ..writeByte(3)
      ..write(obj.secretKey)
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
      other is EncryptedFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
