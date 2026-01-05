/// Salary Calculator Service
/// Tính lương tự động theo quy định Việt Nam

import '../entities/salary.dart';
import '../entities/leave_request.dart';
import '../entities/employee.dart';

class SalaryCalculator {
  // Tỷ lệ bảo hiểm theo quy định (phần người lao động đóng)
  static const double bhxhRate = 0.08;   // BHXH 8%
  static const double bhytRate = 0.015;  // BHYT 1.5%
  static const double bhtnRate = 0.01;   // BHTN 1%
  
  // Mức lương tối thiểu vùng 1 (Hà Nội, HCM) năm 2024
  static const double minimumWage = 4680000;
  
  // Mức giảm trừ gia cảnh
  static const double personalDeduction = 11000000;  // Bản thân
  static const double dependentDeduction = 4400000;  // Người phụ thuộc
  
  // Ngày công chuẩn
  static const int standardWorkingDays = 22;

  /// Tính lương cho một nhân viên trong một tháng
  static Salary calculateMonthlySalary({
    required Employee employee,
    required int month,
    required int year,
    required List<LeaveRequest> approvedLeaves,
    int actualWorkingDays = 22,
    int dependents = 0,
    double overtimeHours = 0,
    double performanceBonus = 0,
    double mealAllowance = 0,
    double transportAllowance = 0,
  }) {
    final grossSalary = employee.luongCoBan ?? 0;
    
    // Tính ngày nghỉ phép trong tháng
    int paidLeaveDays = 0;
    int unpaidLeaveDays = 0;
    int sickLeaveDays = 0;
    
    for (final leave in approvedLeaves) {
      if (leave.status != LeaveStatus.approved) continue;
      
      // Kiểm tra xem nghỉ phép có nằm trong tháng này không
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0);
      
      if (leave.endDate.isBefore(monthStart) || leave.startDate.isAfter(monthEnd)) {
        continue; // Không nằm trong tháng này
      }
      
      // Tính số ngày nghỉ trong tháng
      final effectiveStart = leave.startDate.isBefore(monthStart) ? monthStart : leave.startDate;
      final effectiveEnd = leave.endDate.isAfter(monthEnd) ? monthEnd : leave.endDate;
      final days = effectiveEnd.difference(effectiveStart).inDays + 1;
      
      // Phân loại theo loại nghỉ phép
      if (leave.type == LeaveType.unpaid) {
        unpaidLeaveDays += days;
      } else if (leave.type == LeaveType.sickPaid) {
        sickLeaveDays += days;
      } else if (leave.type.isPaid) {
        paidLeaveDays += days;
      } else {
        unpaidLeaveDays += days;
      }
    }
    
    // Tổng ngày được tính lương đầy đủ
    final totalPaidDays = actualWorkingDays + paidLeaveDays;
    
    // Tính lương cơ bản theo ngày công
    final dailySalary = grossSalary / standardWorkingDays;
    final baseSalary = dailySalary * totalPaidDays;
    
    // Tính tiền nghỉ ốm (75% từ BHXH)
    final sickLeavePay = dailySalary * sickLeaveDays * 0.75;
    
    // Tính tiền OT (150% ngày thường)
    final hourlyRate = dailySalary / 8;
    final overtimePay = hourlyRate * overtimeHours * 1.5;
    
    // Tổng thu nhập chịu thuế
    final totalAllowances = mealAllowance + transportAllowance;
    final totalIncome = baseSalary + sickLeavePay + overtimePay + performanceBonus + totalAllowances;
    
    // Tính BHXH, BHYT, BHTN (trên mức lương đóng BHXH)
    // Lương đóng BHXH = min(grossSalary, 20 * lương cơ sở)
    final bhxhBaseSalary = grossSalary; // Simplified, should be capped
    final bhxh = bhxhBaseSalary * bhxhRate;
    final bhyt = bhxhBaseSalary * bhytRate;
    final bhtn = bhxhBaseSalary * bhtnRate;
    final totalInsurance = bhxh + bhyt + bhtn;
    
    // Thu nhập chịu thuế = Tổng TN - Bảo hiểm - Giảm trừ gia cảnh
    final taxableIncome = totalIncome - totalInsurance - personalDeduction - (dependents * dependentDeduction);
    
    // Tính thuế TNCN theo bậc
    final personalTax = calculatePersonalIncomeTax(taxableIncome);
    
    // Tổng khấu trừ
    final totalDeductions = totalInsurance + personalTax;
    
    // Lương thực nhận
    final netSalary = totalIncome - totalDeductions;
    
    return Salary(
      id: '',
      employeeId: employee.id,
      employeeName: employee.hoTen,
      month: month,
      year: year,
      status: SalaryStatus.draft,
      createdAt: DateTime.now(),
      grossSalary: grossSalary,
      baseSalary: baseSalary,
      mealAllowance: mealAllowance,
      transportAllowance: transportAllowance,
      performanceBonus: performanceBonus,
      overtimeHours: overtimeHours,
      overtimePay: overtimePay,
      bhxh: bhxh,
      bhyt: bhyt,
      bhtn: bhtn,
      personalTax: personalTax,
      standardWorkingDays: standardWorkingDays,
      actualWorkingDays: actualWorkingDays,
      paidLeaveDays: paidLeaveDays,
      unpaidLeaveDays: unpaidLeaveDays,
      sickLeaveDays: sickLeaveDays,
      netSalary: netSalary > 0 ? netSalary : 0,
    );
  }
  
  /// Tính thuế TNCN theo biểu thuế lũy tiến từng phần
  static double calculatePersonalIncomeTax(double taxableIncome) {
    if (taxableIncome <= 0) return 0;
    
    // Biểu thuế lũy tiến theo tháng (VND)
    // Bậc 1: Đến 5 triệu: 5%
    // Bậc 2: 5-10 triệu: 10%
    // Bậc 3: 10-18 triệu: 15%
    // Bậc 4: 18-32 triệu: 20%
    // Bậc 5: 32-52 triệu: 25%
    // Bậc 6: 52-80 triệu: 30%
    // Bậc 7: Trên 80 triệu: 35%
    
    double tax = 0;
    double remaining = taxableIncome;
    
    // Bậc 1: 5% cho 5 triệu đầu
    if (remaining > 0) {
      final bracket = remaining.clamp(0, 5000000);
      tax += bracket * 0.05;
      remaining -= bracket;
    }
    
    // Bậc 2: 10% cho 5 triệu tiếp
    if (remaining > 0) {
      final bracket = remaining.clamp(0, 5000000);
      tax += bracket * 0.10;
      remaining -= bracket;
    }
    
    // Bậc 3: 15% cho 8 triệu tiếp
    if (remaining > 0) {
      final bracket = remaining.clamp(0, 8000000);
      tax += bracket * 0.15;
      remaining -= bracket;
    }
    
    // Bậc 4: 20% cho 14 triệu tiếp
    if (remaining > 0) {
      final bracket = remaining.clamp(0, 14000000);
      tax += bracket * 0.20;
      remaining -= bracket;
    }
    
    // Bậc 5: 25% cho 20 triệu tiếp
    if (remaining > 0) {
      final bracket = remaining.clamp(0, 20000000);
      tax += bracket * 0.25;
      remaining -= bracket;
    }
    
    // Bậc 6: 30% cho 28 triệu tiếp
    if (remaining > 0) {
      final bracket = remaining.clamp(0, 28000000);
      tax += bracket * 0.30;
      remaining -= bracket;
    }
    
    // Bậc 7: 35% cho phần còn lại
    if (remaining > 0) {
      tax += remaining * 0.35;
    }
    
    return tax;
  }
}
