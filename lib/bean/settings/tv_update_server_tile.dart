import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/services/update/auto_updater.dart';

class TvUpdateServerTile extends StatefulWidget {
  const TvUpdateServerTile({super.key});
  @override
  State<TvUpdateServerTile> createState() => _TvUpdateServerTileState();
}

class _TvUpdateServerTileState extends State<TvUpdateServerTile> {
  Future<void> _editUpdateServer() async {
    final saved = GStorage.getSetting(SettingsKeys.tvUpdateServer);
    final input = TextEditingController(
      text: saved.isEmpty ? tvUpdateBase : saved,
    );
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('TV 更新服务器'),
        content: TextField(
          controller: input,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'http://服务器IP:18080',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final text = input.text.trim().replaceFirst(RegExp(r'/+$'), '');
              final uri = Uri.tryParse(text);
              if (text.isNotEmpty &&
                  (uri == null ||
                      !['http', 'https'].contains(uri.scheme) ||
                      uri.host.isEmpty ||
                      uri.userInfo.isNotEmpty ||
                      uri.hasQuery ||
                      uri.hasFragment ||
                      uri.path.isNotEmpty)) {
                KazumiDialog.showToast(
                  message: '请输入服务器地址，例如 http://服务器IP:18080',
                );
                return;
              }
              Navigator.pop(dialogContext, text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    // Wait for the closing dialog to release its text controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
    if (value != null && mounted) {
      await GStorage.putSetting(SettingsKeys.tvUpdateServer, value);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => SettingsTile(
    leading: Icons.system_update_rounded,
    title: const Text('TV 更新服务器'),
    description: Text(
      GStorage.getSetting(SettingsKeys.tvUpdateServer).isEmpty
          ? (tvUpdateBase.isEmpty ? '未配置' : tvUpdateBase)
          : GStorage.getSetting(SettingsKeys.tvUpdateServer),
    ),
    onPressed: (_) => _editUpdateServer(),
  );
}
