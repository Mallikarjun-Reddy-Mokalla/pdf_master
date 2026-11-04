import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database operation failed']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'File system operation failed']);
}

class PdfProcessingFailure extends Failure {
  const PdfProcessingFailure([super.message = 'PDF processing failed']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Required permission not granted']);
}

