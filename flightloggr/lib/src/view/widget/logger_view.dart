import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/serial_provider.dart';
import '../../provider/log_provider.dart';

// ★【変更】自動スクロールのためにConsumerStatefulWidgetに変更
class LoggerView extends ConsumerStatefulWidget {
  const LoggerView({super.key});

  @override
  ConsumerState<LoggerView> createState() => _LoggerViewState();
}

class _LoggerViewState extends ConsumerState<LoggerView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // ★【変更】serialProvider と logProvider の両方を監視/参照する
    final serialState = ref.watch(serialProvider);
    final serialNotifier = ref.read(serialProvider.notifier);
    final logLines = ref.watch(logProvider);
    
    // ★【追加】ログが更新されたら、一番下までスクロールする
    ref.listen(logProvider, (previous, next) {
      if (next.length > (previous?.length ?? 0)) {
        // 少し待ってからスクロールしないと、描画が間に合わない場合がある
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 接続設定エリア (変更なし)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text("ポート:"),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: serialState.selectedPort,
                          items: serialState.availablePorts
                              .map((port) => DropdownMenuItem(
                                    value: port,
                                    child: Text(port),
                                  ))
                              .toList(),
                          onChanged: serialState.isConnected
                              ? null
                              : (value) => serialNotifier.selectPort(value),
                          isExpanded: true,
                          hint: const Text("ポート選択"),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: serialState.isConnected
                            ? null
                            : () => serialNotifier.refreshPorts(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: serialState.selectedPort == null
                          ? null
                          : () {
                              if (serialState.isConnected) {
                                serialNotifier.disconnect();
                              } else {
                                serialNotifier.connect();
                              }
                            },
                      icon: Icon(serialState.isConnected
                          ? Icons.stop
                          : Icons.play_arrow),
                      label: Text(serialState.isConnected ? '切断' : '接続'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: serialState.isConnected
                              ? Colors.red
                              : Colors.green,
                          foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          
          // ★【変更】データ表示エリアをListView.builderに置き換え
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: logLines.length,
                  itemBuilder: (context, index) {
                    return Text(
                      logLines[index],
                      style: const TextStyle(fontFamily: 'monospace'), // 等幅フォントで見やすく
                    );
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          // 操作ボタンエリア (変更なし)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: serialNotifier.clearData,
                icon: const Icon(Icons.delete_outline),
                label: const Text('クリア'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed:
                    serialState.isConnected ? null : serialNotifier.saveAsCsv,
                icon: const Icon(Icons.save_alt),
                label: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
