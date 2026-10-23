import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/patient/patient_dashboard.dart';
import 'screens/doctor/doctor_dashboard.dart';
import 'screens/pharmacy/pharmacy_dashboard.dart';
import 'screens/lab/lab_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/patient/payment_screen.dart';
import 'screens/patient/payment_success_screen.dart';
import 'models/appointment_model.dart';
import 'screens/shared/prescription_list_screen.dart';
import 'screens/doctor/prescription_form_screen.dart';
import 'screens/pharmacy/prescription_verification_screen.dart';
import 'services/notification_service.dart';
import 'screens/ss_portal/ss_login_screen.dart';
import 'screens/ss_portal/ss_dashboard_screen.dart';
import 'screens/ss_portal/medical_controller_dashboard.dart';
import 'screens/ss_portal/ss_portal_main_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // Restore saved user session
  await AuthService().loadSavedSession();
  
  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(const EasyHealthApp());
}

class EasyHealthApp extends StatelessWidget {
  const EasyHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'EasyHealth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardRouter(),
        '/payment': (context) => PaymentScreen(appointment: ModalRoute.of(context)!.settings.arguments as AppointmentModel),
        '/payment-success': (context) => const PaymentSuccessScreen(),
        '/prescriptions': (context) => const PrescriptionListScreen(),
        '/create-prescription': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PrescriptionFormScreen(
            patientId: args['patientId'],
            patientName: args['patientName'],
            appointmentId: args['appointmentId'],
          );
        },
        '/verify-prescription': (context) => const PrescriptionVerificationScreen(),
        '/ss-portal-login': (context) => const SSPortalLoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}

class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      NotificationService().disconnectSocket();
      return const LoginScreen();
    }

    // Connect to real-time notification socket & fetch persistent notifications
    NotificationService().connectSocket(user.id);
    NotificationService().fetchNotifications();

    // Initial sync of medication reminders if patient
    if (user.role == UserRole.patient) {
      NotificationService().syncMedicationReminders();
    }

    switch (user.role) {
      case UserRole.patient:
        return const PatientDashboard();
      case UserRole.doctor:
        return const DoctorDashboard();
      case UserRole.pharmacy:
        return const PharmacyDashboard();
      case UserRole.lab:
        return const LabDashboard();
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.socialSecurity:
      case UserRole.medicalController:
        return const SSPortalMainScreen();
    }
  }
}
