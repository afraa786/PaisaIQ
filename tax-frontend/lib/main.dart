import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/alerts_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/coin_detail_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/theme.dart';

void main() {
  runApp(const ProviderScope(child: AlphaEdgeApp()));
}

class AlphaEdgeApp extends ConsumerWidget {
  const AlphaEdgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/compare',
              name: 'compare',
              builder: (context, state) => const CompareScreen(),
            ),
            GoRoute(
              path: '/alerts',
              name: 'alerts',
              builder: (context, state) => const AlertsScreen(),
            ),
            GoRoute(
              path: '/portfolio',
              name: 'portfolio',
              builder: (context, state) => const PortfolioScreen(),
            ),
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/coin/:coinId',
          name: 'coinDetail',
          builder: (context, state) {
            final coinId = state.pathParameters['coinId'] ?? '';
            return CoinDetailScreen(coinId: coinId);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'AlphaEdge',
      debugShowCheckedModeBanner: false,
      theme: alphaEdgeTheme,
      routeInformationParser: goRouter.routeInformationParser,
      routerDelegate: goRouter.routerDelegate,
      routeInformationProvider: goRouter.routeInformationProvider,
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const tabRoutes = ['dashboard', 'compare', 'alerts', 'portfolio'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _routeIndex(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: const Color(0xFF00C896),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.compare_arrows), label: 'Compare'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Portfolio'),
        ],
        onTap: (index) {
          final routeName = tabRoutes[index];
          context.goNamed(routeName);
        },
      ),
    );
  }

  int _routeIndex(String location) {
    if (location.startsWith('/compare')) return 1;
    if (location.startsWith('/alerts')) return 2;
    if (location.startsWith('/portfolio')) return 3;
    return 0;
  }
}
