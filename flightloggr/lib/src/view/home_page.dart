import 'package:flutter/material.dart';
import 'widget/logger_view.dart';
import 'widget/map_view.dart';
import 'widget/instrument_widget.dart';
import 'log_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetory Log Tracker'),
        actions: [
          IconButton(
            onPressed:(){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogListPage()),
              );
            },
            icon: const Icon(Icons.folder),
            tooltip:  '保存済みログ一覧',
          )
        ],
      ),
      body: const Row(
        children: [
          // 左側：操作パネル
          Expanded(
            flex: 1,
            child: LoggerView(),
          ),
          VerticalDivider(width: 1, thickness: 1),
          // 中央：リアルタイム計器
          Expanded(
            flex: 1,
            child: InstrumentWidget(),
          ),
          VerticalDivider(width: 1, thickness: 1),
          // 右側：地図
          Expanded(
            flex: 2,
            child: MapView(),
          ),
        ],
      ),
    );
  }
}