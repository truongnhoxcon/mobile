import 'package:equatable/equatable.dart';

/// My Info Events - For loading personal HR data
abstract class MyInfoEvent extends Equatable {
  const MyInfoEvent();

  @override
  List<Object?> get props => [];
}

/// Load all personal data (contracts, salary, evaluations)
class MyInfoLoadData extends MyInfoEvent {
  const MyInfoLoadData();
}

/// Load personal contracts
class MyInfoLoadContracts extends MyInfoEvent {
  const MyInfoLoadContracts();
}

/// Load personal salary history
class MyInfoLoadSalaries extends MyInfoEvent {
  final int? month;
  final int? year;
  
  const MyInfoLoadSalaries({this.month, this.year});
  
  @override
  List<Object?> get props => [month, year];
}

/// Load personal evaluations
class MyInfoLoadEvaluations extends MyInfoEvent {
  const MyInfoLoadEvaluations();
}
