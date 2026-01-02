/// HR Data Source - Firebase Firestore operations for HR management.

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/hr_dashboard_stats.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/contract.dart';
import '../../domain/entities/salary.dart';
import '../../domain/entities/evaluation.dart';

abstract class HRDataSource {
  /// Get all employees
  Future<List<Employee>> getEmployees();

  /// Get employee by ID
  Future<Employee?> getEmployee(String id);

  /// Get HR Dashboard stats
  Future<HRDashboardStats> getDashboardStats();

  /// Get all departments
  Future<List<Department>> getDepartments();

  /// Add new department
  Future<Department> addDepartment({
    required String name,
    String? description,
    String? managerId,
  });

  /// Update department
  Future<Department> updateDepartment({
    required String id,
    required String name,
    String? description,
    String? managerId,
  });

  /// Delete department
  Future<void> deleteDepartment(String id);

  /// Get all positions
  Future<List<Position>> getPositions();

  /// Get pending leave requests
  Future<List<LeaveRequest>> getPendingLeaveRequests();

  /// Approve leave request
  Future<void> approveLeaveRequest(String id, String note);

  /// Reject leave request
  Future<void> rejectLeaveRequest(String id, String reason);

  /// Get all leave requests
  Future<List<LeaveRequest>> getAllLeaveRequests();

  /// Add new employee (create user + employee record)
  Future<Employee> addEmployee({
    required String hoTen,
    required String email,
    required String password,
    String? soDienThoai,
    String gioiTinh,
    String? phongBanId,
    String? chucVuId,
  });

  /// Import employees from CSV (only creates employee records, not auth users)
  Future<List<Employee>> importEmployeesFromCSV(
    List<Map<String, dynamic>> employeesData, {
    String? defaultDepartmentId,
  });

  // ==================== CONTRACT METHODS ====================
  
  /// Get all contracts
  Future<List<Contract>> getContracts({String? statusFilter});

  // ==================== SALARY METHODS ====================
  
  /// Get salaries by period
  Future<List<Salary>> getSalaries({int? month, int? year});

  // ==================== EVALUATION METHODS ====================
  
  /// Get evaluations
  Future<List<Evaluation>> getEvaluations({bool pendingOnly = false});

  /// Approve evaluation
  Future<void> approveEvaluation(String id, String note);

  /// Reject evaluation
  Future<void> rejectEvaluation(String id, String reason);
}

