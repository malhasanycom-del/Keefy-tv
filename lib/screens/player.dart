import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models.dart';
import '../services/stalker.dart';
import '../services/store.dart';

const _playerAccent = Color(0xFFF2A33A);

class PlayerScreen extends StatefulWidget {
  final Channel ch;
  const PlayerScreen({super.key, required this.ch});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? controller;
  String? error;
  bool busy = true;
  bool controls = true;
  bool fullscreen = false;
  bool favorite = false;
  Timer? hideTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    favorite = Store.isFav(widget.ch);
    _start();
  }

  Future<void> _start() async {
    if (!mounted) return;
    setState(() { busy = true; error = null; });
    VideoPlayerController? next;
    try {
      var url = widget.ch.url;
      Map<String, String> headers = {};
      if (widget.ch.cmd != null) {
        final source = Store.sources().firstWhere((s) => s.id == widget.ch.sourceId);
        final stalker = Stalker(source);
        await stalker.connect();
        url = await stalker.link(widget.ch.cmd!);
        headers = stalker.headers;
      }
      next = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: headers,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
      await next.initialize().timeout(const Duration(seconds: 50));
      await next.play();
      if (!mounted || _disposed) {
        await next.dispose();
        return;
      }
      next.addListener(_videoChanged);
      final old = controller;
      setState(() { controller = next; busy = false; });
      await old?.dispose();
      _showControlsTemporarily();
      await WakelockPlus.enable();
    } catch (e) {
      await next?.dispose();
      if (mounted) {
        setState(() {
          error = 'تعذر تشغيل المحتوى. تحقق من الرابط أو صلاحية الاشتراك.\n' + e.toString();
          busy = false;
        });
      }
    }
  }

  void _videoChanged() {
    if (mounted) setState(() {});
  }

  void _showControlsTemporarily() {
    if (!mounted) return;
    setState(() => controls = true);
    hideTimer?.cancel();
    hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && (controller?.value.isPlaying ?? false)) {
        setState(() => controls = false);
      }
    });
  }

  Future<void> _togglePlayback() async {
    final c = controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
      hideTimer?.cancel();
      if (mounted) setState(() => controls = true);
    } else {
      await c.play();
      _showControlsTemporarily();
    }
  }

  Future<void> _toggleFullscreen() async {
    final next = !fullscreen;
    setState(() { fullscreen = next; controls = true; });
    hideTimer?.cancel();
    if (next) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await WakelockPlus.enable();
    } else {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await WakelockPlus.disable();
    }
    _showControlsTemporarily();
  }

  Future<void> _toggleFavorite() async {
    await Store.toggleFav(widget.ch);
    if (mounted) setState(() => favorite = Store.isFav(widget.ch));
  }

  Future<void> _seek(int seconds) async {
    final c = controller;
    if (c == null || !c.value.isInitialized) return;
    final target = c.value.position + Duration(seconds: seconds);
    final max = c.value.duration;
    await c.seekTo(target < Duration.zero ? Duration.zero : (target > max ? max : target));
    _showControlsTemporarily();
  }

  String _time(Duration value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = value.inHours;
    final mm = two(value.inMinutes.remainder(60));
    final ss = two(value.inSeconds.remainder(60));
    return h > 0 ? h.toString() + ':' + mm + ':' + ss : two(value.inMinutes) + ':' + ss;
  }

  @override
  void dispose() {
    _disposed = true;
    hideTimer?.cancel();
    controller?.removeListener(_videoChanged);
    controller?.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final initialized = c?.value.isInitialized ?? false;
    final playing = c?.value.isPlaying ?? false;
    final buffering = c?.value.isBuffering ?? false;
    final duration = initialized ? c!.value.duration : Duration.zero;
    final position = initialized ? c!.value.position : Duration.zero;

    return PopScope(
      canPop: !fullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && fullscreen) _toggleFullscreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: fullscreen ? null : AppBar(
          backgroundColor: Colors.black,
          title: Text(widget.ch.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: favorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
              onPressed: _toggleFavorite,
              icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: favorite ? Colors.redAccent : Colors.white),
            ),
            IconButton(
              tooltip: 'ملء الشاشة',
              onPressed: _toggleFullscreen,
              icon: const Icon(Icons.fullscreen),
            ),
          ],
        ),
        body: Focus(
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.mediaPlayPause) {
              _togglePlayback();
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.arrowRight) {
              _seek(-10);
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.arrowLeft) {
              _seek(10);
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
              if (fullscreen) _toggleFullscreen();
              return KeyEventResult.handled;
            }
            _showControlsTemporarily();
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!controls) {
                _showControlsTemporarily();
              } else {
                _togglePlayback();
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (initialized)
                  Center(
                    child: AspectRatio(
                      aspectRatio: c!.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
                      child: VideoPlayer(c),
                    ),
                  )
                else if (busy)
                  const Center(child: CircularProgressIndicator(color: _playerAccent))
                else if (error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 14),
                          Text(error!, textAlign: TextAlign.center),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _start,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (buffering)
                  const Center(child: CircularProgressIndicator(color: _playerAccent)),
                if (initialized && !playing && !buffering)
                  Center(
                    child: Icon(Icons.pause_circle_filled, size: 66, color: Colors.white.withOpacity(.65)),
                  ),
                if (initialized)
                  AnimatedOpacity(
                    opacity: controls ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: IgnorePointer(
                      ignoring: !controls,
                      child: Stack(
                        children: [
                          const Positioned(
                            top: 0, left: 0, right: 0, height: 110,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: fullscreen ? 20 : 12,
                            left: 18,
                            right: 18,
                            child: Row(children: [
                              if (fullscreen)
                                IconButton(
                                  onPressed: _toggleFullscreen,
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                ),
                              if (widget.ch.cmd != null) ...[
                                const Icon(Icons.circle, size: 9, color: Colors.redAccent),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(widget.ch.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                              ),
                              IconButton(
                                onPressed: _toggleFavorite,
                                icon: Icon(favorite ? Icons.favorite : Icons.favorite_border,
                                  color: favorite ? Colors.redAccent : Colors.white),
                              ),
                              IconButton(
                                onPressed: _toggleFullscreen,
                                icon: Icon(fullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
                              ),
                            ]),
                          ),
                          Positioned(
                            left: 0, right: 0, bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Row(children: [
                                  Text(_time(position), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                  const Spacer(),
                                  Text(widget.ch.group, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                                  const Spacer(),
                                  Text(_time(duration), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                ]),
                                if (duration > Duration.zero)
                                  VideoProgressIndicator(
                                    c!,
                                    allowScrubbing: true,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    colors: const VideoProgressColors(
                                      playedColor: _playerAccent,
                                      bufferedColor: Colors.white38,
                                      backgroundColor: Colors.white24,
                                    ),
                                  ),
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  IconButton(
                                    onPressed: widget.ch.url.contains('/live/') || widget.ch.cmd != null ? null : () => _seek(-10),
                                    icon: const Icon(Icons.replay_10, size: 30),
                                  ),
                                  const SizedBox(width: 22),
                                  IconButton.filled(
                                    style: IconButton.styleFrom(backgroundColor: _playerAccent, foregroundColor: Colors.black),
                                    onPressed: _togglePlayback,
                                    icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 34),
                                  ),
                                  const SizedBox(width: 22),
                                  IconButton(
                                    onPressed: widget.ch.url.contains('/live/') || widget.ch.cmd != null ? null : () => _seek(10),
                                    icon: const Icon(Icons.forward_10, size: 30),
                                  ),
                                ]),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
