import 'dart:io';
import 'package:excel/excel.dart' as ex;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kebuli_mimi/models/report_model.dart';
import 'package:kebuli_mimi/services/report_service.dart';
import 'package:kebuli_mimi/utils/error_handler.dart';
import 'package:kebuli_mimi/widgets/loading_indicator.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  List<DailyReport> _reports = [];
  bool _isLoading = true;

  // State untuk filter
  late int _selectedYear;
  late int _selectedMonth;
  final List<String> _months = List.generate(
    12,
    (index) => DateFormat('MMMM', 'id_ID').format(DateTime(0, index + 1)),
  );
  final List<int> _years = List.generate(
    5,
    (index) => DateTime.now().year - index,
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final fetchedReports = await _reportService.getDailyReports(
        _selectedYear,
        _selectedMonth,
      );
      final reportsMap = {
        for (var report in fetchedReports) report.day: report,
      };

      // Membuat daftar laporan untuk semua hari dalam sebulan
      final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
      final fullMonthReports = List.generate(daysInMonth, (index) {
        final day = index + 1;
        return reportsMap[day] ??
            DailyReport(day: day, totalSales: 0, totalOrders: 0);
      });

      setState(() => _reports = fullMonthReports);
    } catch (e) {
      if (mounted) {
        if (mounted) ErrorHandler.showSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ekspor Laporan'),
            content: const Text('Pilih format file yang Anda inginkan.'),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _exportToPdf();
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.table_chart),
                label: const Text('Excel'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _exportToExcel();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    final salesDays = _reports.where((r) => r.totalSales > 0).toList();
    final monthName = _months[_selectedMonth - 1];
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Laporan Penjualan - $monthName $_selectedYear',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Tanggal', 'Total Penjualan', 'Total Pesanan'],
                data:
                    salesDays
                        .map(
                          (report) => [
                            report.day.toString(),
                            currencyFormatter.format(report.totalSales),
                            report.totalOrders.toString(),
                          ],
                        )
                        .toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportToExcel() async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Sheet1'];
    final salesDays = _reports.where((r) => r.totalSales > 0).toList();
    final monthName = _months[_selectedMonth - 1];
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    // Header
    sheet.appendRow([
      ex.TextCellValue('Laporan Penjualan - $monthName $_selectedYear'),
    ]);
    sheet.appendRow([]); // Empty row
    sheet.appendRow([
      ex.TextCellValue('Tanggal'),
      ex.TextCellValue('Total Penjualan'),
      ex.TextCellValue('Total Pesanan'),
    ]);

    // Data
    for (var report in salesDays) {
      sheet.appendRow([
        ex.IntCellValue(report.day),
        ex.DoubleCellValue(report.totalSales),
        ex.IntCellValue(report.totalOrders),
      ]);
    }

    // Simpan file
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/Laporan_${monthName}_$_selectedYear.xlsx';
      final file =
          File(path)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);

      // Buka file
      await OpenFile.open(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan Bulanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Ekspor Laporan',
            onPressed: _reports.isEmpty ? null : _showExportDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),
          const Divider(height: 1),
          // Content Section
          Expanded(
            child:
                _isLoading
                    ? const LoadingIndicator()
                    : RefreshIndicator(
                      onRefresh: _loadReports,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Grafik Pendapatan Harian',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(height: 300, child: _buildLineChart()),
                            const SizedBox(height: 32),
                            Text(
                              'Rincian per Hari',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            _buildDataTable(),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedMonth,
              items: List.generate(
                12,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text(_months[index]),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMonth = value);
                  _loadReports();
                }
              },
              decoration: const InputDecoration(
                labelText: 'Bulan',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedYear,
              items:
                  _years
                      .map(
                        (year) => DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedYear = value);
                  _loadReports();
                }
              },
              decoration: const InputDecoration(
                labelText: 'Tahun',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final spots =
        _reports
            .map((report) => FlSpot(report.day.toDouble(), report.totalSales))
            .toList();
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return LineChart(
      LineChartData(
        // PERBAIKAN 1: Tetapkan nilai minimum sumbu Y ke 0.
        // Ini memastikan garis tidak akan pernah digambar di bawah nol.
        minY: 0,

        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5, // Tampilkan label tiap 5 hari
              getTitlesWidget:
                  (value, meta) => SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,

            // PERBAIKAN 2: Properti ini secara khusus mencegah kurva 'kebablasan'.
            // Ini adalah perbaikan utamanya.
            preventCurveOverShooting: true,

            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final report = _reports[spot.spotIndex];
                return LineTooltipItem(
                  'Tgl ${report.day}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    // Tambahkan 'const' di depan TextSpan karena constructornya adalah const.
                    const TextSpan(
                      text: ' ', // Beri spasi agar tidak menempel
                    ),
                    TextSpan(
                      text: currencyFormatter.format(report.totalSales),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    // Tampilkan hanya hari dengan penjualan
    final salesDays = _reports.where((r) => r.totalSales > 0).toList();
    if (salesDays.isEmpty) {
      return const Center(
        heightFactor: 5, // Beri sedikit ruang agar tidak menempel ke atas
        child: Text('Tidak ada penjualan di bulan ini.'),
      );
    }

    // Bungkus DataTable dengan SingleChildScrollView agar bisa di-scroll horizontal
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          Colors.orange.withOpacity(0.1),
        ),
        columns: const [
          DataColumn(
            label: Text(
              'Tanggal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Total Penjualan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Pesanan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
        ],
        rows:
            salesDays.map((report) {
              return DataRow(
                cells: [
                  DataCell(Text(report.day.toString())),
                  DataCell(Text(currencyFormatter.format(report.totalSales))),
                  DataCell(Text(report.totalOrders.toString())),
                ],
              );
            }).toList(),
      ),
    );
  }
}
