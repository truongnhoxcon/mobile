import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'config/dependencies/injection_container.dart' as di;
import 'domain/repositories/hr_repository.dart';
import 'presentation/utils/data_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize dependencies
  await di.init();
  
  runApp(const SeederApp());
}

class SeederApp extends StatefulWidget {
  const SeederApp({super.key});

  @override
  State<SeederApp> createState() => _SeederAppState();
}

class _SeederAppState extends State<SeederApp> {
  String _status = 'Đang khởi tạo...';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _startSeeding();
  }

  Future<void> _startSeeding() async {
    setState(() {
      _status = 'Đang kết nối Database...';
      _logs.add('Bắt đầu quy trình seed data...');
    });

    try {
      final repository = di.sl<HRRepository>();
      final seeder = DataSeeder(repository);

      setState(() {
        _status = 'Đang tạo dữ liệu... (Vui lòng đợi)';
        _logs.add('Found HRRepository instance');
      });

      // Wrap seeder logs? 
      // Ideally DataSeeder uses debugPrint which shows in console, but we want UI feedback too.
      // For now, just run it.
      
      await seeder.seedSalaryAndLeaveData();

      setState(() {
        _status = 'Hoàn tất!';
        _logs.add('Đã tạo xong dữ liệu mẫu.');
        _logs.add('Vui lòng tắt ứng dụng này và chạy lại main.dart');
      });
    } catch (e) {
      setState(() {
        _status = 'Lỗi!';
        _logs.add('Error: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Data Seeder Tool')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _status,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('> ${_logs[index]}', style: const TextStyle(fontFamily: 'monospace')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
