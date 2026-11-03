import 'package:flutter/material.dart';
import '../services/store.dart';
import 'add_source.dart';
import 'channels.dart';
import 'favorites.dart';
import 'settings.dart';
import 'media_catalog.dart';
import 'sources.dart';

const _bg = Color(0xFF0E1218);
const _surface = Color(0xFF171D26);
const _accent = Color(0xFFF2A33A);
const _muted = Color(0xFF8B96A8);

Route<T> _fade<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (_, animation, __) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    child: page,
  ),
);

class _KeefyBrand extends StatelessWidget {
  final double size;
  const _KeefyBrand({this.size = 32});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .28),
        gradient: const LinearGradient(
          colors: [_accent, Color(0xFFFFD18A)],
          begin: Alignment.topRight, end: Alignment.bottomLeft,
        ),
        boxShadow: [BoxShadow(color: _accent.withOpacity(.24), blurRadius: 16)],
      ),
      child: Icon(Icons.play_arrow_rounded, color: Colors.black, size: size * .82),
    ),
    const SizedBox(width: 10),
    Text('KEEFY', style: TextStyle(
      fontSize: size * .65, letterSpacing: 2.1,
      fontWeight: FontWeight.w900, color: Colors.white,
    )),
    Text(' TV', style: TextStyle(
      fontSize: size * .65, letterSpacing: 1.2,
      fontWeight: FontWeight.w900, color: _accent,
    )),
  ]);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final source = Store.active;
    final items = <(String, String, IconData, Widget, Color)>[
      ('البث المباشر', 'قنواتك المفضلة لحظة بلحظة', Icons.live_tv_rounded, const ChannelsScreen(), const Color(0xFFF2A33A)),
      ('الأفلام', 'مكتبة الأفلام والتصنيفات', Icons.movie_creation_rounded, const MediaCatalogScreen(type: 'movie'), const Color(0xFF5B9DFF)),
      ('المسلسلات', 'المواسم والحلقات بالتفصيل', Icons.video_library_rounded, const MediaCatalogScreen(type: 'series'), const Color(0xFFB18AFF)),
      ('المفضلة', 'كل ما حفظته في مكان واحد', Icons.favorite_rounded, const FavoritesScreen(), const Color(0xFFFF718B)),
      ('مصادر التشغيل', 'إدارة M3U وXtream وStalker', Icons.dns_rounded, const SourcesScreen(), const Color(0xFF55C7B2)),
      ('إضافة قائمة', 'أضف رابطاً أو بوابة جديدة', Icons.add_link_rounded, const AddSourceScreen(), const Color(0xFFFFB45E)),
      ('الإعدادات', 'تفضيلات وتجربة المشاهدة', Icons.tune_rounded, const SettingsScreen(), const Color(0xFF9AA8BC)),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final columns = constraints.maxWidth >= 1100 ? 4 : (wide ? 3 : 2);
          return Stack(children: [
            Positioned(top: -140, right: -100, child: _orb(300, _accent.withOpacity(.09))),
            Positioned(bottom: -160, left: -100, child: _orb(340, const Color(0xFF355B9A).withOpacity(.12))),
            CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(wide ? 32 : 18, 18, wide ? 32 : 18, 10),
                  child: Row(children: [
                    const _KeefyBrand(size: 38),
                    const Spacer(),
                    IconButton(
                      tooltip: 'الإعدادات',
                      onPressed: () => Navigator.push(context, _fade(const SettingsScreen())),
                      icon: const Icon(Icons.settings_outlined, color: _muted),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 18, vertical: 12),
                  child: Container(
                    padding: EdgeInsets.all(wide ? 28 : 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34302A), Color(0xFF1A202A), Color(0xFF171D26)],
                        begin: Alignment.topRight, end: Alignment.bottomLeft,
                      ),
                      border: Border.all(color: Colors.white.withOpacity(.08)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.22), blurRadius: 24, offset: const Offset(0, 12))],
                    ),
                    child: Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('تجربتك الترفيهية تبدأ هنا', style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 9),
                          Text('كل ما تحب\nفي مكان واحد', style: TextStyle(fontSize: wide ? 30 : 25, height: 1.15, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 14),
                          Row(children: [
                            const Icon(Icons.circle, size: 8, color: Color(0xFF61D6A5)),
                            const SizedBox(width: 8),
                            Flexible(child: Text(source?.name ?? 'لم تتم إضافة مصدر بعد', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                          ]),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                            onPressed: () => Navigator.push(context, _fade(source == null ? const AddSourceScreen() : const ChannelsScreen())),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(source == null ? 'إضافة أول مصدر' : 'ابدأ المشاهدة'),
                          ),
                        ],
                      )),
                      if (wide) const SizedBox(width: 24),
                      if (wide) Container(
                        width: 150, height: 150,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withOpacity(.08), border: Border.all(color: _accent.withOpacity(.18), width: 1.5)),
                        child: const Icon(Icons.connected_tv_rounded, size: 78, color: _accent),
                      ),
                    ]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(wide ? 32 : 18, 18, wide ? 32 : 18, 14),
                  child: Row(children: [
                    const Text('اكتشف Keefy', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${items.length} أقسام', style: const TextStyle(color: _muted, fontSize: 12)),
                  ]),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(wide ? 32 : 18, 0, wide ? 32 : 18, 30),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12, crossAxisSpacing: 12,
                    childAspectRatio: wide ? 1.55 : 1.12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];
                    return _HomeTile(
                      title: item.$1, subtitle: item.$2, icon: item.$3,
                      tint: item.$5,
                      onTap: () => Navigator.push(context, _fade(item.$4)),
                    );
                  }, childCount: items.length),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Center(child: Text('KEEFY TV  •  استمتع بالمشاهدة', style: TextStyle(color: Colors.white.withOpacity(.28), fontSize: 11, letterSpacing: 1))),
                ),
              ),
            ]),
          ]);
        }),
      ),
    );
  }

  Widget _orb(double size, Color color) => IgnorePointer(child: Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)]),
  ));
}

class _HomeTile extends StatefulWidget {
  final String title, subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  const _HomeTile({required this.title, required this.subtitle, required this.icon, required this.tint, required this.onTap});
  @override State<_HomeTile> createState() => _HomeTileState();
}
class _HomeTileState extends State<_HomeTile> {
  bool focused = false;
  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: focused ? 1.025 : 1,
    duration: const Duration(milliseconds: 150),
    child: Card(
      color: const Color(0xFF171D26),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: focused ? widget.tint : Colors.white.withOpacity(.055), width: focused ? 1.8 : 1),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (value) => setState(() => focused = value),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: widget.tint.withOpacity(.14), borderRadius: BorderRadius.circular(14)),
              child: Icon(widget.icon, color: widget.tint, size: 25),
            ),
            const Spacer(),
            Text(widget.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11, height: 1.3)),
          ]),
        ),
      ),
    ),
  );
}
