import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../services/analytics_service.dart';
import 'admin_auth_provider.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final authService = ref.watch(adminAuthServiceProvider);
  return AnalyticsService(authService);
});

final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, DashboardStatsState>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return DashboardStatsNotifier(analyticsService);
});

class DashboardStatsState {
  final DashboardStats? stats;
  final bool isLoading;
  final String? error;

  DashboardStatsState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  DashboardStatsState copyWith({
    DashboardStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return DashboardStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardStatsNotifier extends StateNotifier<DashboardStatsState> {
  final AnalyticsService _analyticsService;

  DashboardStatsNotifier(this._analyticsService)
      : super(DashboardStatsState());

  Future<void> loadStats({DateTime? startDate, DateTime? endDate}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final stats = await _analyticsService.getDashboardStats(
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
