import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vehicles_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/alerts_screen.dart';
import 'services/notification_service.dart';
import 'services/expiry_checker_service.dart';
import 'services/gps_service.dart';
import 'services/sms_listener_service.dart';
import 'providers/fleet_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  runApp(const ProviderScope(child: MyeTaxiTrackerApp()));
}

class MyeTaxiTrackerApp extends ConsumerStatefulWidget {
  const MyeTaxiTrackerApp({super.key});

  @override
  ConsumerState<MyeTaxiTrackerApp> createState() => _MyeTaxiTrackerAppState();
}

class _MyeTaxiTrackerAppState extends ConsumerState<MyeTaxiTrackerApp> {
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    // Services are initialized after first auth state
    WidgetsBinding.instance.addPostFrameCallback((_) => _initServices());
  }

  Future<void> _initServices() async {
    ref.listenManual(authProvider, (_, next) async {
      final uid = next.value?.uid;
      if (uid != null && !_servicesInitialized) {
        _servicesInitialized = true;

        // GPS & SMS services
        await GpsService().initialize(uid);
        await SmsListenerService().initialize();

        // Document expiry checker
        ExpiryCheckerService().startDailyCheck(uid);

        // Connect to GPS WebSocket server (update URL to your server)
        // GpsService().connectWebSocket('wss://your-gps-server.com/ws?owner=$uid');
        // Or use HTTP polling:
        // GpsService().startHttpPolling('https://your-gps-server.com');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 14 base size
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        title: 'MyeTaxi Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return auth.when(
      loading: () => const _SplashScreen(),
      error: (_, __) => const _SplashScreen(),
      data: (user) => user != null ? const MainShell() : const _LoginScreen(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    VehiclesScreen(),
    TripsScreen(),
    DriversScreen(),
    AlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadAlertCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.border),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'Fleet',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Trips',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Drivers',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                backgroundColor: AppTheme.red,
                child: const Icon(Icons.notifications_outlined),
              ),
              activeIcon: const Icon(Icons.notifications),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SPLASH SCREEN ────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFF0066FF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.local_taxi,
                color: Colors.black, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('MyeTaxi Tracker',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Fleet Intelligence Platform',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: AppTheme.accent,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────────

class _LoginScreen extends StatefulWidget {
  const _LoginScreen();

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accent, Color(0xFF0066FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_taxi,
                  color: Colors.black, size: 34),
              ),
              const SizedBox(height: 24),
              const Text('Welcome back',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text('MyeTaxi Tracker Fleet Platform',
                style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 36),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withOpacity(0.1),
                    border: Border.all(color: AppTheme.red.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                    style: const TextStyle(color: AppTheme.red, fontSize: 13)),
                ),

              const Text('EMAIL', style: TextStyle(
                color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'owner@email.com'),
              ),
              const SizedBox(height: 16),

              const Text('PASSWORD', style: TextStyle(
                color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(hintText: '••••••••'),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2))
                      : const Text('SIGN IN',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontSize: 15,
                          )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Firebase Auth sign in
      // await FirebaseAuth.instance.signInWithEmailAndPassword(
      //   email: _email.text.trim(),
      //   password: _pass.text,
      // );
      // For demo: navigate directly
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }
}
