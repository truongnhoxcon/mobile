import 'package:equatable/equatable.dart';

/// Contract Status
enum ContractStatus {
  draft,      // Bản nháp
  pending,    // Chờ ký
  active,     // Đang hiệu lực
  expired,    // Hết hạn
  terminated, // Chấm dứt trước hạn
  renewed,    // Đã gia hạn (HĐ cũ)
}

extension ContractStatusExtension on ContractStatus {
  String get value {
    switch (this) {
      case ContractStatus.draft:
        return 'DRAFT';
      case ContractStatus.pending:
        return 'PENDING';
      case ContractStatus.active:
        return 'ACTIVE';
      case ContractStatus.expired:
        return 'EXPIRED';
      case ContractStatus.terminated:
        return 'TERMINATED';
      case ContractStatus.renewed:
        return 'RENEWED';
    }
  }

  String get displayName {
    switch (this) {
      case ContractStatus.draft:
        return 'Bản nháp';
      case ContractStatus.pending:
        return 'Chờ ký';
      case ContractStatus.active:
        return 'Đang hiệu lực';
      case ContractStatus.expired:
        return 'Hết hạn';
      case ContractStatus.terminated:
        return 'Chấm dứt';
      case ContractStatus.renewed:
        return 'Đã gia hạn';
    }
  }

  static ContractStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DRAFT':
        return ContractStatus.draft;
      case 'ACTIVE':
        return ContractStatus.active;
      case 'EXPIRED':
        return ContractStatus.expired;
      case 'TERMINATED':
        return ContractStatus.terminated;
      case 'RENEWED':
        return ContractStatus.renewed;
      case 'PENDING':
      default:
        return ContractStatus.pending;
    }
  }
}

/// Contract Type - Theo luật lao động Việt Nam
enum ContractType {
  indefinite,   // HĐ không xác định thời hạn
  definite12,   // HĐ xác định thời hạn 12 tháng
  definite24,   // HĐ xác định thời hạn 24 tháng
  definite36,   // HĐ xác định thời hạn 36 tháng
  seasonal,     // HĐ mùa vụ/công việc (<12 tháng)
  partTime,     // HĐ bán thời gian
  freelance,    // Hợp đồng dịch vụ/CTV
}

extension ContractTypeExtension on ContractType {
  String get value {
    switch (this) {
      case ContractType.indefinite:
        return 'INDEFINITE';
      case ContractType.definite12:
        return 'DEFINITE_12';
      case ContractType.definite24:
        return 'DEFINITE_24';
      case ContractType.definite36:
        return 'DEFINITE_36';
      case ContractType.seasonal:
        return 'SEASONAL';
      case ContractType.partTime:
        return 'PART_TIME';
      case ContractType.freelance:
        return 'FREELANCE';
    }
  }

  String get displayName {
    switch (this) {
      case ContractType.indefinite:
        return 'Không xác định thời hạn';
      case ContractType.definite12:
        return 'Xác định 12 tháng';
      case ContractType.definite24:
        return 'Xác định 24 tháng';
      case ContractType.definite36:
        return 'Xác định 36 tháng';
      case ContractType.seasonal:
        return 'Mùa vụ/Công việc';
      case ContractType.partTime:
        return 'Bán thời gian';
      case ContractType.freelance:
        return 'Cộng tác viên';
    }
  }

  /// Thời hạn mặc định (tháng), -1 cho không xác định
  int get defaultMonths {
    switch (this) {
      case ContractType.indefinite:
        return -1;
      case ContractType.definite12:
        return 12;
      case ContractType.definite24:
        return 24;
      case ContractType.definite36:
        return 36;
      case ContractType.seasonal:
        return 6;
      case ContractType.partTime:
        return 12;
      case ContractType.freelance:
        return 12;
    }
  }

  /// Có đóng BHXH không
  bool get hasSocialInsurance {
    switch (this) {
      case ContractType.indefinite:
      case ContractType.definite12:
      case ContractType.definite24:
      case ContractType.definite36:
      case ContractType.partTime:
        return true;
      case ContractType.seasonal:
      case ContractType.freelance:
        return false;
    }
  }

  static ContractType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DEFINITE_12':
        return ContractType.definite12;
      case 'DEFINITE_24':
        return ContractType.definite24;
      case 'DEFINITE_36':
        return ContractType.definite36;
      case 'SEASONAL':
        return ContractType.seasonal;
      case 'PART_TIME':
        return ContractType.partTime;
      case 'FREELANCE':
        return ContractType.freelance;
      case 'INDEFINITE':
      default:
        return ContractType.indefinite;
    }
  }
}

/// Probation Status - Trạng thái thử việc
enum ProbationStatus {
  notRequired,  // Không yêu cầu thử việc
  inProbation,  // Đang thử việc
  passed,       // Đã pass thử việc
  failed,       // Không đạt thử việc
}

extension ProbationStatusExtension on ProbationStatus {
  String get displayName {
    switch (this) {
      case ProbationStatus.notRequired:
        return 'Không thử việc';
      case ProbationStatus.inProbation:
        return 'Đang thử việc';
      case ProbationStatus.passed:
        return 'Đã hoàn thành';
      case ProbationStatus.failed:
        return 'Không đạt';
    }
  }
}

