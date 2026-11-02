class Source {
  String id, name, type, url, user, pass, mac;
  Source({required this.id, required this.name, required this.type, required this.url, this.user = '', this.pass = '', this.mac = ''});
  Map toJson() => {'id': id, 'name': name, 'type': type, 'url': url, 'user': user, 'pass': pass, 'mac': mac};
  factory Source.fromJson(Map j) => Source(id: j['id'], name: j['name'], type: j['type'], url: j['url'], user: j['user'] ?? '', pass: j['pass'] ?? '', mac: j['mac'] ?? '');
}
class Channel {
  String name, url, logo, group, sourceId;
  String? cmd;
  Channel({required this.name, this.url = '', this.logo = '', this.group = 'عام', this.cmd, required this.sourceId});
  String get key => '$sourceId|$name';
  Map toJson() => {'name': name, 'url': url, 'logo': logo, 'group': group, 'cmd': cmd, 'sourceId': sourceId};
  factory Channel.fromJson(Map j) => Channel(name: j['name'], url: j['url'] ?? '', logo: j['logo'] ?? '', group: j['group'] ?? 'عام', cmd: j['cmd'], sourceId: j['sourceId']);
}

class MediaItem {
  final String id, name, url, poster, category, sourceId, type;
  final String plot, year, rating, extension;
  MediaItem({required this.id, required this.name, required this.url, required this.poster, required this.category, required this.sourceId, required this.type, this.plot='', this.year='', this.rating='', this.extension=''});
}
