/// HR Data Source - Firebase Firestore operations for HR management.

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/hr_dashboard_stats.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/contract.dart';
import '../../domain/entities/salary.dart';
import '../../domain/entities/evaluation.dart';
import '../../domain/services/salary_calculator.dart';

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

  /// Submit a new leave request
  Future<LeaveRequest> submitLeaveRequest(LeaveRequest request);

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

  /// Delete employee
  Future<void> deleteEmployee(String id);

  // ==================== CONTRACT METHODS ====================
  
  /// Get all contracts
  Future<List<Contract>> getContracts({String? statusFilter});

  // ==================== SALARY METHODS ====================
  
  /// Get salaries by period
  Future<List<Salary>> getSalaries({int? month, int? year});

  /// Generate monthly salaries for all employees
  Future<List<Salary>> generateMonthlySalaries({
    required int month,
    required int year,
  });

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

  HRDataSourceImpl({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

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
    
    // Get all employees to count per department
    final employeesSnapshot = await _employeesRef.get();
    final employeeCountByDeptId = <String, int>{};
    
    for (final doc in employeesSnapshot.docs) {
      final phongBanId = doc.data()['phongBanId'] as String?;
      if (phongBanId != null && phongBanId.isNotEmpty) {
        employeeCountByDeptId[phongBanId] = (employeeCountByDeptId[phongBanId] ?? 0) + 1;
      }
    }
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Department(
        id: doc.id,
        tenPhongBan: data['tenPhongBan'] ?? '',
        moTa: data['moTa'],
        soNhanVien: employeeCountByDeptId[doc.id] ?? 0,
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
    debugPrint('=== GET PENDING LEAVE REQUESTS ===');
    try {
      // Get all leave requests and filter locally to avoid Firestore composite index requirement
      final snapshot = await _leaveRequestsRef.get();
      debugPrint('Total docs in leave_requests: ${snapshot.docs.length}');
      
      final allRequests = snapshot.docs.map((doc) {
        debugPrint('Doc ${doc.id}: status=${doc.data()['status']}');
        return _leaveRequestFromFirestore(doc);
      }).toList();
      
      // Filter for pending status
      final pendingRequests = allRequests.where((r) => r.status == LeaveStatus.pending).toList();
      
      // Sort by createdAt descending
      pendingRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('Found ${pendingRequests.length} pending leave requests');
      return pendingRequests;
    } catch (e, stackTrace) {
      debugPrint('Error getting pending leave requests: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<LeaveRequest>> getAllLeaveRequests() async {
    debugPrint('=== GET ALL LEAVE REQUESTS ===');
    final snapshot = await _leaveRequestsRef
        .orderBy('createdAt', descending: true)
        .get();
    debugPrint('Found ${snapshot.docs.length} total leave requests');
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

  @override
  Future<LeaveRequest> submitLeaveRequest(LeaveRequest request) async {
    debugPrint('=== SUBMIT LEAVE REQUEST ===');
    debugPrint('userId: ${request.userId}');
    debugPrint('userName: ${request.userName}');
    debugPrint('type: ${request.type.value}');
    debugPrint('reason: ${request.reason}');
    
    final docRef = await _leaveRequestsRef.add({
      'userId': request.userId,
      'userName': request.userName,
      'type': request.type.value,
      'startDate': Timestamp.fromDate(request.startDate),
      'endDate': Timestamp.fromDate(request.endDate),
      'reason': request.reason,
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('Created leave request with ID: ${docRef.id}');

    return LeaveRequest(
      id: docRef.id,
      userId: request.userId,
      userName: request.userName,
      type: request.type,
      startDate: request.startDate,
      endDate: request.endDate,
      reason: request.reason,
      status: LeaveStatus.pending,
      createdAt: DateTime.now(),
    );
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
    try {
      // Generate employee code
      final employeesCount = (await _employeesRef.get()).docs.length;
      final maNhanVien = 'NV${(employeesCount + 1).toString().padLeft(4, '0')}';

      // Get department name if department is assigned
      String? tenPhongBan;
      if (phongBanId != null && phongBanId.isNotEmpty) {
        final deptDoc = await _departmentsRef.doc(phongBanId).get();
        if (deptDoc.exists) {
          tenPhongBan = deptDoc.data()?['tenPhongBan'] as String?;
        }
      }

      // Create Firebase Auth account using secondary app to avoid auto-switching
      String? userId;
      try {
        final secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
          options: Firebase.app().options,
        );
        
        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        
        final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        userId = userCredential.user?.uid;
        
        // Sign out from secondary app and delete it
        await secondaryAuth.signOut();
        await secondaryApp.delete();
      } catch (authError) {
        if (authError is FirebaseAuthException && authError.code == 'email-already-in-use') {
          debugPrint('Email $email already exists, skipping auth creation');
        } else {
          debugPrint('Error creating auth account: $authError');
        }
      }

      // Create employee document
      final employeeData = {
        'maNhanVien': maNhanVien,
        'hoTen': hoTen,
        'email': email,
        'soDienThoai': soDienThoai,
        'gioiTinh': gioiTinh,
        'phongBanId': phongBanId ?? '',
        'tenPhongBan': tenPhongBan ?? '',
        'chucVuId': chucVuId ?? '',
        'ngayVaoLam': FieldValue.serverTimestamp(),
        'status': 'DANG_LAM_VIEC',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId,
      };

      final docRef = await _employeesRef.add(employeeData);

      // Create user record in 'users' collection if auth account was created
      if (userId != null) {
        await _firestore.collection('users').doc(userId).set({
          'email': email,
          'displayName': hoTen,
          'role': 'employee',
          'employeeId': docRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Update department employee count if department is assigned
      if (phongBanId != null && phongBanId.isNotEmpty) {
        try {
          await _departmentsRef.doc(phongBanId).update({
            'soNhanVien': FieldValue.increment(1),
          });
        } catch (e) {
          debugPrint('Error updating department count: $e');
        }
      }

      return Employee(
        id: docRef.id,
        maNhanVien: maNhanVien,
        userId: userId,
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

    // Default password for new accounts
    const String defaultPassword = 'Employee@123';

    for (final data in employeesData) {
      try {
        codeCounter++;
        final maNhanVien = 'NV${codeCounter.toString().padLeft(4, '0')}';

        // Get email and password from CSV
        final email = (data['email'] ?? '').toString().trim();
        final password = (data['matkhau'] ?? data['mat_khau'] ?? data['password'] ?? defaultPassword).toString();
        
        // Skip if no email
        if (email.isEmpty) {
          debugPrint('Skipping employee without email');
          continue;
        }

        // Get department name from CSV and look up the actual department ID
        final phongBanFromCSV = (data['phongban'] ?? data['phong_ban'] ?? data['phongbanid'] ?? '').toString().trim();
        String? phongBanId = defaultDepartmentId;
        String? tenPhongBan;
        
        // If department name is provided, look up the actual department ID
        if (phongBanFromCSV.isNotEmpty && phongBanId == null) {
          final deptQuery = await _departmentsRef
              .where('tenPhongBan', isEqualTo: phongBanFromCSV)
              .limit(1)
              .get();
          
          if (deptQuery.docs.isNotEmpty) {
            phongBanId = deptQuery.docs.first.id;
            tenPhongBan = deptQuery.docs.first.data()['tenPhongBan'] as String?;
          } else {
            debugPrint('Department "$phongBanFromCSV" not found, skipping department assignment');
          }
        }

        // Get gender
        final gioiTinhRaw = (data['gioitinh'] ?? data['gioi_tinh'] ?? data['gender'] ?? 'Nam').toString().toLowerCase();
        final gioiTinh = gioiTinhRaw.contains('nữ') || gioiTinhRaw.contains('nu') || gioiTinhRaw.contains('female') ? 'Nữ' : 'Nam';

        // Create Firebase Auth account using secondary app to avoid auto-switching
        String? userId;
        try {
          final secondaryApp = await Firebase.initializeApp(
            name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}_${email.hashCode}',
            options: Firebase.app().options,
          );
          
          final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
          
          final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
            email: email,
            password: password.isEmpty ? defaultPassword : password,
          );
          userId = userCredential.user?.uid;
          
          // Sign out from secondary app and delete it
          await secondaryAuth.signOut();
          await secondaryApp.delete();
        } catch (authError) {
          if (authError is FirebaseAuthException && authError.code == 'email-already-in-use') {
            debugPrint('Email $email already exists, skipping auth creation');
          } else {
            debugPrint('Error creating auth account: $authError');
          }
        }

        // Create employee data
        final employeeData = {
          'maNhanVien': maNhanVien,
          'hoTen': data['hoten'] ?? data['ho_ten'] ?? data['name'] ?? '',
          'email': email,
          'soDienThoai': data['sodienthoai'] ?? data['sdt'] ?? data['phone'] ?? '',
          'gioiTinh': gioiTinh,
          'cccd': data['cccd'] ?? data['cmnd'] ?? '',
          'diaChi': data['diachi'] ?? data['dia_chi'] ?? data['address'] ?? '',
          'phongBanId': phongBanId ?? '',
          'tenPhongBan': tenPhongBan ?? '',
          'chucVuId': data['chucvuid'] ?? data['chuc_vu'] ?? '',
          'ngayVaoLam': FieldValue.serverTimestamp(),
          'status': 'DANG_LAM_VIEC',
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userId,
        };

        final docRef = await _employeesRef.add(employeeData);

        // Create user record in 'users' collection if auth account was created
        if (userId != null) {
          await _firestore.collection('users').doc(userId).set({
            'email': email,
            'displayName': employeeData['hoTen'],
            'role': 'employee',
            'employeeId': docRef.id,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Update department employee count if department is assigned
        if (phongBanId != null && phongBanId.isNotEmpty) {
          try {
            await _departmentsRef.doc(phongBanId).update({
              'soNhanVien': FieldValue.increment(1),
            });
          } catch (e) {
            debugPrint('Error updating department count: $e');
          }
        }

        importedEmployees.add(Employee(
          id: docRef.id,
          maNhanVien: maNhanVien,
          userId: userId,
          hoTen: employeeData['hoTen'] as String,
          email: employeeData['email'] as String,
          soDienThoai: employeeData['soDienThoai'] as String?,
          gioiTinh: gioiTinh,
          cccd: employeeData['cccd'] as String?,
          diaChi: employeeData['diaChi'] as String?,
          phongBanId: phongBanId,
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

  @override
  Future<void> deleteEmployee(String id) async {
    // Get employee data first
    final doc = await _employeesRef.doc(id).get();
    if (!doc.exists) return;

    final data = doc.data();
    final phongBanId = data?['phongBanId'] as String?;
    final userId = data?['userId'] as String?;

    // Delete employee document
    await _employeesRef.doc(id).delete();

    // Update department employee count
    if (phongBanId != null && phongBanId.isNotEmpty) {
      try {
        await _departmentsRef.doc(phongBanId).update({
          'soNhanVien': FieldValue.increment(-1),
        });
      } catch (e) {
        debugPrint('Error updating department count: $e');
      }
    }

    // Delete user record if exists
    if (userId != null && userId.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(userId).delete();
      } catch (e) {
        debugPrint('Error deleting user record: $e');
      }
    }
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

  @override
  Future<List<Salary>> generateMonthlySalaries({
    required int month,
    required int year,
  }) async {
    debugPrint('=== GENERATING MONTHLY SALARIES for $month/$year ===');
    
    // 1. Get all active employees
    final employees = await getEmployees();
    final activeEmployees = employees.where((e) => e.status == EmployeeStatus.working).toList();
    debugPrint('Found ${activeEmployees.length} active employees');
    
    // 2. Get all approved leave requests for this month
    final allLeaves = await getAllLeaveRequests();
    final approvedLeaves = allLeaves.where((l) => l.status == LeaveStatus.approved).toList();
    debugPrint('Found ${approvedLeaves.length} approved leave requests');
    
    // 3. Calculate salary for each employee
    final List<Salary> generatedSalaries = [];
    
    for (final employee in activeEmployees) {
      // Get leaves for this employee in this month
      final employeeLeaves = approvedLeaves.where((l) {
        if (l.userId != employee.userId && l.userId != employee.id) return false;
        
        final monthStart = DateTime(year, month, 1);
        final monthEnd = DateTime(year, month + 1, 0);
        return !(l.endDate.isBefore(monthStart) || l.startDate.isAfter(monthEnd));
      }).toList();
      
      // Calculate salary
      final salary = SalaryCalculator.calculateMonthlySalary(
        employee: employee,
        month: month,
        year: year,
        approvedLeaves: employeeLeaves,
        actualWorkingDays: 22, // Default, could be from attendance
        mealAllowance: employee.phuCap ?? 0,
      );
      
      // Save to Firestore
      final docRef = await _salariesRef.add({
        'employeeId': employee.id,
        'employeeName': employee.hoTen,
        'month': month,
        'year': year,
        'grossSalary': salary.grossSalary,
        'baseSalary': salary.baseSalary,
        'mealAllowance': salary.mealAllowance,
        'transportAllowance': salary.transportAllowance,
        'performanceBonus': salary.performanceBonus,
        'overtimeHours': salary.overtimeHours,
        'overtimePay': salary.overtimePay,
        'bhxh': salary.bhxh,
        'bhyt': salary.bhyt,
        'bhtn': salary.bhtn,
        'personalTax': salary.personalTax,
        'standardWorkingDays': salary.standardWorkingDays,
        'actualWorkingDays': salary.actualWorkingDays,
        'paidLeaveDays': salary.paidLeaveDays,
        'unpaidLeaveDays': salary.unpaidLeaveDays,
        'sickLeaveDays': salary.sickLeaveDays,
        'netSalary': salary.netSalary,
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      generatedSalaries.add(salary.copyWith(id: docRef.id));
      debugPrint('Generated salary for ${employee.hoTen}: ${salary.netSalary}');
    }
    
    debugPrint('Generated ${generatedSalaries.length} salary records');
    return generatedSalaries;
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

