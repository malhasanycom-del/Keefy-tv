import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';

String _attr(String line, String key) =>
    RegExp('(?:^|\\s)$key="([^"]*)"', caseSensitive: false)
        .firstMatch(line)?.group(1) ?? '';

String _kind(String name, String group, String url) {
  final s = '${name.toLowerCase()} ${group.toLowerCase()} ${url.toLowerCase()}';
  const seriesWords = ['series','season','episode','tv show','مسلسل','مسلسلات','حلقة','حلقات','موسم','انمي','أنمي'];
  const movieWords = ['movie','movies','film','films','vod','افلام','أفلام','فيلم','سينما'];
  if (seriesWords.any(s.contains) || RegExp(r's\\d{1,2}e\\d{1,2}|\\b\\d{1,2}x\\d{1,2}\\b', caseSensitive:false).hasMatch(s)) return 'series';
  if (movieWords.any(s.contains) || RegExp(r'\\.(mp4|mkv|avi|mov)(?:$|\\?)',caseSensitive:false).hasMatch(url)) return 'movie';
  return 'live';
}

Future<List<MediaItem>> loadMedia(Source source, String type) async {
  if (source.type == 'stalker') {
    throw Exception('قوائم الأفلام والمسلسلات عبر Stalker غير مفعّلة في هذه النسخة؛ القنوات المباشرة تعمل بصورة مستقلة.');
  }
  if (source.type == 'm3u') {
    final response = await http.get(Uri.parse(source.url), headers: {'Accept':'*/*','User-Agent':'KeefyTV/1.1'}).timeout(const Duration(seconds:60));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('فشل تحميل القائمة: HTTP ${response.statusCode}');
    final lines = const LineSplitter().convert(utf8.decode(response.bodyBytes, allowMalformed:true).replaceFirst('\\uFEFF',''));
    final result = <MediaItem>[];
    String? name; String poster=''; String category='عام'; String id='';
    for (final raw in lines) {
      final line = raw.trim();
      if (line.startsWith('#EXTINF')) {
        final comma = line.indexOf(',');
        name = comma >= 0 ? line.substring(comma+1).trim() : (_attr(line,'tvg-name').isNotEmpty ? _attr(line,'tvg-name') : 'بدون اسم');
        poster = _attr(line,'tvg-logo');
        category = _attr(line,'group-title').trim();
        id = _attr(line,'tvg-id');
      } else if (line.isNotEmpty && !line.startsWith('#') && name != null) {
        final kind = _kind(name!, category, line);
        if (kind == type) result.add(MediaItem(id:id.isEmpty?line:id,name:name!,url:line,poster:poster,category:category.isEmpty?'غير مصنف':category,sourceId:source.id,type:type));
        name=null; poster=''; category='عام'; id='';
      }
    }
    return result;
  }
  final base = source.url.replaceAll(RegExp(r'/+$'),'');
  Future<dynamic> api(String action) async {
    final uri=Uri.parse('$base/player_api.php').replace(queryParameters:{'username':source.user,'password':source.pass,'action':action});
    final r=await http.get(uri).timeout(const Duration(seconds:50));
    if(r.statusCode!=200) throw Exception('Xtream HTTP ${r.statusCode}');
    return jsonDecode(utf8.decode(r.bodyBytes,allowMalformed:true));
  }
  if(type=='movie') {
    final rawCats=await api('get_vod_categories');
    final raw=await api('get_vod_streams');
    final cats=<String,String>{};
    if(rawCats is List) for(final c in rawCats) { cats['${c['category_id']}']='${c['category_name']??'غير مصنف'}'; }
    if(raw is! List) throw Exception('تعذر قراءة مكتبة الأفلام');
    return [for(final x in raw) MediaItem(id:'${x['stream_id']}',name:'${x['name']??'بدون عنوان'}',url:'$base/movie/${Uri.encodeComponent(source.user)}/${Uri.encodeComponent(source.pass)}/${x['stream_id']}.${x['container_extension']??'mp4'}',poster:'${x['stream_icon']??''}',category:cats['${x['category_id']}']??'غير مصنف',sourceId:source.id,type:'movie',plot:'${x['plot']??''}',year:'${x['year']??''}',rating:'${x['rating']??''}',extension:'${x['container_extension']??'mp4'}')];
  }
  final rawCats=await api('get_series_categories');
  final raw=await api('get_series');
  final cats=<String,String>{};
  if(rawCats is List) for(final c in rawCats) { cats['${c['category_id']}']='${c['category_name']??'غير مصنف'}'; }
  if(raw is! List) throw Exception('تعذر قراءة مكتبة المسلسلات');
  return [for(final x in raw) MediaItem(id:'${x['series_id']}',name:'${x['name']??'بدون عنوان'}',url:'',poster:'${x['cover']??''}',category:cats['${x['category_id']}']??'غير مصنف',sourceId:source.id,type:'series',plot:'${x['plot']??''}',year:'${x['releaseDate']??''}',rating:'${x['rating']??''}')];
}

/// يحافظ على رقم الموسم القادم من بنية Xtream نفسها؛ عدم حفظ المفتاح كان
/// يجعل كل الحلقات تظهر خطأً تحت الموسم الأول.
Future<List<Map<String,dynamic>>> loadSeriesEpisodes(Source source, String seriesId) async {
  final base = source.url.replaceAll(RegExp(r'/+$'),'');
  final uri=Uri.parse('$base/player_api.php').replace(queryParameters:{
    'username':source.user,'password':source.pass,
    'action':'get_series_info','series_id':seriesId,
  });
  final r=await http.get(uri).timeout(const Duration(seconds:45));
  if(r.statusCode!=200) throw Exception('Xtream HTTP ${r.statusCode}');
  final data=jsonDecode(utf8.decode(r.bodyBytes,allowMalformed:true));
  final episodes=data is Map ? data['episodes'] : null;
  final out=<Map<String,dynamic>>[];
  if(episodes is Map) {
    episodes.forEach((seasonKey, seasonEpisodes) {
      if(seasonEpisodes is! List) return;
      for(final raw in seasonEpisodes) {
        if(raw is Map) {
          final ep=Map<String,dynamic>.from(raw);
          ep['season_number'] ??= seasonKey.toString();
          out.add(ep);
        }
      }
    });
  } else if(episodes is List) {
    for(var seasonIndex=0; seasonIndex<episodes.length; seasonIndex++) {
      final seasonEpisodes=episodes[seasonIndex];
      if(seasonEpisodes is! List) continue;
      for(final raw in seasonEpisodes) {
        if(raw is Map) {
          final ep=Map<String,dynamic>.from(raw);
          ep['season_number'] ??= (seasonIndex+1).toString();
          out.add(ep);
        }
      }
    }
  }
  return out;
}
