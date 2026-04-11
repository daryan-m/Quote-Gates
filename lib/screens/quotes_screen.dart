import 'package:flutter/material.dart';
import '../services/quote_loader.dart';
import '../models/quote.dart';
import '../widgets/quote_edit_dialog.dart';

class QuotesScreen extends StatefulWidget {
  final Function(Quote) onQuoteSelected;
  final bool isPremium;
  final VoidCallback? onUpgradePressed;

  const QuotesScreen({
    super.key,
    required this.onQuoteSelected,
    this.isPremium = false,
    this.onUpgradePressed,
  });

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  List<Quote> _quotes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // ── 5 وتەی ئازاد بۆ بەکارهێنەری فری ──
  static const int _freeQuoteLimit = 5;

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
    List<Quote> source = _quotes;
    if (_searchQuery.isNotEmpty) {
      source = source.where((q) {
        return q.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            q.author.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    // بەکارهێنەری فری تەنها 5 وتەی یەکەم دەبینێت
    if (!widget.isPremium) {
      return source.take(_freeQuoteLimit).toList();
    }
    return source;
  }

  void _openEditDialog(Quote quote) {
    showDialog(
      context: context,
      builder: (_) => QuoteEditDialog(
        quote: quote,
        isPremium: widget.isPremium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey))
          : Column(
              children: [
                // ── بانەری ئەپگرەید (تەنها بۆ فری) ──
                if (!widget.isPremium) _buildUpgradeBanner(),
                Expanded(child: _buildQuoteList()),
              ],
            ),
    );
  }

  // ── AppBar ──
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        "Wisdom Quotes",
        style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
      backgroundColor: Colors.blueGrey.shade800,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (!widget.isPremium)
          TextButton.icon(
            onPressed: widget.onUpgradePressed,
            icon: const Icon(Icons.workspace_premium,
                color: Colors.amber, size: 18),
            label: const Text(
              "Upgrade",
              style:
                  TextStyle(color: Colors.amber, fontWeight: FontWeight.w600),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.isPremium
                  ? "Search all quotes..."
                  : "Search (5 free quotes)...",
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              fillColor: Colors.white,
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── بانەری ئەپگرەید ──
  Widget _buildUpgradeBanner() {
    return GestureDetector(
      onTap: widget.onUpgradePressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade700,
              Colors.orange.shade600,
            ],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're viewing 5 free quotes",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "Upgrade to unlock hundreds of wisdom quotes",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Upgrade",
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── لیستی وتەکان ──
  Widget _buildQuoteList() {
    final quotes = _filteredQuotes;

    if (quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "No quotes found",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
      itemCount: quotes.length + (!widget.isPremium ? 1 : 0),
      itemBuilder: (context, index) {
        // ئایتەمی ئەپگرەید لە کۆتایی لیست
        if (!widget.isPremium && index == quotes.length) {
          return _buildLockedItem();
        }

        final quote = quotes[index];
        return _buildQuoteCard(quote, index);
      },
    );
  }

  // ── کارتی وتە ──
  Widget _buildQuoteCard(Quote quote, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEditDialog(quote),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ژمارەی وتە
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.text,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF2C2C2C),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 1.5,
                          color: Colors.blueGrey.shade200,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            quote.author,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // دوگمەکانی کردار
              Column(
                children: [
                  _actionIcon(
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    tooltip: "Select for home",
                    onTap: () {
                      widget.onQuoteSelected(quote);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Quote selected!"),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.blueGrey.shade800,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  _actionIcon(
                    icon: Icons.tune_rounded,
                    color: Colors.blueGrey,
                    tooltip: "Customize & Share",
                    onTap: () => _openEditDialog(quote),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  // ── ئایتەمی قفڵکراو بۆ بەکارهێنەری فری ──
  Widget _buildLockedItem() {
    return GestureDetector(
      onTap: widget.onUpgradePressed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.amber.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Unlock All Quotes",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  Text(
                    "Upgrade to access hundreds of wisdom quotes",
                    style:
                        TextStyle(fontSize: 12, color: Colors.amber.shade700),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.amber.shade700),
          ],
        ),
      ),
    );
  }
}
