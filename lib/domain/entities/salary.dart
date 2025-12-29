import 'package:equatable/equatable.dart';

/// Salary Status
enum SalaryStatus {
  draft,      // Bản nháp
  pending,    // Chờ thanh toán
  paid,       // Đã thanh toán
  cancelled,  // Đã hủy
}

extension SalaryStatusExtension on SalaryStatus {
  String get value {
    switch (this) {
      case SalaryStatus.draft:
        return 'DRAFT';
      case SalaryStatus.pending:
        return 'PENDING';
      case SalaryStatus.paid:
        return 'PAID';
      case SalaryStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get displayName {
    switch (this) {
      case SalaryStatus.draft:
        return 'Bản nháp';
      case SalaryStatus.pending:
        return 'Chờ thanh toán';
      case SalaryStatus.paid:
        return 'Đã thanh toán';
      case SalaryStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static SalaryStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DRAFT':
        return SalaryStatus.draft;
      case 'PAID':
        return SalaryStatus.paid;
      case 'CANCELLED':
        return SalaryStatus.cancelled;
      case 'PENDING':
      default:
        return SalaryStatus.pending;
    }
  }
}

/// Salary entity
class Salary extends Equatable {
  final String id;
  final String employeeId;
  final String? employeeName;
  final int month;
  final int year;
  final SalaryStatus status;
  final DateTime? paidAt;
  final String? note;
  final DateTime createdAt;

  // Base Salary
  final double grossSalary;     // Lương gross theo HĐ
  final double baseSalary;      // Lương cơ bản (sau tính công)

  // Allowances (phụ cấp)
  final double mealAllowance;       // Phụ cấp ăn trưa
  final double transportAllowance;  // Phụ cấp xăng xe
  final double phoneAllowance;      // Phụ cấp điện thoại
  final double housingAllowance;    // Phụ cấp nhà ở
  final double otherAllowance;      // Phụ cấp khác

  // Bonus (thưởng)
  final double performanceBonus;    // Thưởng hiệu suất
  final double projectBonus;        // Thưởng dự án
  final double holidayBonus;        // Thưởng lễ/Tết
  final double otherBonus;          // Thưởng khác

  // Overtime (OT)
  final double overtimeHours;       // Tổng số giờ OT
  final double overtimeNormalRate;  // Giờ OT ngày thường (150%)
  final double overtimeWeekendRate; // Giờ OT cuối tuần (200%)
  final double overtimeHolidayRate; // Giờ OT ngày lễ (300%)
  final double overtimePay;         // Tổng tiền OT

  // Deductions (khấu trừ)
  final double bhxh;          // BHXH (8%)
  final double bhyt;          // BHYT (1.5%)
  final double bhtn;          // BHTN (1%)
  final double personalTax;   // Thuế TNCN
  final double otherDeductions; // Khấu trừ khác

  // Working days tracking
  final int standardWorkingDays;    // Ngày công chuẩn (22)
  final int actualWorkingDays;      // Ngày làm thực tế
  final int paidLeaveDays;          // Nghỉ phép có lương
  final int unpaidLeaveDays;        // Nghỉ không lương
  final int sickLeaveDays;          // Nghỉ ốm (75% lương BHXH)
  final int lateDays;               // Ngày đi trễ
  final int absentDays;             // Vắng không phép

  // Net salary
  final double netSalary;           // Thực nhận

  const Salary({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.month,
    required this.year,
    this.status = SalaryStatus.pending,
    this.paidAt,
    this.note,
    required this.createdAt,
    required this.grossSalary,
    required this.baseSalary,
    this.mealAllowance = 0,
    this.transportAllowance = 0,
    this.phoneAllowance = 0,
    this.housingAllowance = 0,
    this.otherAllowance = 0,
    this.performanceBonus = 0,
    this.projectBonus = 0,
    this.holidayBonus = 0,
    this.otherBonus = 0,
    this.overtimeHours = 0,
    this.overtimeNormalRate = 1.5,
    this.overtimeWeekendRate = 2.0,
    this.overtimeHolidayRate = 3.0,
    this.overtimePay = 0,
    this.bhxh = 0,
    this.bhyt = 0,
    this.bhtn = 0,
    this.personalTax = 0,
    this.otherDeductions = 0,
    this.standardWorkingDays = 22,
    this.actualWorkingDays = 0,
    this.paidLeaveDays = 0,
    this.unpaidLeaveDays = 0,
    this.sickLeaveDays = 0,
    this.lateDays = 0,
    this.absentDays = 0,
    required this.netSalary,
  });

  /// Period string (MM/YYYY format)
  String get periodString => '$month/$year';

  /// Tổng phụ cấp
  double get totalAllowances => 
      mealAllowance + transportAllowance + phoneAllowance + 
      housingAllowance + otherAllowance;

  /// Tổng thưởng
  double get totalBonus => 
      performanceBonus + projectBonus + holidayBonus + otherBonus;

  /// Tổng khấu trừ bảo hiểm
  double get totalInsurance => bhxh + bhyt + bhtn;

  /// Tổng khấu trừ
  double get totalDeductions => 
      bhxh + bhyt + bhtn + personalTax + otherDeductions;

  /// Lương theo ngày
  double get dailySalary => standardWorkingDays > 0 
      ? grossSalary / standardWorkingDays 
      : 0;

  /// Lương OT theo giờ (hourly rate)
  double get hourlyRate => standardWorkingDays > 0 
      ? grossSalary / standardWorkingDays / 8 
      : 0;

  /// Tổng ngày được tính lương = làm thực tế + phép có lương
  int get totalPaidDays => actualWorkingDays + paidLeaveDays;

  /// Tỷ lệ công (%)
  double get workingRatio => standardWorkingDays > 0 
      ? (totalPaidDays / standardWorkingDays * 100) 
      : 0;

  /// Tổng thu nhập trước thuế
  double get totalIncome => 
      baseSalary + totalAllowances + totalBonus + overtimePay;

  /// Tiền lương từ nghỉ ốm (75% từ BHXH)
  double get sickLeavePay => dailySalary * sickLeaveDays * 0.75;

  Salary copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    int? month,
    int? year,
    SalaryStatus? status,
    DateTime? paidAt,
    String? note,
    DateTime? createdAt,
    double? grossSalary,
    double? baseSalary,
    double? mealAllowance,
    double? transportAllowance,
    double? phoneAllowance,
    double? housingAllowance,
    double? otherAllowance,
    double? performanceBonus,
    double? projectBonus,
    double? holidayBonus,
    double? otherBonus,
    double? overtimeHours,
    double? overtimeNormalRate,
    double? overtimeWeekendRate,
    double? overtimeHolidayRate,
    double? overtimePay,
    double? bhxh,
    double? bhyt,
    double? bhtn,
    double? personalTax,
    double? otherDeductions,
    int? standardWorkingDays,
    int? actualWorkingDays,
    int? paidLeaveDays,
    int? unpaidLeaveDays,
    int? sickLeaveDays,
    int? lateDays,
    int? absentDays,
    double? netSalary,
  }) {
    return Salary(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      month: month ?? this.month,
      year: year ?? this.year,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      grossSalary: grossSalary ?? this.grossSalary,
      baseSalary: baseSalary ?? this.baseSalary,
      mealAllowance: mealAllowance ?? this.mealAllowance,
      transportAllowance: transportAllowance ?? this.transportAllowance,
      phoneAllowance: phoneAllowance ?? this.phoneAllowance,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      otherAllowance: otherAllowance ?? this.otherAllowance,
      performanceBonus: performanceBonus ?? this.performanceBonus,
      projectBonus: projectBonus ?? this.projectBonus,
      holidayBonus: holidayBonus ?? this.holidayBonus,
      otherBonus: otherBonus ?? this.otherBonus,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      overtimeNormalRate: overtimeNormalRate ?? this.overtimeNormalRate,
      overtimeWeekendRate: overtimeWeekendRate ?? this.overtimeWeekendRate,
      overtimeHolidayRate: overtimeHolidayRate ?? this.overtimeHolidayRate,
      overtimePay: overtimePay ?? this.overtimePay,
      bhxh: bhxh ?? this.bhxh,
      bhyt: bhyt ?? this.bhyt,
      bhtn: bhtn ?? this.bhtn,
      personalTax: personalTax ?? this.personalTax,
      otherDeductions: otherDeductions ?? this.otherDeductions,
      standardWorkingDays: standardWorkingDays ?? this.standardWorkingDays,
      actualWorkingDays: actualWorkingDays ?? this.actualWorkingDays,
      paidLeaveDays: paidLeaveDays ?? this.paidLeaveDays,
      unpaidLeaveDays: unpaidLeaveDays ?? this.unpaidLeaveDays,
      sickLeaveDays: sickLeaveDays ?? this.sickLeaveDays,
      lateDays: lateDays ?? this.lateDays,
      absentDays: absentDays ?? this.absentDays,
      netSalary: netSalary ?? this.netSalary,
    );
  }

  @override
  List<Object?> get props => [
        id, employeeId, employeeName, month, year, status, paidAt, note, createdAt,
        grossSalary, baseSalary, mealAllowance, transportAllowance, phoneAllowance,
        housingAllowance, otherAllowance, performanceBonus, projectBonus,
        holidayBonus, otherBonus, overtimeHours, overtimeNormalRate,
        overtimeWeekendRate, overtimeHolidayRate, overtimePay, bhxh, bhyt, bhtn,
        personalTax, otherDeductions, standardWorkingDays, actualWorkingDays,
        paidLeaveDays, unpaidLeaveDays, sickLeaveDays, lateDays, absentDays, netSalary,
      ];
}
