import 'package:flutter_riverpod/flutter_riverpod.dart';

// ログデータ専用のProvider
final logProvider = StateProvider<List<String>>((ref) => []);