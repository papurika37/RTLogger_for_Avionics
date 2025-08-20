import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'home_page.dart';

import 'chart_page.dart'; // チャートページのインポート

class LogListPage extends StatefulWidget {
  const LogListPage({super.key});

  @override
  State<LogListPage> createState() => _LogListPageState();
}

class _LogListPageState extends State<LogListPage> {
  // ファイル一覧を取得する非同期処理
  Future<List<FileSystemEntity>> _getLogFiles() async {
    try {
      final logDirPath = path.join(Directory.current.path, 'logs');
      final logDir = Directory(logDirPath);

      // logsフォルダが存在するか確認
      if (!await logDir.exists()) {
        return []; // フォルダがなければ空のリストを返す
      }

      // フォルダの中身を取得し、.csvファイルのみをフィルタリング
      final files = await logDir.list().toList();
      final csvFiles = files.where((file) => path.extension(file.path) == '.csv').toList();

      // 更新日時が新しい順にソートする
      csvFiles.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });
      
      return csvFiles;
    } catch (e) {
      print("ログファイルの読み込みエラー: $e");
      return [];
    }
  }

  // ファイルサイズを読みやすい形式にフォーマットする関数
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('保存済みログ一覧'),
        actions: [
          IconButton(
            onPressed:(){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            icon: const Icon(Icons.home),
            tooltip:  'ホーム',
          )
        ],
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: _getLogFiles(), // ファイル取得処理を呼び出し
        builder: (context, snapshot) {
          // 処理中の場合、ローディングインジケータを表示
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // エラーが発生した場合
          if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }
          // データがない（ファイルが0個の）場合
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('保存されているログファイルはありません。'));
          }

          final files = snapshot.data!;

          // ファイル一覧をリスト表示
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileStat = file.statSync();

              return ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(path.basename(file.path)), // ファイル名
                subtitle: Text(
                  // 更新日時とファイルサイズを表示
                  '${DateFormat('yyyy/MM/dd HH:mm').format(fileStat.modified)} - ${_formatFileSize(fileStat.size)}'
                ),
                // ここにタップした時の処理（ファイルを開くなど）を将来追加できる
                onTap: () {
                  // ★【変更】タップでチャートページに遷移する
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      // 表示するファイルを渡してChartPageを開く
                      builder: (context) => ChartPage(logFile: File(file.path)),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}