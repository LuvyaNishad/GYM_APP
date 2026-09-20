import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder analytics provider.
/// TODO: implement progress history and chart data state.
class AnalyticsNotifier extends Notifier<List<dynamic>> {
  @override
  List<dynamic> build() => const [];
}

final analyticsProvider =
    NotifierProvider<AnalyticsNotifier, List<dynamic>>(AnalyticsNotifier.new);
