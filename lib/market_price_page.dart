import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketPricePage extends StatefulWidget {
  const MarketPricePage({super.key});

  @override
  State<MarketPricePage> createState() => _MarketPricePageState();
}

class _MarketPricePageState extends State<MarketPricePage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _prices = [];
  bool _loading = true;

  Future<void> _getPrices() async {
    try {
      final data = await _supabase
          .from('market_prices')
          .select()
          .order('crop_name', ascending: true);
      if (mounted) {
        setState(() {
          _prices = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (error) {
      // Handle error
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getPrices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current Market Prices')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _prices.length,
              itemBuilder: (context, index) {
                final item = _prices[index];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.trending_up,
                        color: Theme.of(context).primaryColor),
                    title: Text(item['crop_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['market_location']),
                    trailing: Text(
                      '₹ ${item['price_per_quintal']} / quintal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
