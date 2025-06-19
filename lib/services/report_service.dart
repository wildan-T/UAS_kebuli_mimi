import 'package:kebuli_mimi/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MonthlyReport>> getMonthlyReports(int year) async {
    final response = await _client.rpc(
      'get_monthly_reports',
      params: {'year': year},
    );
    return (response as List)
        .map((json) => MonthlyReport.fromJson(json))
        .toList();
  }

  Future<List<DailyReport>> getDailyReports(int year, int month) async {
    final response = await _client.rpc(
      'get_daily_reports_for_month',
      params: {'target_year': year, 'target_month': month},
    );
    return (response as List)
        .map((json) => DailyReport.fromJson(json))
        .toList();
  }
}
