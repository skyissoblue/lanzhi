import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});
  @override State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final api = ApiService();
  late Future<List<Map<String, dynamic>>> future;
  @override void initState(){super.initState();future=api.groupedWatchlist();}
  void reload()=>setState(()=>future=api.groupedWatchlist());
  bool _isEtf(String code)=>code.startsWith('51')||code.startsWith('56')||code.startsWith('15');

  @override Widget build(BuildContext context)=>DefaultTabController(length:2,child:Column(children:[
    const Material(color:Colors.white,child:TabBar(tabs:[Tab(text:'股票'),Tab(text:'ETF')])),
    Expanded(child:FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(context,snapshot){
      if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(snapshot.hasError)return Center(child:Text('加载失败：${snapshot.error}'));
      final groups=snapshot.data??[];
      return TabBarView(children:[_groups(groups,false),_groups(groups,true)]);
    })),
  ]));

  Widget _groups(List<Map<String,dynamic>> groups,bool etf){
    final filtered=<Map<String,dynamic>>[];
    for(final group in groups){
      final stocks=(group['stocks'] as List? ?? const []).whereType<Map>().where((stock)=>_isEtf('${stock['code']}')==etf).toList();
      if(stocks.isNotEmpty)filtered.add({...group,'stocks':stocks});
    }
    if(filtered.isEmpty)return Center(child:Text(etf?'还没有 ETF 自选':'还没有股票自选，去首页选股并加入吧'));
    return RefreshIndicator(onRefresh:()async=>reload(),child:ListView(children:[for(final group in filtered)ExpansionTile(initiallyExpanded:true,title:Text('来自：${group['combo_name']} · ${(group['stocks'] as List).length}'),children:[for(final stock in group['stocks'] as List)Dismissible(key:ValueKey('${stock['code']}-$etf'),direction:DismissDirection.endToStart,background:Container(color:Colors.red,alignment:Alignment.centerRight,padding:const EdgeInsets.only(right:20),child:const Icon(Icons.delete,color:Colors.white)),onDismissed:(_)async{await api.removeWatchlist('${stock['code']}');reload();},child:ListTile(title:Text('${stock['name']??''}'),subtitle:Text('${stock['code']}'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{await api.removeWatchlist('${stock['code']}');reload();})) )]) ]));
  }
}
