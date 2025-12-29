import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/hr_repository.dart';
import '../auth/auth_bloc.dart';
import 'my_info_event.dart';
import 'my_info_state.dart';

/// My Info BLoC
/// Handles loading personal data for the current user
class MyInfoBloc extends Bloc<MyInfoEvent, MyInfoState> {
  final HRRepository _repository;
  final AuthBloc _authBloc;

  MyInfoBloc({
    required HRRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const MyInfoState()) {
    on<MyInfoLoadData>(_onLoadData);
    on<MyInfoLoadContracts>(_onLoadContracts);
    on<MyInfoLoadSalaries>(_onLoadSalaries);
    on<MyInfoLoadEvaluations>(_onLoadEvaluations);
  }

  String get _currentUserId => _authBloc.state.user?.id ?? '';

  Future<void> _onLoadData(
    MyInfoLoadData event,
    Emitter<MyInfoState> emit,
  ) async {
    emit(state.copyWith(status: MyInfoStatus.loading));

    try {
      // Load all personal data in parallel
      final contractsResult = await _repository.getContracts();
      final salariesResult = await _repository.getSalaries();
      final evaluationsResult = await _repository.getEvaluations();

      // Filter for current user only
      final userId = _currentUserId;
      
      contractsResult.fold(
        (failure) => null,
        (contracts) {
          final myContracts = contracts.where((c) => c.employeeId == userId).toList();
          emit(state.copyWith(myContracts: myContracts));
        },
      );

      salariesResult.fold(
        (failure) => null,
        (salaries) {
          final mySalaries = salaries.where((s) => s.employeeId == userId).toList();
          emit(state.copyWith(mySalaries: mySalaries));
        },
      );

      evaluationsResult.fold(
        (failure) => null,
        (evaluations) {
          final myEvaluations = evaluations.where((e) => e.employeeId == userId).toList();
          emit(state.copyWith(myEvaluations: myEvaluations));
        },
      );

      emit(state.copyWith(status: MyInfoStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: MyInfoStatus.error,
        errorMessage: 'Không thể tải dữ liệu: $e',
      ));
    }
  }

  Future<void> _onLoadContracts(
    MyInfoLoadContracts event,
    Emitter<MyInfoState> emit,
  ) async {
    final result = await _repository.getContracts();
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (contracts) {
        final myContracts = contracts.where((c) => c.employeeId == _currentUserId).toList();
        emit(state.copyWith(myContracts: myContracts));
      },
    );
  }

  Future<void> _onLoadSalaries(
    MyInfoLoadSalaries event,
    Emitter<MyInfoState> emit,
  ) async {
    final result = await _repository.getSalaries(month: event.month, year: event.year);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (salaries) {
        final mySalaries = salaries.where((s) => s.employeeId == _currentUserId).toList();
        emit(state.copyWith(mySalaries: mySalaries));
      },
    );
  }

  Future<void> _onLoadEvaluations(
    MyInfoLoadEvaluations event,
    Emitter<MyInfoState> emit,
  ) async {
    final result = await _repository.getEvaluations();
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (evaluations) {
        final myEvaluations = evaluations.where((e) => e.employeeId == _currentUserId).toList();
        emit(state.copyWith(myEvaluations: myEvaluations));
      },
    );
  }
}
