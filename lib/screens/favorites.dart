import 'package:flutter/material.dart';
import '../services/store.dart';
import 'channels.dart';
class FavoritesScreen extends StatefulWidget { const FavoritesScreen({super.key}); @override State<FavoritesScreen> createState()=>_S(); }
class _S extends State<FavoritesScreen> { @override Widget build(BuildContext context){final l=Store.favs(); return Scaffold(appBar:AppBar(title:const Text('المفضلة')),body:l.isEmpty?const Center(child:Text('ما في مفضلة بعد')):ListView(children:[for(final c in l) channelTile(context,c,()=>setState((){}))]));} }
