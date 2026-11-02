import 'package:flutter/material.dart';
import '../models.dart';
import '../services/media_loader.dart';
import '../services/store.dart';
import 'player.dart';

class MediaCatalogScreen extends StatefulWidget {
  final String type;
  const MediaCatalogScreen({super.key, required this.type});
  @override State<MediaCatalogScreen> createState()=>_MediaCatalogState();
}

class _MediaCatalogState extends State<MediaCatalogScreen> {
  List<MediaItem> items=[];
  bool loading=true;
  String? error;
  String query='';
  String category='الكل';
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    final source=Store.active;
    if(source==null){setState((){loading=false;error='أضف مصدراً أولاً';});return;}
    setState((){loading=true;error=null;});
    try { final data=await loadMedia(source,widget.type); if(mounted)setState((){items=data;loading=false;}); }
    catch(e){if(mounted)setState((){error=e.toString().replaceFirst('Exception: ','');loading=false;});}
  }
  @override Widget build(BuildContext context) {
    final isMovie=widget.type=='movie';
    final title=isMovie?'الأفلام':'المسلسلات';
    final categories=['الكل',...items.map((e)=>e.category).where((e)=>e.isNotEmpty).toSet().toList()..sort()];
    final filtered=items.where((e)=>(category=='الكل'||e.category==category)&&e.name.toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar:AppBar(title:Text(title),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh_rounded),tooltip:'تحديث المكتبة')]),
      body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.video_library_outlined,size:54,color:Colors.white38),const SizedBox(height:14),Text(error!,textAlign:TextAlign.center),const SizedBox(height:16),FilledButton.icon(onPressed:_load,icon:const Icon(Icons.refresh),label:const Text('إعادة المحاولة'))]))):items.isEmpty?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(isMovie?Icons.movie_outlined:Icons.live_tv_outlined,size:60,color:Colors.white38),const SizedBox(height:12),Text('لا توجد ${isMovie?'أفلام':'مسلسلات'} في المصدر الحالي'),const SizedBox(height:6),const Text('تحقق من تصنيف القائمة أو بيانات اشتراك Xtream',style:TextStyle(color:Colors.white54))])):Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(16,12,16,8),child:TextField(onChanged:(v)=>setState(()=>query=v),decoration:InputDecoration(hintText:'ابحث في $title',prefixIcon:const Icon(Icons.search),filled:true,fillColor:Colors.white.withOpacity(.05),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none)))),
        SizedBox(height:46,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),children:[for(final c in categories)Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(label:Text(c),selected:category==c,onSelected:(_)=>setState(()=>category=c)))])),
        Padding(padding:const EdgeInsets.fromLTRB(16,4,16,8),child:Row(children:[Text('${filtered.length} عنوان',style:const TextStyle(color:Colors.white60)),const Spacer(),Text(category,style:const TextStyle(color:Colors.white38))])),
        Expanded(child:GridView.builder(padding:const EdgeInsets.fromLTRB(14,4,14,20),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.61,crossAxisSpacing:12,mainAxisSpacing:14),itemCount:filtered.length,itemBuilder:(context,index){final item=filtered[index];return InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>_open(item),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(14),child:Stack(fit:StackFit.expand,children:[Container(color:const Color(0xFF20243B),child:item.poster.isEmpty?Icon(isMovie?Icons.movie:Icons.tv,size:44,color:Colors.white30):Image.network(item.poster,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Center(child:Icon(Icons.broken_image_outlined,size:38,color:Colors.white30)))),Positioned(top:8,right:8,child:Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:Colors.black.withOpacity(.7),borderRadius:BorderRadius.circular(8)),child:Text(item.category,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10))))]))),
          const SizedBox(height:8),Text(item.name,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700)),if(item.year.isNotEmpty)Padding(padding:const EdgeInsets.only(top:3),child:Text(item.year,style:const TextStyle(color:Colors.white54,fontSize:11)))
        ]));})),
      ]),
    );
  }
  Future<void> _open(MediaItem item) async {
    if(item.type=='movie'){await Navigator.push(context,MaterialPageRoute(builder:(_)=>PlayerScreen(ch:Channel(name:item.name,url:item.url,logo:item.poster,group:item.category,sourceId:item.sourceId))));return;}
    if(item.url.isNotEmpty){await Navigator.push(context,MaterialPageRoute(builder:(_)=>PlayerScreen(ch:Channel(name:item.name,url:item.url,logo:item.poster,group:item.category,sourceId:item.sourceId))));return;}
    final source=Store.sources().firstWhere((s)=>s.id==item.sourceId);
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>SeriesEpisodesScreen(source:source,item:item)));
  }
}

class SeriesEpisodesScreen extends StatefulWidget {
  final Source source;
  final MediaItem item;
  const SeriesEpisodesScreen({super.key, required this.source, required this.item});
  @override State<SeriesEpisodesScreen> createState() => _SeriesEpisodesState();
}

