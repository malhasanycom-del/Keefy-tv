import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
class Store {
  static late SharedPreferences p;
  static Future<void> init() async => p = await SharedPreferences.getInstance();
  static List<T> _decode<T>(String key, T Function(Map) parse) { try { final raw = jsonDecode(p.getString(key) ?? '[]') as List; return raw.whereType<Map>().map(parse).toList(); } catch (_) { return <T>[]; } }
  static List<Source> sources() => _decode('sources', Source.fromJson);
  static Future<void> saveSources(List<Source> list) => p.setString('sources', jsonEncode(list.map((e) => e.toJson()).toList()));
  static String? get activeId => p.getString('active');
  static Future<void> setActive(String id) => p.setString('active', id);
  static Source? get active { final list = sources(); for (final s in list) { if (s.id == activeId) return s; } return list.isEmpty ? null : list.first; }
  static List<Channel> favs() => _decode('favs', Channel.fromJson);
  static bool isFav(Channel c) => favs().any((f) => f.key == c.key);
  static Future<void> toggleFav(Channel c) async { final l = favs(); if (l.any((f) => f.key == c.key)) { l.removeWhere((f) => f.key == c.key); } else { l.add(c); } await p.setString('favs', jsonEncode(l.map((e) => e.toJson()).toList())); }
  static Future<void> clearFavs() => p.remove('favs');
  static List<Channel> cachedChannels(String id) => _decode('channels_$id', Channel.fromJson);
  static Future<void> saveChannels(String id, List<Channel> l) => p.setString('channels_$id', jsonEncode(l.map((e) => e.toJson()).toList()));
  static Future<void> removeSourceData(String id) async { await p.remove('channels_$id'); final f = favs()..removeWhere((e) => e.sourceId == id); await p.setString('favs', jsonEncode(f.map((e) => e.toJson()).toList())); }
}
