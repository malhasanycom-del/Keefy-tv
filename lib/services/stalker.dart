import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';
class Stalker {
  final Source s; String? _token; String _api = '';
  Stalker(this.s);
  Map<String,String> get headers => {'Cookie':'mac=${s.mac}; stb_lang=en; timezone=GMT','User-Agent':'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 2 rev: 250 Safari/533.3','X-User-Agent':'Model: MAG250; Link: WiFi',if (_token != null) 'Authorization':'Bearer $_token'};
  Future<dynamic> _call(String q) async { final r = await http.get(Uri.parse('$_api?$q&JsHttpRequest=1-xml'), headers: headers).timeout(const Duration(seconds:20)); return jsonDecode(utf8.decode(r.bodyBytes,allowMalformed:true))['js']; }
  Future<void> connect() async { var b=s.url.trim().replaceAll(RegExp(r'/c/?$'),'').replaceAll(RegExp(r'/+$'),''); final paths=b.contains('.php')?['']:['/portal.php','/stalker_portal/server/load.php','/server/load.php']; for(final p in paths){_api=b+p; try{final j=await _call('type=stb&action=handshake&token='); _token=j['token']; if(_token!=null) break;}catch(_){}} if(_token==null) throw 'فشل الاتصال بالبورتال، تأكد من الرابط والماك'; try{await _call('type=stb&action=get_profile&hd=1');}catch(_){} }
  Future<List<Channel>> channels() async { final g=await _call('type=itv&action=get_genres'); final names={for(final x in (g as List)) '${x['id']}':'${x['title']}'}; final j=await _call('type=itv&action=get_all_channels'); return [for(final c in j['data']) Channel(name:'${c['name']}',logo:'${c['logo']??''}',cmd:'${c['cmd']}',group:names['${c['tv_genre_id']}']??'عام',sourceId:s.id)]; }
  Future<String> link(String cmd) async { final j=await _call('type=itv&action=create_link&cmd=${Uri.encodeComponent(cmd)}'); return '${j['cmd']}'.replaceFirst(RegExp(r'^(ffmpeg|ffrt\d?|auto)\s+'),''); }
}