class _SeriesEpisodesState extends State<SeriesEpisodesScreen> with SingleTickerProviderStateMixin {
  List<Map<String,dynamic>> episodes = [];
  Map<String,List<Map<String,dynamic>>> seasons = {};
  bool loading = true;
  String? error;
  TabController? tabs;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await loadSeriesEpisodes(widget.source, widget.item.id);
      final grouped = <String,List<Map<String,dynamic>>>{};
      for (var i=0; i<data.length; i++) {
        final ep = data[i];
        final season = (ep['season'] ?? ep['season_number'] ?? 1).toString();
        grouped.putIfAbsent(season, () => []).add(ep);
      }
      final keys = grouped.keys.toList()..sort((a,b) {
        final ai=int.tryParse(a) ?? 0, bi=int.tryParse(b) ?? 0;
        return ai.compareTo(bi);
      });
      if (!mounted) return;
      tabs?.dispose();
      setState(() {
        episodes = data;
        seasons = {for(final key in keys) key: grouped[key]!};
        tabs = TabController(length: keys.isEmpty ? 1 : keys.length, vsync: this);
        loading = false;
      });
    } catch(e) {
      if (mounted) setState(() { error=e.toString().replaceFirst('Exception: ',''); loading=false; });
    }
  }

  @override void dispose() { tabs?.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final seasonKeys = seasons.keys.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: !loading && error == null && seasonKeys.isNotEmpty
          ? TabBar(controller: tabs, isScrollable: true, tabs: [
              for(final key in seasonKeys)
                Tab(text: 'الموسم $key  •  ${seasons[key]!.length} حلقة')
            ])
          : null,
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: () { setState(() {loading=true; error=null;}); _load(); }, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'))
            ])))
          : episodes.isEmpty
            ? const Center(child: Text('لا توجد حلقات متاحة لهذا المسلسل'))
            : Column(children: [
                _seriesHeader(seasonKeys.length),
                Expanded(child: TabBarView(
                  controller: tabs,
                  children: [
                    for(final key in seasonKeys)
                      _seasonEpisodes(seasons[key]!, key)
                  ],
                )),
              ]),
    );
  }

  Widget _seriesHeader(int seasonCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14,14,14,10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF252B49), Color(0xFF151827)]),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width:76,height:104, child: widget.item.poster.isEmpty
            ? const ColoredBox(color: Color(0xFF30364F), child: Icon(Icons.live_tv_rounded,size:34))
            : Image.network(widget.item.poster,fit:BoxFit.cover,errorBuilder: (_,__,___)=>const ColoredBox(color:Color(0xFF30364F),child:Icon(Icons.broken_image_outlined)))),
        ),
        const SizedBox(width:14),
        Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(widget.item.name, maxLines:2, overflow:TextOverflow.ellipsis, style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
          const SizedBox(height:8),
          Wrap(spacing:8,runSpacing:6,children:[
            _countPill(Icons.layers_outlined,'$seasonCount موسم'),
            _countPill(Icons.video_library_outlined,'${episodes.length} حلقة'),
          ]),
          if(widget.item.category.isNotEmpty) Padding(padding:const EdgeInsets.only(top:8),child:Text(widget.item.category,style:const TextStyle(color:Colors.white60,fontSize:12))),
        ])),
      ]),
    );
  }

  Widget _countPill(IconData icon,String text) => Container(
    padding:const EdgeInsets.symmetric(horizontal:9,vertical:6),
    decoration:BoxDecoration(color:Colors.white.withOpacity(.09),borderRadius:BorderRadius.circular(20)),
    child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:14,color:Colors.white70),const SizedBox(width:5),Text(text,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600))]),
  );

  Widget _seasonEpisodes(List<Map<String,dynamic>> list,String season) {
    final sorted = [...list]..sort((a,b)=>(int.tryParse('${a['episode_num'] ?? a['episode'] ?? 0}') ?? 0).compareTo(int.tryParse('${b['episode_num'] ?? b['episode'] ?? 0}') ?? 0));
    return ListView.separated(
      padding:const EdgeInsets.fromLTRB(14,8,14,24),
      itemCount:sorted.length,
      separatorBuilder:(_,__)=>const SizedBox(height:8),
      itemBuilder:(context,index) {
        final ep=sorted[index];
        final number=ep['episode_num'] ?? ep['episode'] ?? (index+1);
        final title=(ep['title'] ?? ep['name'] ?? 'الحلقة $number').toString();
        final ext=(ep['container_extension'] ?? 'mp4').toString();
        final id=ep['id'] ?? ep['episode_id'];
        final url='${widget.source.url.replaceAll(RegExp(r'/+$'),'')}/series/${Uri.encodeComponent(widget.source.user)}/${Uri.encodeComponent(widget.source.pass)}/$id.$ext';
        return Material(
          color:Colors.white.withOpacity(.045),
          borderRadius:BorderRadius.circular(14),
          child:ListTile(
            contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:4),
            leading:Container(width:46,height:46,decoration:BoxDecoration(color:Theme.of(context).colorScheme.primary.withOpacity(.18),borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.play_arrow_rounded)),
            title:Text(title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w600)),
            subtitle:Text('الموسم $season  •  الحلقة $number',style:const TextStyle(color:Colors.white54,fontSize:12)),
            trailing:const Icon(Icons.chevron_left_rounded,color:Colors.white54),
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PlayerScreen(ch:Channel(name:'${widget.item.name} - $title',url:url,logo:widget.item.poster,group:widget.item.category,sourceId:widget.item.sourceId)))),
          ),
        );
      },
    );
  }
}
