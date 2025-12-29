import 'package:equatable/equatable.dart';
import '../../../domain/entities/contract.dart';
import '../../../domain/entities/salary.dart';
import '../../../domain/entities/evaluation.dart';

/// My Info Status
enum MyInfoStatus {
  initial,
  loading,
  loaded,
  error,
}

/// My Info State - Personal data
class MyInfoState extends Equatable {
  final MyInfoStatus status;
  final List<Contract> myContracts;
  final List<Salary> mySalaries;
  final List<Evaluation> myEvaluations;
  final String? errorMessage;

  const MyInfoState({
    this.status = MyInfoStatus.initial,
    this.myContracts = const [],
    this.mySalaries = const [],
    this.myEvaluations = const [],
    this.errorMessage,
  });

  MyInfoState copyWith({
    MyInfoStatus? status,
    List<Contract>? myContracts,
    List<Salary>? mySalaries,
    List<Evaluation>? myEvaluations,
    String? errorMessage,
  }) {
    return MyInfoState(
      status: status ?? this.status,
      myContracts: myContracts ?? this.myContracts,
      mySalaries: mySalaries ?? this.mySalaries,
      myEvaluations: myEvaluations ?? this.myEvaluations,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, myContracts, mySalaries, myEvaluations, errorMessage];
}
