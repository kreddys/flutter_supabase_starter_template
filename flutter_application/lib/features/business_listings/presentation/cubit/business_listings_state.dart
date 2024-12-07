import 'package:equatable/equatable.dart';

enum BusinessListingsStatus { initial, loading, success, failure }

class BusinessListingsState extends Equatable {
  const BusinessListingsState({
    this.status = BusinessListingsStatus.initial,
    this.errorMessage,
  });

  final BusinessListingsStatus status;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, errorMessage];

  BusinessListingsState copyWith({
    BusinessListingsStatus? status,
    String? errorMessage,
  }) {
    return BusinessListingsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}