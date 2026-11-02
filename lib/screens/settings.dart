import 'package:flutter/material.dart';
import '../services/store.dart';
class SettingsScreen extends StatelessWidget { const SettingsScreen({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الإعدادات')),body:ListView(children:[ListTile(leading:const Icon(Icons.delete_sweep),title:const Text('مسح المفضلة'),onTap:()async{await Store.clearFavs();if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم')));}),const ListTile(leading:Icon(Icons.info),title:Text('Keefy TV'),subtitle:Text('الإصدار 1.1.0'))])); }
