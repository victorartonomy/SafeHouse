import 'package:equatable/equatable.dart';

class CloudFile extends Equatable {
  final String name;
  final String fullPath;
  final int sizeBytes;
  final DateTime? timeCreated;

  const CloudFile({
    required this.name,
    required this.fullPath,
    required this.sizeBytes,
    this.timeCreated,
  });

  @override
  List<Object?> get props => [name, fullPath, sizeBytes, timeCreated];
}
