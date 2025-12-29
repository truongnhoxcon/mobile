import 'package:equatable/equatable.dart';

/// Evaluation Status
enum EvaluationStatus {
  draft,      // Bản nháp (tự đánh giá)
  submitted,  // Đã gửi cho manager
  reviewed,   // Manager đã review
  approved,   // Đã duyệt
  rejected,   // Yêu cầu đánh giá lại
}

extension EvaluationStatusExtension on EvaluationStatus {
  String get value {
    switch (this) {
      case EvaluationStatus.draft:
        return 'DRAFT';
      case EvaluationStatus.submitted:
        return 'SUBMITTED';
      case EvaluationStatus.reviewed:
        return 'REVIEWED';
      case EvaluationStatus.approved:
        return 'APPROVED';
      case EvaluationStatus.rejected:
        return 'REJECTED';
    }
  }

  String get displayName {
    switch (this) {
      case EvaluationStatus.draft:
        return 'Bản nháp';
      case EvaluationStatus.submitted:
        return 'Đã gửi';
      case EvaluationStatus.reviewed:
        return 'Đã review';
      case EvaluationStatus.approved:
        return 'Đã duyệt';
      case EvaluationStatus.rejected:
        return 'Yêu cầu đánh giá lại';
    }
  }

  static EvaluationStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DRAFT':
        return EvaluationStatus.draft;
      case 'SUBMITTED':
        return EvaluationStatus.submitted;
      case 'REVIEWED':
        return EvaluationStatus.reviewed;
      case 'APPROVED':
        return EvaluationStatus.approved;
      case 'REJECTED':
        return EvaluationStatus.rejected;
      default:
        return EvaluationStatus.draft;
    }
  }
}

/// Evaluation Period Type
enum EvaluationPeriod {
  monthly,    // Hàng tháng
  quarterly,  // Hàng quý
  halfYear,   // 6 tháng
  annual,     // Hàng năm
}

extension EvaluationPeriodExtension on EvaluationPeriod {
  String get displayName {
    switch (this) {
      case EvaluationPeriod.monthly:
        return 'Tháng';
      case EvaluationPeriod.quarterly:
        return 'Quý';
      case EvaluationPeriod.halfYear:
        return '6 tháng';
      case EvaluationPeriod.annual:
        return 'Năm';
    }
  }
}

/// Criteria Category - Nhóm tiêu chí
enum CriteriaCategory {
  performance,    // Hiệu suất công việc
  skill,          // Kỹ năng chuyên môn
  attitude,       // Thái độ làm việc
  teamwork,       // Làm việc nhóm
  leadership,     // Lãnh đạo
  innovation,     // Sáng tạo
}

extension CriteriaCategoryExtension on CriteriaCategory {
  String get displayName {
    switch (this) {
      case CriteriaCategory.performance:
        return 'Hiệu suất';
      case CriteriaCategory.skill:
        return 'Kỹ năng';
      case CriteriaCategory.attitude:
        return 'Thái độ';
      case CriteriaCategory.teamwork:
        return 'Teamwork';
      case CriteriaCategory.leadership:
        return 'Lãnh đạo';
      case CriteriaCategory.innovation:
        return 'Sáng tạo';
    }
  }
}

/// Evaluation Criteria - Tiêu chí đánh giá chi tiết
class EvaluationCriteria extends Equatable {
  final String id;
  final String name;              // Tên tiêu chí
  final String? description;      // Mô tả
  final CriteriaCategory category;
  final double weight;            // Trọng số (%)
  final double maxScore;          // Điểm tối đa (thường 5 hoặc 10)
  final double? selfScore;        // Tự đánh giá
  final double? managerScore;     // Manager đánh giá
  final String? selfComment;      // NV tự nhận xét
  final String? managerComment;   // Manager nhận xét

  const EvaluationCriteria({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.weight,
    this.maxScore = 5,
    this.selfScore,
    this.managerScore,
    this.selfComment,
    this.managerComment,
  });

  /// Điểm cuối cùng (ưu tiên manager)
  double? get finalScore => managerScore ?? selfScore;

  /// Điểm có trọng số (weighted score)
  double? get weightedScore {
    final score = finalScore;
    if (score == null) return null;
    return (score / maxScore) * weight;
  }

  EvaluationCriteria copyWith({
    String? id,
    String? name,
    String? description,
    CriteriaCategory? category,
    double? weight,
    double? maxScore,
    double? selfScore,
    double? managerScore,
    String? selfComment,
    String? managerComment,
  }) {
    return EvaluationCriteria(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      weight: weight ?? this.weight,
      maxScore: maxScore ?? this.maxScore,
      selfScore: selfScore ?? this.selfScore,
      managerScore: managerScore ?? this.managerScore,
      selfComment: selfComment ?? this.selfComment,
      managerComment: managerComment ?? this.managerComment,
    );
  }

  @override
  List<Object?> get props => [
        id, name, description, category, weight, maxScore,
        selfScore, managerScore, selfComment, managerComment,
      ];
}

/// Goal - Mục tiêu kỳ đánh giá
class EvaluationGoal extends Equatable {
  final String id;
  final String title;
  final String? description;
  final double? targetValue;      // Giá trị mục tiêu
  final double? actualValue;      // Giá trị thực tế đạt được
  final String? unit;             // Đơn vị (%, VND, dự án...)
  final bool isCompleted;
  final DateTime? deadline;

