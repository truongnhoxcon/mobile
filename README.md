# 📱 Enterprise Mobile App

> Ứng dụng quản lý dự án và nhân sự - Flutter + Firebase

## 🚀 Features

- **Project Management**: Dự án, Sprint, Issues, Kanban Board
- **HR Management**: Nhân viên, Chấm công GPS, Nghỉ phép, Bảng lương
- **Real-time Chat**: Messaging, File sharing, Reactions
- **Notifications**: Push & In-app notifications

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter | UI Framework |
| Dart | Programming Language |
| Firebase Auth | Authentication |
| Cloud Firestore | Database |
| Cloud Storage | File Storage |
| Firebase Messaging | Push Notifications |
| BLoC/Cubit | State Management |

## 📂 Project Structure

```
lib/
├── core/           # Core utilities, theme, constants
├── config/         # Routes, dependencies
├── data/           # Models, repositories, datasources
├── domain/         # Entities, repository interfaces
└── presentation/   # BLoCs, Screens, Widgets
```

## 🔧 Setup

1. Install dependencies:
```bash
flutter pub get
```

2. Configure Firebase:
   - Create Firebase project at https://console.firebase.google.com
   - Run `flutterfire configure`

3. Run the app:
```bash
flutter run
```

## 📝 License

MIT License