/// Contract entity
class Contract extends Equatable {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String contractNumber;  // Số hợp đồng
  final ContractType type;
  final DateTime startDate;
  final DateTime? endDate;      // null cho HĐ không xác định
  final ContractStatus status;
  final String? note;
  final DateTime createdAt;
  final DateTime? signedDate;   // Ngày ký

  // Salary Info
  final double grossSalary;     // Lương gross
  final double netSalary;       // Lương net (ước tính)
  final double allowances;      // Tổng phụ cấp
  final double insuranceSalary; // Lương đóng BHXH

  // Allowances breakdown
  final double mealAllowance;       // Phụ cấp ăn trưa
  final double transportAllowance;  // Phụ cấp xăng xe
  final double phoneAllowance;      // Phụ cấp điện thoại
  final double housingAllowance;    // Phụ cấp nhà ở
  final double otherAllowance;      // Phụ cấp khác

  // Probation
  final ProbationStatus probationStatus;
  final DateTime? probationEndDate;
  final double? probationSalaryPercent; // % lương thử việc (85%)

  // Renewal
  final int renewalCount;       // Số lần gia hạn (max 2 cho HĐ xác định)
  final String? previousContractId;

  const Contract({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.contractNumber,
    required this.type,
    required this.startDate,
    this.endDate,
    this.status = ContractStatus.pending,
    this.note,
    required this.createdAt,
    this.signedDate,
    required this.grossSalary,
    this.netSalary = 0,
    this.allowances = 0,
    this.insuranceSalary = 0,
    this.mealAllowance = 0,
    this.transportAllowance = 0,
    this.phoneAllowance = 0,
    this.housingAllowance = 0,
    this.otherAllowance = 0,
    this.probationStatus = ProbationStatus.notRequired,
    this.probationEndDate,
    this.probationSalaryPercent = 85,
    this.renewalCount = 0,
    this.previousContractId,
  });

  /// Tổng thu nhập (gross + phụ cấp)
  double get totalIncome => grossSalary + allowances;

  /// Có đang thử việc không
  bool get isInProbation => probationStatus == ProbationStatus.inProbation;

  /// Days until contract expires (null cho HĐ không xác định)
  int? get daysUntilExpiry {
    if (endDate == null) return null;
    return endDate!.difference(DateTime.now()).inDays;
  }

  /// Is contract expiring soon (within 30 days)
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days > 0 && days <= 30;
  }

  /// Contract duration in months
  int? get durationMonths {
    if (endDate == null) return null;
    return (endDate!.year - startDate.year) * 12 + endDate!.month - startDate.month;
  }

  /// Có thể gia hạn không (max 2 lần cho HĐ xác định)
  bool get canRenew {
    if (type == ContractType.indefinite) return false;
    return renewalCount < 2;
  }

  /// Có đóng BHXH không
  bool get hasSocialInsurance => type.hasSocialInsurance;

  Contract copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? contractNumber,
    ContractType? type,
    DateTime? startDate,
    DateTime? endDate,
    ContractStatus? status,
    String? note,
    DateTime? createdAt,
    DateTime? signedDate,
    double? grossSalary,
    double? netSalary,
    double? allowances,
    double? insuranceSalary,
    double? mealAllowance,
    double? transportAllowance,
    double? phoneAllowance,
    double? housingAllowance,
    double? otherAllowance,
    ProbationStatus? probationStatus,
    DateTime? probationEndDate,
    double? probationSalaryPercent,
    int? renewalCount,
    String? previousContractId,
  }) {
    return Contract(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      contractNumber: contractNumber ?? this.contractNumber,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      signedDate: signedDate ?? this.signedDate,
      grossSalary: grossSalary ?? this.grossSalary,
      netSalary: netSalary ?? this.netSalary,
      allowances: allowances ?? this.allowances,
      insuranceSalary: insuranceSalary ?? this.insuranceSalary,
      mealAllowance: mealAllowance ?? this.mealAllowance,
      transportAllowance: transportAllowance ?? this.transportAllowance,
      phoneAllowance: phoneAllowance ?? this.phoneAllowance,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      otherAllowance: otherAllowance ?? this.otherAllowance,
      probationStatus: probationStatus ?? this.probationStatus,
      probationEndDate: probationEndDate ?? this.probationEndDate,
      probationSalaryPercent: probationSalaryPercent ?? this.probationSalaryPercent,
      renewalCount: renewalCount ?? this.renewalCount,
      previousContractId: previousContractId ?? this.previousContractId,
    );
  }

  @override
  List<Object?> get props => [
        id, employeeId, employeeName, contractNumber, type, startDate, endDate,
        status, note, createdAt, signedDate, grossSalary, netSalary, allowances,
        insuranceSalary, mealAllowance, transportAllowance, phoneAllowance,
        housingAllowance, otherAllowance, probationStatus, probationEndDate,
        probationSalaryPercent, renewalCount, previousContractId,
      ];
}
