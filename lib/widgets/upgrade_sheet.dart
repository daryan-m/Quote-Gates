import 'package:flutter/material.dart';

class UpgradeSheet extends StatelessWidget {
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  const UpgradeSheet({
    super.key,
    required this.onPurchase,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2D1B69)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar ─────────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // ── Icon ───────────────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ──────────────────────────────────────────────────
            const Text(
              "Wisdom Gates Pro",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Unlock All Features",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // ── Features ───────────────────────────────────────────────
            ...[
              ("📖", "Full Quote Library", "1000+ curated quotes"),
              ("🗓️", "Today's History", "Daily tracking & insights"),
              ("🎨", "All Themes & Fonts", "Unlimited styles"),
              ("📏", "Font Size Control", "Customize your reading"),
              ("🚫", "Ad-Free Experience", "Clean & focused"),
            ].map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(f.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            f.$3,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Price ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "\$2.99",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "/ year",
                    style: TextStyle(color: Colors.white60, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Billed annually · Cancel anytime",
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 16),

            // ── Subscribe button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF764BA2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Subscribe Now",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Dismiss button ──────────────────────────────────────────
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "No thanks",
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),

            // ── Restore purchases ───────────────────────────────────────
            TextButton(
              onPressed: onRestore,
              child: const Text(
                "Restore Purchases",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
