import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/db_helper.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _onlineTransactions = [];
  List<Map<String, dynamic>> _offlineTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    // Fallback/Mock for Online Transactions until GET /api/transactions endpoint is confirmed
    // But we will try to fetch pending ones from SQLite first
    try {
      final pending = await DatabaseHelper().getPendingTransactions();
      _offlineTransactions = pending;

      // Try fetch from network if possible (assuming GET /api/transactions returns a list)
      // Since it's not fully defined by user, comment out or try catching
      final response = await _apiService.getTransactions();
      if (response.isNotEmpty) {
        if (response.first.containsKey('error')) {
          print('Transactions API Error: ${response.first['error']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error API: ${response.first['error']}')),
            );
          }
        } else {
          _onlineTransactions = response;
        }
      }
    } catch (e) {
      print('Failed fetching transactions: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasTransactions =
        _onlineTransactions.isNotEmpty || _offlineTransactions.isNotEmpty;
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: !hasTransactions
          ? const Center(
              child: Text(
                'Belum ada transaksi',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_offlineTransactions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Transaksi Offline (Tertunda)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  ..._offlineTransactions.map((tx) {
                    final amountPaid = tx['amount_paid'] ?? 0;
                    final paymentMethod = tx['payment_method'] ?? '-';
                    // since our helper flattens it, date might not be saved or we'll fallback to current time string
                    final date = tx['timestamp'] ?? '-';

                    return Card(
                      color: Colors.orange.withOpacity(0.1),
                      child: ListTile(
                        leading: const Icon(
                          Icons.cloud_off,
                          color: Colors.orange,
                        ),
                        title: Text('Pembayaran: $paymentMethod'),
                        subtitle: Text('Waktu: $date'),
                        trailing: Text(
                          currencyFormat.format(amountPaid),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const Divider(height: 32),
                ],
                if (_onlineTransactions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Transaksi Selesai (Server)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._onlineTransactions.map((tx) {
                    final invoice = tx['invoice'] ?? 'N/A';
                    final total =
                        double.tryParse(tx['total']?.toString() ?? '') ?? 0;
                    final date = tx['tgl_penjualan'] ?? '';

                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: Text('Invoice: $invoice'),
                        subtitle: Text('Tgl: $date'),
                        trailing: Text(
                          currencyFormat.format(total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }),
                ] else if (_offlineTransactions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Data transaksi server kosong / belum dapat dimuat.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
