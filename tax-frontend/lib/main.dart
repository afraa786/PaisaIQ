import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/alerts_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/coin_detail_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/learn_screen.dart';
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
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/',         name: 'dashboard', builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/learn',    name: 'learn',     builder: (_, __) => const LearnScreen()),
            GoRoute(path: '/alerts',   name: 'alerts',    builder: (_, __) => const AlertsScreen()),
            GoRoute(path: '/portfolio',name: 'portfolio', builder: (_, __) => const PortfolioScreen()),
            GoRoute(path: '/compare',  name: 'compare',   builder: (_, __) => const CompareScreen()),
            GoRoute(path: '/settings', name: 'settings',  builder: (_, __) => const SettingsScreen()),
          ],
        ),
        GoRoute(
          path: '/coin/:coinId',
          name: 'coinDetail',
          builder: (context, state) =>
              CoinDetailScreen(coinId: state.pathParameters['coinId'] ?? ''),
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

  static const _tabs = [
    ('dashboard', '/'),
    ('learn',     '/learn'),
    ('alerts',    '/alerts'),
    ('portfolio', '/portfolio'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => context.goNamed(_tabs[i].$1),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.candlestick_chart_outlined),
                activeIcon: Icon(Icons.candlestick_chart),
                label: 'Markets'),
            BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_outline),
                activeIcon: Icon(Icons.play_circle),
                label: 'Learn'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(Icons.notifications),
                label: 'Alerts'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: 'Portfolio'),
          ],
        ),
      ),
    );
  }

  int _indexFor(String loc) {
    if (loc.startsWith('/learn'))     return 1;
    if (loc.startsWith('/alerts'))    return 2;
    if (loc.startsWith('/portfolio')) return 3;
    return 0;
  }
}
