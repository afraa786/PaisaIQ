// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alpharedge_flutter/data/models/coin_model.dart';
import 'package:alpharedge_flutter/data/models/market_global_model.dart';
import 'package:alpharedge_flutter/data/models/trending_model.dart';
import 'package:alpharedge_flutter/data/providers/coin_providers.dart';
import 'package:alpharedge_flutter/data/providers/market_providers.dart';
import 'package:alpharedge_flutter/main.dart';

void main() {
  testWidgets('AlphaEdge app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketGlobalProvider.overrideWith(
            (_) async => MarketGlobalModel(
              totalMarketCapUsd: 0,
              volume24hUsd: 0,
              btcDominance: 0,
            ),
          ),
          trendingCoinsProvider.overrideWith(
            (_) async => const <TrendingModel>[],
          ),
          trackedCoinsProvider.overrideWith(
            (_) async => const <CoinModel>[],
          ),
        ],
        child: const AlphaEdgeApp(),
      ),
    );

    expect(find.text('AlphaEdge'), findsOneWidget);
  });
}
