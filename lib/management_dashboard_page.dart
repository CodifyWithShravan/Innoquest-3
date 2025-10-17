// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ManagementDashboardPage extends StatefulWidget {
  const ManagementDashboardPage({super.key});

  @override
  State<ManagementDashboardPage> createState() =>
      _ManagementDashboardPageState();
}

class _ManagementDashboardPageState extends State<ManagementDashboardPage> {
  final _supabase = Supabase.instance.client;
  final FlutterTts _flutterTts = FlutterTts();
  bool _loading = true;
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _yields = [];
  double _totalExpenses = 0.0;
  double _totalIncome = 0.0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchData();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("ml-IN");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speakSummary() async {
    final netProfit = _totalIncome - _totalExpenses;
    String profitStatus = netProfit >= 0 ? 'ലാഭം' : 'നഷ്ടം';
    String summary =
        'നിങ്ങളുടെ ആകെ വരുമാനം ${NumberFormat.simpleCurrency(locale: 'en_IN').format(_totalIncome)}. ആകെ ചെലവ് ${NumberFormat.simpleCurrency(locale: 'en_IN').format(_totalExpenses)}. നിങ്ങളുടെ നിലവിലെ $profitStatus ${NumberFormat.simpleCurrency(locale: 'en_IN').format(netProfit.abs())} ആണ്.';
    await _flutterTts.speak(summary);
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final expensesData =
          await _supabase.from('expenses').select().eq('user_id', userId);
      final yieldsData =
          await _supabase.from('yields').select().eq('user_id', userId);

      if (mounted) {
        setState(() {
          _expenses = List<Map<String, dynamic>>.from(expensesData);
          _yields = List<Map<String, dynamic>>.from(yieldsData);
          _totalExpenses =
              _expenses.fold(0, (sum, item) => sum + (item['amount'] ?? 0));
          _totalIncome =
              _yields.fold(0, (sum, item) => sum + (item['sale_price'] ?? 0));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error fetching data: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- NEW: Add Expense Dialog Logic ---
  void _addExpenseDialog() {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Expense'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount (₹)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                        labelText: 'Category (e.g., Seeds)'),
                    validator: (v) => v!.isEmpty ? 'Required' : null),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _supabase.from('expenses').insert({
                      'user_id': _supabase.auth.currentUser!.id,
                      'description': descriptionController.text,
                      'amount': double.parse(amountController.text),
                      'category': categoryController.text,
                    });
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Expense added successfully!')));
                      _fetchData(); // Refresh the dashboard
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('Failed to add expense: ${e.toString()}'),
                          backgroundColor: Colors.red));
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- NEW: Add Yield Dialog Logic ---
  void _addYieldDialog() {
    final formKey = GlobalKey<FormState>();
    final cropController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Yield Sale'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                    controller: cropController,
                    decoration: const InputDecoration(labelText: 'Crop Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                TextFormField(
                    controller: quantityController,
                    decoration:
                        const InputDecoration(labelText: 'Quantity (kg)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                        labelText: 'Total Sale Price (₹)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _supabase.from('yields').insert({
                      'user_id': _supabase.auth.currentUser!.id,
                      'crop_name': cropController.text,
                      'quantity_kg': double.parse(quantityController.text),
                      'sale_price': double.parse(priceController.text),
                    });
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Yield added successfully!')));
                      _fetchData(); // Refresh the dashboard
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Failed to add yield: ${e.toString()}'),
                          backgroundColor: Colors.red));
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = _totalIncome - _totalExpenses;
    final currencyFormat =
        NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Farm Management')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Profit & Loss Summary',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryColumn(
                                  'Total Income',
                                  currencyFormat.format(_totalIncome),
                                  Colors.green),
                              _buildSummaryColumn(
                                  'Total Expenses',
                                  currencyFormat.format(_totalExpenses),
                                  Colors.red),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(netProfit >= 0 ? 'Net Profit' : 'Net Loss',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                  onPressed: _speakSummary,
                                  icon: const Icon(Icons.volume_up_outlined),
                                  tooltip: 'Read Summary'),
                              Text(
                                currencyFormat.format(netProfit.abs()),
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: netProfit >= 0
                                        ? Colors.green
                                        : Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.arrow_downward), text: 'Expenses'),
                      Tab(icon: Icon(Icons.arrow_upward), text: 'Yields'),
                      Tab(icon: Icon(Icons.add), text: 'Add New'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Expenses List
                        ListView.builder(
                            itemCount: _expenses.length,
                            itemBuilder: (ctx, i) => ListTile(
                                title: Text(_expenses[i]['description']),
                                subtitle: Text(_expenses[i]['category']),
                                trailing: Text(
                                    '- ${currencyFormat.format(_expenses[i]['amount'])}',
                                    style:
                                        const TextStyle(color: Colors.red)))),
                        // Yields List
                        ListView.builder(
                            itemCount: _yields.length,
                            itemBuilder: (ctx, i) => ListTile(
                                title: Text(
                                    '${_yields[i]['quantity_kg']} kg of ${_yields[i]['crop_name']}'),
                                trailing: Text(
                                    '+ ${currencyFormat.format(_yields[i]['sale_price'])}',
                                    style:
                                        const TextStyle(color: Colors.green)))),
                        // Add New Entry Forms
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                  icon: const Icon(Icons.money_off),
                                  label: const Text('Add New Expense'),
                                  onPressed:
                                      _addExpenseDialog), // Connect the function
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                  icon: const Icon(Icons.price_check),
                                  label: const Text('Add New Yield Sale'),
                                  onPressed:
                                      _addYieldDialog), // Connect the function
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryColumn(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}
