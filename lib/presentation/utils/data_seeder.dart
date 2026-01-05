import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/hr_repository.dart';

class DataSeeder {
  final HRRepository _repository;

  DataSeeder(this._repository);

  Future<void> seedSalaryAndLeaveData() async {
    debugPrint('=== STARTING DATA SEEDING ===');
    
    // 1. Get all employees
    final result = await _repository.getEmployees();
    
    await result.fold(
      (failure) async {
        debugPrint('Failed to get employees: ${failure.message}');
      },
      (employees) async {
        debugPrint('Found ${employees.length} employees. Generating leave data...');
        
        final now = DateTime.now();
        final random = Random();
        
        // 2. Generate leave requests for each employee
        for (final employee in employees) {
          // Skip some employees randomly (30% chance of no leave)
          if (random.nextDouble() < 0.3) continue;
          
          // Generate 1-3 leave requests per employee
          final leaveCount = random.nextInt(3) + 1;
          
          for (int i = 0; i < leaveCount; i++) {
            // Random month (current or previous)
            final isCurrentMonth = random.nextBool();
            final month = isCurrentMonth ? now.month : (now.month - 1);
            final year = now.year;
            
            // Handle January edge case for previous month
            final effectiveMonth = month == 0 ? 12 : month;
            final effectiveYear = month == 0 ? year - 1 : year;
            
            // Random days
            final day = random.nextInt(20) + 1;
            final duration = random.nextInt(3) + 1; // 1-3 days
            
            final startDate = DateTime(effectiveYear, effectiveMonth, day);
            final endDate = startDate.add(Duration(days: duration - 1));
            
            // Random type
            final types = LeaveType.values;
            final type = types[random.nextInt(types.length)];
            
            // Create request
            final request = LeaveRequest(
              id: '', // Repo will assign
              userId: employee.userId ?? employee.id, // Prefer userId for auth link
              userName: employee.hoTen,
              type: type,
              startDate: startDate,
              endDate: endDate,
              reason: 'Nghỉ phép tự động (Seeded Data)',
              createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
              status: LeaveStatus.pending,
            );
            
            try {
              final submitResult = await _repository.submitLeaveRequest(request);
              
              await submitResult.fold(
                (failure) async => debugPrint('Authorized users only: ${failure.message}'), 
                (submittedRequest) async {
                  debugPrint('Created leave for ${employee.hoTen}');
                  
                  // Randomly approve (80% chance)
                  if (random.nextDouble() < 0.8) {
                    await _repository.approveLeaveRequest(
                      submittedRequest.id, 
                      'Đồng ý (Auto approved)'
                    );
                    debugPrint('Approved leave ${submittedRequest.id}');
                  }
                }
              );
            } catch (e) {
              debugPrint('Error creating leave: $e');
            }
          }
        }
        
        debugPrint('=== LEAVE DATA GENERATED ===');
        debugPrint('=== GENERATING SALARY DATA ===');
        
        // 3. Generate salaries for current month
        final salaryResult = await _repository.generateMonthlySalaries(
          month: now.month,
          year: now.year,
        );
        
        salaryResult.fold(
          (failure) => debugPrint('Failed to generate salaries: ${failure.message}'),
          (salaries) => debugPrint('Successfully generated ${salaries.length} salary records'),
        );
        
        debugPrint('=== SEEDING COMPLETED ===');
      },
    );
  }
}