  const EvaluationGoal({
    required this.id,
    required this.title,
    this.description,
    this.targetValue,
    this.actualValue,
    this.unit,
    this.isCompleted = false,
    this.deadline,
  });

  /// Tỷ lệ hoàn thành (%)
  double? get completionRate {
    if (targetValue == null || actualValue == null || targetValue == 0) return null;
    return (actualValue! / targetValue!) * 100;
  }

  @override
  List<Object?> get props => [
        id, title, description, targetValue, actualValue, 
        unit, isCompleted, deadline,
      ];
}

/// Evaluation entity
class Evaluation extends Equatable {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String? employeeDepartment;
  final String? employeePosition;
  
  // Period
  final EvaluationPeriod periodType;
  final String period;        // e.g., "Q1/2024", "2024"
  final DateTime startDate;
  final DateTime endDate;
  
  // Scores
  final double? selfScore;        // Điểm tự đánh giá (trung bình)
  final double? managerScore;     // Điểm manager (trung bình)
  final double? finalScore;       // Điểm cuối cùng
  
  // Status
  final EvaluationStatus status;
  
  // Evaluator
  final String? evaluatorId;
  final String? evaluatorName;
  
  // Comments
  final String? selfSummary;      // NV tự tổng kết
  final String? managerSummary;   // Manager tổng kết
  final String? improvement;      // Điểm cần cải thiện
  final String? strength;         // Điểm mạnh
  
  // Criteria và Goals
  final List<EvaluationCriteria> criteria;
  final List<EvaluationGoal> currentGoals;    // Mục tiêu kỳ này
  final List<EvaluationGoal> nextGoals;       // Mục tiêu kỳ tiếp
  
  // Metadata
  final String? rejectReason;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime createdAt;

  const Evaluation({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeDepartment,
    this.employeePosition,
    this.periodType = EvaluationPeriod.quarterly,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.selfScore,
    this.managerScore,
    this.finalScore,
    this.status = EvaluationStatus.draft,
    this.evaluatorId,
    this.evaluatorName,
    this.selfSummary,
    this.managerSummary,
    this.improvement,
    this.strength,
    this.criteria = const [],
    this.currentGoals = const [],
    this.nextGoals = const [],
    this.rejectReason,
    this.submittedAt,
    this.approvedAt,
    required this.createdAt,
  });

  /// Score grade (Xuất sắc, Tốt, Khá, Trung bình, Yếu)
  String get grade {
    final score = finalScore ?? managerScore ?? selfScore ?? 0;
    if (score >= 90) return 'Xuất sắc';
    if (score >= 80) return 'Tốt';
    if (score >= 70) return 'Khá';
    if (score >= 50) return 'Trung bình';
    return 'Yếu';
  }

  /// Điểm cuối cùng tính từ criteria có trọng số
  double get calculatedScore {
    if (criteria.isEmpty) return 0;
    double totalWeightedScore = 0;
    double totalWeight = 0;
    
    for (final c in criteria) {
      if (c.finalScore != null) {
        totalWeightedScore += c.weightedScore ?? 0;
        totalWeight += c.weight;
      }
    }
    
    if (totalWeight == 0) return 0;
    return (totalWeightedScore / totalWeight) * 100;
  }

  /// Số mục tiêu đã hoàn thành
  int get completedGoalsCount => 
      currentGoals.where((g) => g.isCompleted).length;

  /// Tỷ lệ hoàn thành mục tiêu
  double get goalsCompletionRate {
    if (currentGoals.isEmpty) return 0;
    return (completedGoalsCount / currentGoals.length) * 100;
  }

  Evaluation copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeeDepartment,
    String? employeePosition,
    EvaluationPeriod? periodType,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    double? selfScore,
    double? managerScore,
    double? finalScore,
    EvaluationStatus? status,
    String? evaluatorId,
    String? evaluatorName,
    String? selfSummary,
    String? managerSummary,
    String? improvement,
    String? strength,
    List<EvaluationCriteria>? criteria,
    List<EvaluationGoal>? currentGoals,
    List<EvaluationGoal>? nextGoals,
    String? rejectReason,
    DateTime? submittedAt,
    DateTime? approvedAt,
    DateTime? createdAt,
  }) {
    return Evaluation(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeDepartment: employeeDepartment ?? this.employeeDepartment,
      employeePosition: employeePosition ?? this.employeePosition,
      periodType: periodType ?? this.periodType,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selfScore: selfScore ?? this.selfScore,
      managerScore: managerScore ?? this.managerScore,
      finalScore: finalScore ?? this.finalScore,
      status: status ?? this.status,
      evaluatorId: evaluatorId ?? this.evaluatorId,
      evaluatorName: evaluatorName ?? this.evaluatorName,
      selfSummary: selfSummary ?? this.selfSummary,
      managerSummary: managerSummary ?? this.managerSummary,
      improvement: improvement ?? this.improvement,
      strength: strength ?? this.strength,
      criteria: criteria ?? this.criteria,
      currentGoals: currentGoals ?? this.currentGoals,
      nextGoals: nextGoals ?? this.nextGoals,
      rejectReason: rejectReason ?? this.rejectReason,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, employeeId, employeeName, employeeDepartment, employeePosition,
        periodType, period, startDate, endDate, selfScore, managerScore,
        finalScore, status, evaluatorId, evaluatorName, selfSummary,
        managerSummary, improvement, strength, criteria, currentGoals,
        nextGoals, rejectReason, submittedAt, approvedAt, createdAt,
      ];
}
