import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../blocs/blocs.dart';
import 'tabs/hr_dashboard_tab.dart';
import 'tabs/hr_employees_tab.dart';
import 'tabs/hr_leaves_tab.dart';
import 'tabs/hr_contracts_tab.dart';
import 'tabs/hr_salary_tab.dart';
import 'tabs/hr_evaluations_tab.dart';

import '../../widgets/common/pastel_background.dart';

/// HR Main Screen for HR Manager
/// Contains tabs: Dashboard, Employees, Leaves, Contracts, Salary, Evaluations
class HRMainScreen extends StatefulWidget {
  const HRMainScreen({super.key});

  @override
  State<HRMainScreen> createState() => _HRMainScreenState();
}

class _HRMainScreenState extends State<HRMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<HRBloc>()
        ..add(const HRLoadDashboard())
        ..add(const HRLoadEmployees())
        ..add(const HRLoadLeaveRequests())
        ..add(const HRLoadContracts())
        ..add(const HRLoadSalaries())
        ..add(const HRLoadEvaluations()),
      child: BlocListener<HRBloc, HRState>(
        listenWhen: (previous, current) => 
          previous.status != current.status && 
          current.status == HRStatus.actionSuccess,
        listener: (context, state) {
          // Auto-reload dashboard when employee added/imported
          context.read<HRBloc>().add(const HRLoadDashboard());
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Quản lý Nhân sự',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Tổng quan', icon: Icon(Icons.dashboard)),
                Tab(text: 'Nhân viên', icon: Icon(Icons.people)),
                Tab(text: 'Nghỉ phép', icon: Icon(Icons.event_busy)),
                Tab(text: 'Hợp đồng', icon: Icon(Icons.description)),
                Tab(text: 'Lương', icon: Icon(Icons.paid)),
                Tab(text: 'Đánh giá', icon: Icon(Icons.rate_review)),
              ],
            ),
          ),
          body: PastelBackground(
            child: TabBarView(
              controller: _tabController,
              children: const [
                HRDashboardTab(),
                HREmployeesTab(),
                HRLeavesTab(),
                HRContractsTab(),
                HRSalaryTab(),
                HREvaluationsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