class HRDataSourceImpl implements HRDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HRDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _employeesRef =>
      _firestore.collection('employees');

  CollectionReference<Map<String, dynamic>> get _departmentsRef =>
      _firestore.collection('departments');

  CollectionReference<Map<String, dynamic>> get _positionsRef =>
      _firestore.collection('positions');

  CollectionReference<Map<String, dynamic>> get _leaveRequestsRef =>
      _firestore.collection('leave_requests');

  @override
  Future<List<Employee>> getEmployees() async {
    final snapshot = await _employeesRef.orderBy('hoTen').get();
    return snapshot.docs.map((doc) => _employeeFromFirestore(doc)).toList();
  }

  @override
  Future<Employee?> getEmployee(String id) async {
    final doc = await _employeesRef.doc(id).get();
    if (!doc.exists) return null;
    return _employeeFromFirestore(doc);
  }

  @override
  Future<HRDashboardStats> getDashboardStats() async {
    // Get employee counts
    final employeesSnapshot = await _employeesRef.get();
    final employees = employeesSnapshot.docs;
    
    final totalEmployees = employees.length;
    final activeEmployees = employees.where((doc) {
      final data = doc.data();
      return data['status'] == 'DANG_LAM_VIEC' || data['trangThai'] == 'DANG_LAM_VIEC';
    }).length;
    final terminatedEmployees = employees.where((doc) {
      final data = doc.data();
      return data['status'] == 'NGHI_VIEC' || data['trangThai'] == 'NGHI_VIEC';
    }).length;

    // Get pending leave requests count
    final pendingLeaves = await _leaveRequestsRef
        .where('status', isEqualTo: 'PENDING')
        .get();

    // Count new employees this month
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    int newEmployees = 0;
    for (var doc in employees) {
      final data = doc.data();
      if (data['ngayVaoLam'] != null) {
        DateTime? joinDate;
        if (data['ngayVaoLam'] is Timestamp) {
          joinDate = (data['ngayVaoLam'] as Timestamp).toDate();
        } else if (data['ngayVaoLam'] is String) {
          try {
            joinDate = DateTime.parse(data['ngayVaoLam']);
          } catch (_) {}
        }
        if (joinDate != null && joinDate.isAfter(startOfMonth)) {
          newEmployees++;
        }
      }
    }

    // Gender distribution
    int male = 0;
    int female = 0;
    for (var doc in employees) {
      final data = doc.data();
      final gender = data['gioiTinh']?.toString().toLowerCase() ?? '';
      if (gender == 'nam' || gender == 'male') {
        male++;
      } else if (gender == 'nu' || gender == 'nữ' || gender == 'female') {
        female++;
      }
    }

    return HRDashboardStats(
      tongNhanVien: totalEmployees,
      dangLamViec: activeEmployees,
      nhanVienMoi: newEmployees,
      nghiViec: terminatedEmployees,
      donChoPheDuyet: pendingLeaves.docs.length,
      nhanVienTheoGioiTinh: {'nam': male, 'nu': female},
    );
  }

  @override
  Future<List<Department>> getDepartments() async {
    final snapshot = await _departmentsRef.orderBy('tenPhongBan').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Department(
        id: doc.id,
        tenPhongBan: data['tenPhongBan'] ?? '',
        moTa: data['moTa'],
        soNhanVien: data['soNhanVien'],
      );
    }).toList();
  }

  @override
  Future<Department> addDepartment({
    required String name,
    String? description,
    String? managerId,
  }) async {
    final docRef = await _departmentsRef.add({
      'tenPhongBan': name,
      'moTa': description,
      'managerId': managerId,
      'soNhanVien': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return Department(
      id: docRef.id,
      tenPhongBan: name,
      moTa: description,
      soNhanVien: 0,
    );
  }

  @override
  Future<Department> updateDepartment({
    required String id,
    required String name,
    String? description,
    String? managerId,
  }) async {
    await _departmentsRef.doc(id).update({
      'tenPhongBan': name,
      'moTa': description,
      'managerId': managerId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final doc = await _departmentsRef.doc(id).get();
    final data = doc.data()!;
    return Department(
      id: id,
      tenPhongBan: data['tenPhongBan'] ?? name,
      moTa: data['moTa'],
      soNhanVien: data['soNhanVien'],
    );
  }

  @override
  Future<void> deleteDepartment(String id) async {
    await _departmentsRef.doc(id).delete();
  }


  @override
  Future<List<Position>> getPositions() async {
    final snapshot = await _positionsRef.orderBy('tenChucVu').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Position(
        id: doc.id,
        tenChucVu: data['tenChucVu'] ?? '',
        moTa: data['moTa'],
      );
    }).toList();
  }

  @override
  Future<List<LeaveRequest>> getPendingLeaveRequests() async {
    final snapshot = await _leaveRequestsRef
        .where('status', isEqualTo: 'PENDING')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => _leaveRequestFromFirestore(doc)).toList();
  }

  @override
  Future<List<LeaveRequest>> getAllLeaveRequests() async {
    final snapshot = await _leaveRequestsRef
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => _leaveRequestFromFirestore(doc)).toList();
  }

  @override
  Future<void> approveLeaveRequest(String id, String note) async {
    await _leaveRequestsRef.doc(id).update({
      'status': 'APPROVED',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvalNote': note,
    });
  }

  @override
  Future<void> rejectLeaveRequest(String id, String reason) async {
    await _leaveRequestsRef.doc(id).update({
      'status': 'REJECTED',
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectReason': reason,
    });
  }

  // Helper to convert Firestore doc to Employee
  Employee _employeeFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Employee(
      id: doc.id,
      maNhanVien: data['maNhanVien'],
      userId: data['userId'],
      hoTen: data['hoTen'] ?? '',
      email: data['email'],
      soDienThoai: data['soDienThoai'] ?? data['sdt'],
      cccd: data['cccd'],
      ngaySinh: data['ngaySinh'] is Timestamp 
          ? (data['ngaySinh'] as Timestamp).toDate()
          : data['ngaySinh'] is String ? DateTime.tryParse(data['ngaySinh']) : null,
      gioiTinh: data['gioiTinh'] ?? 'Nam',
      diaChi: data['diaChi'],
      ngayVaoLam: data['ngayVaoLam'] is Timestamp
          ? (data['ngayVaoLam'] as Timestamp).toDate()
          : data['ngayVaoLam'] is String ? DateTime.tryParse(data['ngayVaoLam']) : null,
      phongBanId: data['phongBanId']?.toString() ?? data['phongbanId']?.toString(),
      tenPhongBan: data['tenPhongBan'],
      chucVuId: data['chucVuId']?.toString() ?? data['chucvuId']?.toString(),
      tenChucVu: data['tenChucVu'],
      luongCoBan: (data['luongCoBan'] as num?)?.toDouble(),
      phuCap: (data['phuCap'] as num?)?.toDouble(),
      status: EmployeeStatusExtension.fromString(
          data['status'] ?? data['trangThai'] ?? 'DANG_LAM_VIEC'),
      avatarUrl: data['avatarUrl'],
    );
  }

  // Helper to convert Firestore doc to LeaveRequest
  LeaveRequest _leaveRequestFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return LeaveRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? data['hoTenNhanVien'],
      type: LeaveTypeExtension.fromString(data['type'] ?? data['loaiPhep'] ?? 'ANNUAL'),
      startDate: data['startDate'] is Timestamp
          ? (data['startDate'] as Timestamp).toDate()
          : data['ngayBatDau'] is Timestamp
              ? (data['ngayBatDau'] as Timestamp).toDate()
              : DateTime.now(),
      endDate: data['endDate'] is Timestamp
          ? (data['endDate'] as Timestamp).toDate()
          : data['ngayKetThuc'] is Timestamp
              ? (data['ngayKetThuc'] as Timestamp).toDate()
              : DateTime.now(),
      reason: data['reason'] ?? data['lyDo'] ?? '',
      status: LeaveStatusExtension.fromString(data['status'] ?? data['trangThai'] ?? 'PENDING'),
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'] is Timestamp
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      rejectReason: data['rejectReason'] ?? data['lyDoTuChoi'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  @override
  Future<Employee> addEmployee({
    required String hoTen,
    required String email,
    required String password,
    String? soDienThoai,
    String gioiTinh = 'Nam',
    String? phongBanId,
    String? chucVuId,
  }) async {
    // Store current user to restore later
    final currentUser = _auth.currentUser;
    
    try {
      // Create Firebase Auth user for the new employee
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUserId = userCredential.user!.uid;
      await userCredential.user!.updateDisplayName(hoTen);

      // Generate employee code
      final employeesCount = (await _employeesRef.get()).docs.length;
      final maNhanVien = 'NV${(employeesCount + 1).toString().padLeft(4, '0')}';

      // Create user document
      await _firestore.collection('users').doc(newUserId).set({
        'email': email,
        'displayName': hoTen,
        'phoneNumber': soDienThoai,
        'role': 'EMPLOYEE',
        'departmentId': phongBanId,
        'position': chucVuId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Create employee document
      final employeeData = {
        'maNhanVien': maNhanVien,
        'userId': newUserId,
        'hoTen': hoTen,
        'email': email,
        'soDienThoai': soDienThoai,
        'gioiTinh': gioiTinh,
        'phongBanId': phongBanId,
        'chucVuId': chucVuId,
        'ngayVaoLam': FieldValue.serverTimestamp(),
        'status': 'DANG_LAM_VIEC',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _employeesRef.add(employeeData);

      // Get department name if department is assigned
      String? tenPhongBan;
      if (phongBanId != null && phongBanId.isNotEmpty) {
        // Update department employee count
        await _departmentsRef.doc(phongBanId).update({
          'soNhanVien': FieldValue.increment(1),
        });
        
        // Fetch department name
        final deptDoc = await _departmentsRef.doc(phongBanId).get();
        if (deptDoc.exists) {
          tenPhongBan = deptDoc.data()?['tenPhongBan'] as String?;
          
          // Update employee document with tenPhongBan
          await docRef.update({'tenPhongBan': tenPhongBan});
        }
      }

      // Sign back in as current user (HR Manager)
      // Note: In production, use Admin SDK instead
      if (currentUser != null) {
        // We can't sign back in without password, so HR will need to re-login
        // This is a limitation of client-side Firebase Auth
      }

      return Employee(
        id: docRef.id,
        maNhanVien: maNhanVien,
        userId: newUserId,
        hoTen: hoTen,
        email: email,
        soDienThoai: soDienThoai,
        gioiTinh: gioiTinh,
        phongBanId: phongBanId,
        tenPhongBan: tenPhongBan,
        chucVuId: chucVuId,
        ngayVaoLam: DateTime.now(),
        status: EmployeeStatus.working,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Employee>> importEmployeesFromCSV(
    List<Map<String, dynamic>> employeesData, {
    String? defaultDepartmentId,
  }) async {
    final List<Employee> importedEmployees = [];
    
    // Get current employee count for generating codes
    final existingCount = (await _employeesRef.get()).docs.length;
    int codeCounter = existingCount;

    for (final data in employeesData) {
      try {
        codeCounter++;
        final maNhanVien = 'NV${codeCounter.toString().padLeft(4, '0')}';

        // Use defaultDepartmentId if provided, otherwise try to get from CSV
        final phongBanId = defaultDepartmentId ?? 
            data['phongbanid'] ?? data['phong_ban'] ?? '';

        final employeeData = {
          'maNhanVien': maNhanVien,
          'hoTen': data['hoten'] ?? data['ho_ten'] ?? data['name'] ?? '',
          'email': data['email'] ?? '',
          'soDienThoai': data['sodienthoai'] ?? data['sdt'] ?? data['phone'] ?? '',
          'gioiTinh': data['gioitinh'] ?? data['gioi_tinh'] ?? data['gender'] ?? 'Nam',
          'cccd': data['cccd'] ?? data['cmnd'] ?? '',
          'diaChi': data['diachi'] ?? data['dia_chi'] ?? data['address'] ?? '',
          'phongBanId': phongBanId,
          'chucVuId': data['chucvuid'] ?? data['chuc_vu'] ?? '',
          'ngayVaoLam': FieldValue.serverTimestamp(),
          'status': 'DANG_LAM_VIEC',
          'createdAt': FieldValue.serverTimestamp(),
        };

        final docRef = await _employeesRef.add(employeeData);

        // Get department name and update count if department is assigned
        String? tenPhongBan;
        if (phongBanId.isNotEmpty) {
          await _departmentsRef.doc(phongBanId).update({
            'soNhanVien': FieldValue.increment(1),
          });
          
          // Fetch department name
          final deptDoc = await _departmentsRef.doc(phongBanId).get();
          if (deptDoc.exists) {
            tenPhongBan = deptDoc.data()?['tenPhongBan'] as String?;
            await docRef.update({'tenPhongBan': tenPhongBan});
          }
        }

        importedEmployees.add(Employee(
          id: docRef.id,
          maNhanVien: maNhanVien,
          hoTen: employeeData['hoTen'] as String,
          email: employeeData['email'] as String,
          soDienThoai: employeeData['soDienThoai'] as String?,
          gioiTinh: employeeData['gioiTinh'] as String,
          cccd: employeeData['cccd'] as String?,
          diaChi: employeeData['diaChi'] as String?,
          phongBanId: phongBanId.isNotEmpty ? phongBanId : null,
          tenPhongBan: tenPhongBan,
          ngayVaoLam: DateTime.now(),
          status: EmployeeStatus.working,
        ));
      } catch (e) {
        // Log error but continue with other employees
        debugPrint('Error importing employee: $e');
      }
    }

    return importedEmployees;
  }

  // ==================== CONTRACT IMPLEMENTATIONS ====================

  CollectionReference<Map<String, dynamic>> get _contractsRef =>
      _firestore.collection('contracts');

  @override
  Future<List<Contract>> getContracts({String? statusFilter}) async {
    Query<Map<String, dynamic>> query = _contractsRef;
    
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter.toUpperCase());
    }
    
    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => _contractFromFirestore(doc)).toList();
  }

  Contract _contractFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Contract(
      id: doc.id,
      employeeId: data['employeeId'] ?? data['nhanVienId'] ?? '',
      employeeName: data['employeeName'] ?? data['hoTenNhanVien'],
      contractNumber: data['contractNumber'] ?? data['soHopDong'] ?? 'HD-${doc.id.substring(0, 6)}',
      type: ContractTypeExtension.fromString(data['type'] ?? data['loaiHopDong'] ?? 'INDEFINITE'),
      startDate: data['startDate'] is Timestamp
          ? (data['startDate'] as Timestamp).toDate()
          : data['ngayBatDau'] is Timestamp
              ? (data['ngayBatDau'] as Timestamp).toDate()
              : DateTime.now(),
      endDate: data['endDate'] is Timestamp
          ? (data['endDate'] as Timestamp).toDate()
          : data['ngayKetThuc'] is Timestamp
              ? (data['ngayKetThuc'] as Timestamp).toDate()
              : null,
      grossSalary: (data['grossSalary'] ?? data['salary'] ?? data['luong'] as num?)?.toDouble() ?? 0,
      status: ContractStatusExtension.fromString(data['status'] ?? data['trangThai'] ?? 'ACTIVE'),
      note: data['note'] ?? data['ghiChu'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ==================== SALARY IMPLEMENTATIONS ====================

  CollectionReference<Map<String, dynamic>> get _salariesRef =>
      _firestore.collection('salaries');

  @override
  Future<List<Salary>> getSalaries({int? month, int? year}) async {
    final targetMonth = month ?? DateTime.now().month;
    final targetYear = year ?? DateTime.now().year;
    
    final snapshot = await _salariesRef
        .where('month', isEqualTo: targetMonth)
        .where('year', isEqualTo: targetYear)
        .get();
    
    return snapshot.docs.map((doc) => _salaryFromFirestore(doc)).toList();
  }

  Salary _salaryFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Salary(
      id: doc.id,
      employeeId: data['employeeId'] ?? data['nhanVienId'] ?? '',
      employeeName: data['employeeName'] ?? data['hoTenNhanVien'],
      month: data['month'] ?? data['thang'] ?? DateTime.now().month,
      year: data['year'] ?? data['nam'] ?? DateTime.now().year,
      grossSalary: (data['grossSalary'] ?? data['salary'] ?? data['luong'] as num?)?.toDouble() ?? 0,
      baseSalary: (data['baseSalary'] ?? data['luongCoBan'] as num?)?.toDouble() ?? 0,
      performanceBonus: (data['performanceBonus'] ?? data['bonus'] ?? data['thuong'] as num?)?.toDouble() ?? 0,
      bhxh: (data['bhxh'] as num?)?.toDouble() ?? 0,
      bhyt: (data['bhyt'] as num?)?.toDouble() ?? 0,
      bhtn: (data['bhtn'] as num?)?.toDouble() ?? 0,
      personalTax: (data['personalTax'] ?? data['thue'] as num?)?.toDouble() ?? 0,
      netSalary: (data['netSalary'] ?? data['thucNhan'] as num?)?.toDouble() ?? 0,
      status: SalaryStatusExtension.fromString(data['status'] ?? data['trangThai'] ?? 'PENDING'),
      paidAt: data['paidAt'] is Timestamp
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      note: data['note'] ?? data['ghiChu'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ==================== EVALUATION IMPLEMENTATIONS ====================

  CollectionReference<Map<String, dynamic>> get _evaluationsRef =>
      _firestore.collection('evaluations');

  @override
  Future<List<Evaluation>> getEvaluations({bool pendingOnly = false}) async {
    Query<Map<String, dynamic>> query = _evaluationsRef;
    
    if (pendingOnly) {
      query = query.where('status', isEqualTo: 'PENDING');
    }
    
    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => _evaluationFromFirestore(doc)).toList();
  }

  @override
  Future<void> approveEvaluation(String id, String note) async {
    await _evaluationsRef.doc(id).update({
      'status': 'APPROVED',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvalNote': note,
    });
  }

  @override
  Future<void> rejectEvaluation(String id, String reason) async {
    await _evaluationsRef.doc(id).update({
      'status': 'REJECTED',
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectReason': reason,
    });
  }

  Evaluation _evaluationFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final now = DateTime.now();
    return Evaluation(
      id: doc.id,
      employeeId: data['employeeId'] ?? data['nhanVienId'] ?? '',
      employeeName: data['employeeName'] ?? data['hoTenNhanVien'],
      period: data['period'] ?? data['kyDanhGia'] ?? '',
      startDate: data['startDate'] is Timestamp
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime(now.year, now.month - 3, 1),
      endDate: data['endDate'] is Timestamp
          ? (data['endDate'] as Timestamp).toDate()
          : DateTime(now.year, now.month, 0),
      finalScore: (data['finalScore'] ?? data['score'] ?? data['diem'] as num?)?.toDouble(),
      managerSummary: data['managerSummary'] ?? data['comments'] ?? data['nhanXet'],
      status: EvaluationStatusExtension.fromString(data['status'] ?? data['trangThai'] ?? 'DRAFT'),
      evaluatorId: data['evaluatorId'] ?? data['nguoiDanhGiaId'],
      evaluatorName: data['evaluatorName'] ?? data['tenNguoiDanhGia'],
      rejectReason: data['rejectReason'] ?? data['lyDoTuChoi'],
      approvedAt: data['approvedAt'] is Timestamp
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

