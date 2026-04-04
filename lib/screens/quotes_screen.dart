import 'package:flutter/material.dart';
import '../services/quote_loader.dart';
import '../models/quote.dart';
import '../widgets/quote_widget.dart';

class QuotesScreen extends StatefulWidget {
  final Function(Quote) onQuoteSelected;
  const QuotesScreen({super.key, required this.onQuoteSelected});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  List<Quote> _quotes = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    final quotes = await QuoteLoader.loadAllQuotes();
    setState(() {
      _quotes = quotes;
      _isLoading = false;
    });
  }

  List<Quote> get _filteredQuotes {
    if (_searchQuery.isEmpty) return _quotes;
    return _quotes.where((quote) {
      return quote.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          quote.author.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Wisdom Quotes"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search quotes or authors...",
                prefixIcon: Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredQuotes.isEmpty
              ? const Center(child: Text("No quotes found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredQuotes.length,
                  itemBuilder: (context, index) {
                    final quote = _filteredQuotes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          quote.text,
                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text("— ${quote.author}", style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                              onPressed: () {
                                widget.onQuoteSelected(quote);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Quote selected for home screen")),
                                );
                              },
                              tooltip: "Select this quote",
                            ),
                            IconButton(
                              icon: const Icon(Icons.format_quote, color: Colors.blueGrey),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    contentPadding: const EdgeInsets.all(8),
                                    content: QuoteWidget(
                                      quote: quote.text,
                                      author: quote.author,
                                      backgroundColor: Colors.white,
                                      fontFamily: "System",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Close"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadQuotes,
        tooltip: "Refresh Quotes",
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}