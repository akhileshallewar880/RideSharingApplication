import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_models.dart';
import '../services/driver_dashboard_service.dart';

// Driver dashboard service provider
final driverDashboardServiceProvider =
    Provider<DriverDashboardService>((ref) => DriverDashboardService());

// Driver dashboard state
class DriverDashboardState {
  final DashboardData? dashboardData;
  final EarningsData? earningsData;
  final List<PayoutItem> payoutHistory;
  final bool isLoading;
  final String? errorMessage;

  DriverDashboardState({
    this.dashboardData,
    this.earningsData,
    this.payoutHistory = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DriverDashboardState copyWith({
    DashboardData? dashboardData,
    EarningsData? earningsData,
    List<PayoutItem>? payoutHistory,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DriverDashboardState(
      dashboardData: dashboardData ?? this.dashboardData,
      earningsData: earningsData ?? this.earningsData,
      payoutHistory: payoutHistory ?? this.payoutHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Driver dashboard notifier
class DriverDashboardNotifier extends StateNotifier<DriverDashboardState> {
  final DriverDashboardService _service;

  DriverDashboardNotifier(this._service) : super(DriverDashboardState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      print('📡 Loading dashboard data...');
      final response = await _service.getDashboard();
      print('📊 Dashboard response - success: ${response.success}, hasData: ${response.data != null}');
      
      if (response.success && response.data != null) {
        print('✅ Dashboard loaded. isOnline: ${response.data!.driver.isOnline}');
        state = state.copyWith(
          dashboardData: response.data,
          isLoading: false,
        );
      } else {
        print('❌ Dashboard load failed: ${response.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      print('❌ Error loading dashboard: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> updateOnlineStatus(bool isOnline) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final request = UpdateOnlineStatusRequest(isOnline: isOnline);
      print('🔄 Updating online status to: $isOnline');
      final response = await _service.updateOnlineStatus(request);
      print('📡 Status update response: ${response.success}, ${response.message}');
      
      if (response.success) {
        // Reload dashboard to get updated status from server
        print('✅ Status update successful, reloading dashboard...');
        await loadDashboard();
        print('📊 Dashboard reloaded. Current isOnline: ${state.dashboardData?.driver.isOnline}');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      print('❌ Error updating status: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> loadEarnings({
    required String startDate,
    required String endDate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.getEarnings(
        startDate: startDate,
        endDate: endDate,
      );
      if (response.success && response.data != null) {
        state = state.copyWith(
          earningsData: response.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadPayoutHistory({int page = 1, int pageSize = 20}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.getPayoutHistory(
        page: page,
        pageSize: pageSize,
      );
      if (response.success && response.data != null) {
        state = state.copyWith(
          payoutHistory: page == 1
              ? response.data!
              : [...state.payoutHistory, ...response.data!],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> requestPayout({
    required double amount,
    required String method,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final request = RequestPayoutRequest(amount: amount, method: method);
      final response = await _service.requestPayout(request);
      if (response.success) {
        // Reload dashboard and payout history
        await loadDashboard();
        await loadPayoutHistory();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearDashboard() {
    state = DriverDashboardState();
  }
}

// Driver dashboard notifier provider
final driverDashboardNotifierProvider =
    StateNotifierProvider<DriverDashboardNotifier, DriverDashboardState>((ref) {
  final service = ref.watch(driverDashboardServiceProvider);
  return DriverDashboardNotifier(service);
});
