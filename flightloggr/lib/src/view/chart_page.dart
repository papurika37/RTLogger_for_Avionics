import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'log_list_page.dart';
import 'widget/log_replay_map.dart';

class ChartPage extends StatefulWidget {
  final File logFile;

  const ChartPage({super.key, required this.logFile});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  // ★【変更】チャートのタイトルをキーとして、データを直接管理
  final Map<String, List<FlSpot>> _chartData = {
    '高度': [], '速度': [], 'CAD': [], 'パワー': [],
    '姿勢角': [], 'ヨー': [], '操舵角': [], 'エアデータ': [],
    // 複数線グラフ用の補助データ
    '_pitch': [], '_rudder': [], '_slip': [], 
  };
  
  final Map<String, bool> _chartVisibility = {
    '高度': true, '速度': true, 'CAD': true, 'パワー': true,
    '姿勢角': true, 'ヨー': false, '操舵角': true, 'エアデータ': true,
  };
  late final List<String> _chartTitles;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chartTitles = _chartVisibility.keys.toList();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final lines = await widget.logFile.readAsLines();
      
      // デバッグ用：最初の数行のデータを出力して確認
      if (lines.isNotEmpty) {
        print("データサンプル:");
        for (int i = 0; i < (lines.length > 3 ? 3 : lines.length); i++) {
          final values = lines[i].split(',');
          print("行 $i: ${values.length} 項目 - $values");
        }
      }
      
      for (int i = 0; i < lines.length; i++) {
        final values = lines[i].split(',');
        if (values.length < 17) continue;

        // デバッグ用：特定の値を出力
        if (i < 5) {
          print("行 $i - 速度(value8): ${values[8]}, 全データ: $values");
        }

        // データマッピング（インデックスを確認）
        _chartData['姿勢角']!.add(FlSpot(i.toDouble(), (double.tryParse(values[5]) ?? 180) - 180)); // Roll
        _chartData['_pitch']!.add(FlSpot(i.toDouble(), (double.tryParse(values[6]) ?? 180) - 180));
        _chartData['ヨー']!.add(FlSpot(i.toDouble(), double.tryParse(values[7]) ?? 0));
        _chartData['速度']!.add(FlSpot(i.toDouble(), double.tryParse(values[8]) ?? 0)); // ← ここを確認
        _chartData['エアデータ']!.add(FlSpot(i.toDouble(), double.tryParse(values[9]) ?? 0)); // AoA
        _chartData['_slip']!.add(FlSpot(i.toDouble(), double.tryParse(values[10]) ?? 0));
        _chartData['高度']!.add(FlSpot(i.toDouble(), double.tryParse(values[11]) ?? 0));
        _chartData['CAD']!.add(FlSpot(i.toDouble(), double.tryParse(values[13]) ?? 0));
        _chartData['パワー']!.add(FlSpot(i.toDouble(), double.tryParse(values[14]) ?? 0));
        _chartData['操舵角']!.add(FlSpot(i.toDouble(), double.tryParse(values[15]) ?? 0)); // Elevator
        _chartData['_rudder']!.add(FlSpot(i.toDouble(), double.tryParse(values[16]) ?? 0));
      }
    } catch (e) {
      print("チャートデータ読み込みエラー: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Widget _buildChart(String title, List<List<FlSpot>> datasets, List<Color> colors, List<String> legendTitles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 4.0),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        // 凡例の表示
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, right: 16.0),
          child: Wrap( // 画面幅に応じて折り返すようにWrapを使用
            spacing: 16,
            runSpacing: 4,
            children: List.generate(legendTitles.length, (i) {
              return _buildLegendItem(colors[i], legendTitles[i]);
            }),
          ),
        ),
        AspectRatio(
          aspectRatio: 6,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
                lineBarsData: List.generate(datasets.length, (i) {
                  return LineChartBarData(
                    spots: datasets[i],
                    isCurved: false,
                    color: colors[i],
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 凡例の各項目を生成するヘルパー関数
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }

  // ★【追加】サイドメニュー（Drawer）を生成する関数
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            child: Text('表示データ', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          // _chartVisibilityマップから動的にスイッチを生成
          ..._chartVisibility.entries.map((entry) {
            return SwitchListTile(
              title: Text(entry.key),
              value: entry.value,
              onChanged: (bool value) {
                // スイッチが変更されたら、状態を更新してUIを再描画
                setState(() {
                  _chartVisibility[entry.key] = value;
                });
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.logFile.path.split(Platform.pathSeparator).last, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LogReplayWidget(logFile: widget.logFile),
                ),
              );
            },
            icon: const Icon(Icons.play_circle_fill),
            tooltip: 'ログ再生',
          ),
          IconButton(
            onPressed:(){
              Navigator.pop(
                context,
                MaterialPageRoute(builder: (context) => const LogListPage()),
              );
            },
            icon: const Icon(Icons.folder),
            tooltip:  '保存済みログ一覧',
          )
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chartData['姿勢角']!.isEmpty // いずれかのデータでチェック
              ? const Center(child: Text('表示できるデータがありません。'))
              : SingleChildScrollView(
                  child: Column(
                    children: _chartTitles.where((title) => _chartVisibility[title] ?? false).map((title) {
                      // ★【変更】キーを日本語に統一して安全にデータを参照
                      switch (title) {
                        case '高度':
                          return _buildChart('高度', [_chartData['高度']!], [Colors.purple], ['Alt[cm]']);
                        case '速度':
                          return _buildChart('速度', [_chartData['速度']!], [Colors.orange], ['AirSpeed[m/s]']);
                        case 'CAD':
                          return _buildChart('CAD', [_chartData['CAD']!], [Colors.teal], ['RPM[/min]']);
                        case 'パワー':
                          return _buildChart('パワー', [_chartData['パワー']!], [Colors.pink], ['Power[W]']);
                        case '姿勢角':
                          return _buildChart('姿勢角', [_chartData['姿勢角']!, _chartData['_pitch']!], [Colors.blue, Colors.red], ['Roll[deg]', 'Pitch[deg]']);
                        case 'ヨー':
                          return _buildChart('ヨー', [_chartData['ヨー']!], [Colors.green], ['Yaw[deg]']);
                        case '操舵角':
                          return _buildChart('操舵角', [_chartData['操舵角']!, _chartData['_rudder']!], [Colors.blue, Colors.red], ['Elevator[deg]', 'Rudder[deg]']);
                        case 'エアデータ':
                          return _buildChart('エアデータ', [_chartData['エアデータ']!, _chartData['_slip']!], [Colors.blue, Colors.red], ['AoA[deg]', 'SideSlip[deg]']);
                        default:
                          return const SizedBox.shrink();
                      }
                    }).toList(),
                  ),
              ),
    );
  }
}