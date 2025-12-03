# MedDiet Admin Panel - Project Structure

## Overview
A complete Flutter admin panel application with splash screen, login, and dashboard with sidebar navigation.

## Folder Structure

```
lib/
├── constants/
│   ├── app_colors.dart          # Color constants for the app
│   └── app_theme.dart           # Theme configuration
│
├── models/
│   ├── menu_item_model.dart     # Model for sidebar menu items
│   └── user_model.dart          # Model for user data
│
├── screens/
│   ├── splash_screen.dart       # Animated splash screen (3 seconds)
│   ├── login_screen.dart        # Login screen with form validation
│   ├── admin_panel.dart         # Main admin panel layout
│   └── pages/
│       ├── dashboard_page.dart      # Dashboard with stats and charts
│       ├── users_page.dart          # Users management (empty)
│       ├── patients_page.dart       # Patients management (empty)
│       ├── doctors_page.dart        # Doctors management (empty)
│       ├── appointments_page.dart   # Appointments (empty)
│       ├── diet_plans_page.dart     # Diet plans (empty)
│       ├── nutrition_page.dart      # Nutrition management (empty)
│       ├── reports_page.dart        # Reports & analytics (empty)
│       └── settings_page.dart       # Settings (empty)
│
├── widgets/
│   └── sidebar_widget.dart      # Reusable sidebar component
│
├── utils/                       # Utility functions (empty for now)
│
└── main.dart                    # Application entry point
```

## Features Implemented

### 1. Splash Screen
- Animated logo with fade and scale effects
- Green gradient background (medical theme)
- Auto-navigates to login after 3 seconds
- Medical services icon

### 2. Login Screen
- Email and password fields with validation
- Password visibility toggle
- Loading state during login
- Forgot password link
- Responsive card design
- Green gradient background

### 3. Admin Panel
- **Sidebar Navigation:**
  - Dashboard
  - Users
  - Patients
  - Doctors
  - Appointments
  - Diet Plans
  - Nutrition
  - Reports
  - Settings

- **Top AppBar:**
  - Page title
  - Search bar
  - Notifications icon with badge
  - Profile dropdown

### 4. Dashboard Page (Fully Implemented)
- **Statistics Cards:**
  - Total Patients (1,234)
  - Total Doctors (56)
  - Appointments (89)
  - Diet Plans (342)
  - Each with growth percentage

- **Recent Appointments:**
  - List of upcoming appointments
  - Patient and doctor names
  - Time slots
  - Color-coded status

- **Quick Actions:**
  - Add Patient
  - New Appointment
  - Create Diet Plan
  - View Reports

### 5. Other Pages
All other pages (Users, Patients, Doctors, etc.) show:
- Large icon
- Page title
- "Under construction" message
- Centered layout

## Color Scheme

### Primary Colors
- **Primary Green:** `#2E7D32` (Medical/Health theme)
- **Primary Light:** `#60AD5E`
- **Primary Dark:** `#005005`

### Accent Colors
- **Accent Cyan:** `#00BCD4`
- **Accent Light:** `#62EFFF`
- **Accent Dark:** `#008BA3`

### Background Colors
- **Background:** `#F5F5F5`
- **Card Background:** `#FFFFFF`
- **Sidebar Background:** `#1E1E2D` (Dark)
- **Sidebar Hover:** `#27293D`

### Status Colors
- **Success:** `#4CAF50` (Green)
- **Warning:** `#FFC107` (Yellow)
- **Error:** `#F44336` (Red)
- **Info:** `#2196F3` (Blue)

## Navigation Flow

```
Splash Screen (3s)
    ↓
Login Screen
    ↓
Admin Panel
    ├── Dashboard (default)
    ├── Users
    ├── Patients
    ├── Doctors
    ├── Appointments
    ├── Diet Plans
    ├── Nutrition
    ├── Reports
    └── Settings
```

## Models

### MenuItemModel
```dart
- id: String
- title: String
- icon: IconData
- route: String
- subItems: List<MenuItemModel>? (optional)
```

### UserModel
```dart
- id: String
- name: String
- email: String
- role: String
- avatar: String? (optional)
```

## How to Run

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

3. Build for production:
```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web

# Windows
flutter build windows
```

## Key Features

✅ Animated splash screen with medical theme
✅ Professional login screen with validation
✅ Responsive admin panel layout
✅ Dark sidebar with hover effects
✅ Top navigation bar with search and notifications
✅ Fully functional dashboard with statistics
✅ 9 navigation pages (8 empty, ready for development)
✅ Medical/health color scheme (green theme)
✅ Material Design 3
✅ No linter errors
✅ Clean folder structure
✅ Reusable components

## Next Steps

To complete the application, you can:
1. Implement CRUD operations for each page
2. Add API integration
3. Implement state management (Provider/Riverpod/Bloc)
4. Add data tables for list views
5. Create forms for adding/editing records
6. Add charts and analytics
7. Implement authentication logic
8. Add user role management
9. Create responsive layouts for mobile
10. Add dark mode support

## Dependencies

Current dependencies in `pubspec.yaml`:
- flutter (SDK)
- cupertino_icons: ^1.0.8

Dev dependencies:
- flutter_test (SDK)
- flutter_lints: ^5.0.0

## Notes

- All pages except Dashboard show "Under construction" message
- Login currently has no backend validation (simulated delay)
- Sidebar menu items are hardcoded in `sidebar_widget.dart`
- Color scheme follows medical/healthcare theme with green as primary
- All models are in the `models/` subfolder as requested

