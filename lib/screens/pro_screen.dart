import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/spot_themes.dart';

/// Pro screen: Free-vs-Pro comparison table, one-time Pro unlock,
/// tip jar (coffee/chocolate), and restore purchases.
/// Fully graceful when the store is unconfigured.
class ProScreen extends StatefulWidget {
  final SpotAudio audio;
  final SpotSettings settings;
  const ProScreen({super.key, required this.audio, required this.settings});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  final StoreService _store = StoreService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    await _store.init();
    _store.proPurchased.addListener(_onPro);
    if (_store.proPurchased.value) _applyPro();
    if (mounted) setState(() => _loading = false);
  }

  void _onPro() {
    if (_store.proPurchased.value) _applyPro();
  }

  Future<void> _applyPro() async {
    await widget.settings.setPro(true);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.proPurchased.removeListener(_onPro);
    _store.dispose();
    super.dispose();
  }

  SpotThemeDef _theme() => SpotThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);

  @override
  Widget build(BuildContext context) {
    final theme = _theme();
    final isPro = widget.settings.isPro;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find the Difference PRO'),
        backgroundColor: Colors.transparent,
        foregroundColor: theme.text,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.pageTop, theme.pageBottom],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Free vs Pro table.
            _card(theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('⭐ PRO',
                            style: TextStyle(
                                color: theme.accent,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        const Spacer(),
                        if (isPro)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('ACTIVE ✓',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _row(theme, 'Difficulties', 'Easy + Medium', 'All 3 incl. Hard 🌵', true),
                    _row(theme, 'Differences per scene', 'Up to 6', 'Up to 8 — the sneaky ones', true),
                    _row(theme, 'Themes', '6 cozy themes', 'All 12 + custom creator 🎨', true),
                    _row(theme, 'Frame styles', 'All 8 frames', 'All 8 frames', false),
                    _row(theme, 'Game modes', 'All 5 modes', 'All 5 modes', false),
                    _row(theme, 'Daily puzzle', 'Included', 'Included', false),
                    _row(theme, 'Ads', 'None, ever', 'None, ever', false),
                  ],
                )),
            const SizedBox(height: 14),

            // Buy / restore area.
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (!_store.available || !_store.storeReady)
              _card(theme,
                  child: Column(
                    children: [
                      const Text('🛒', style: TextStyle(fontSize: 34)),
                      const SizedBox(height: 8),
                      Text(
                        _store.error ?? 'Store not ready yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.textDim),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PRO unlocks appear here automatically once the store products are set up in Play Console.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: theme.textDim, fontSize: 12),
                      ),
                    ],
                  ))
            else ...[
              if (!isPro && _store.proProduct != null)
                _buyCard(
                  theme,
                  title: 'Unlock PRO forever',
                  subtitle: 'One-time purchase. Yours on every device.',
                  price: _store.proProduct!.price,
                  onBuy: () {
                    widget.audio.click();
                    _store.buyPro();
                  },
                ),
              if (isPro)
                _card(theme,
                    child: Row(
                      children: [
                        const Text('🎉',
                            style: TextStyle(fontSize: 30)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You are PRO! Hard mode, all 12 themes and the custom theme creator are unlocked.',
                            style: TextStyle(color: theme.text),
                          ),
                        ),
                      ],
                    )),
              const SizedBox(height: 14),
              Text('☕ Tip jar — fuel for more puzzles',
                  style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const SizedBox(height: 8),
              if (_store.coffeeProduct != null)
                _buyCard(
                  theme,
                  title: 'Buy us a coffee',
                  subtitle: 'A small tip to keep the puzzles coming.',
                  price: _store.coffeeProduct!.price,
                  onBuy: () {
                    widget.audio.click();
                    _store.buyTip(_store.coffeeProduct!);
                  },
                ),
              if (_store.chocolateProduct != null)
                _buyCard(
                  theme,
                  title: 'Buy us a chocolate',
                  subtitle: 'The official fuel of eagle-eyed detectives.',
                  price: _store.chocolateProduct!.price,
                  onBuy: () {
                    widget.audio.click();
                    _store.buyTip(_store.chocolateProduct!);
                  },
                ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    widget.audio.click();
                    _store.restore();
                  },
                  child: Text('Restore purchases',
                      style: TextStyle(color: theme.accent)),
                ),
              ),
            ],

            // Purchase feedback.
            ValueListenableBuilder<String?>(
              valueListenable: _store.lastThanks,
              builder: (_, v, _) => v == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(v,
                            style: TextStyle(
                                color: theme.accent,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: _store.purchaseError,
              builder: (_, v, _) => v == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(v,
                            style: const TextStyle(
                                color: Colors.redAccent)),
                      ),
                    ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _store.purchaseInProgress,
              builder: (_, v, _) => v
                  ? const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(
                          child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(SpotThemeDef theme, {required Widget child}) => Container(
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.cardEdge),
        ),
        padding: const EdgeInsets.all(14),
        child: child,
      );

  Widget _row(SpotThemeDef theme, String label, String free, String pro,
      bool diff) {
    Widget cell(String v, bool highlight) => Expanded(
          child: Text(v,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: highlight ? theme.accent : theme.textDim,
                  fontWeight:
                      highlight ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 12)),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          cell(free, false),
          cell(pro, diff),
        ],
      ),
    );
  }

  Widget _buyCard(SpotThemeDef theme,
      {required String title,
      required String subtitle,
      required String price,
      required VoidCallback onBuy}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _card(theme,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: theme.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    Text(subtitle,
                        style: TextStyle(
                            color: theme.textDim, fontSize: 12)),
                    Text(price,
                        style: TextStyle(
                            color: theme.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Buy',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          )),
    );
  }
}
