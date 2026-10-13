import 'package:flutter/material.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/request/clients/danmaku_client.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/dandan_credentials.dart';

class DanmakuServiceTile extends StatefulWidget {
  const DanmakuServiceTile({super.key});
  @override
  State<DanmakuServiceTile> createState() => _DanmakuServiceTileState();
}

class _DanmakuServiceTileState extends State<DanmakuServiceTile> {
  @override
  Widget build(BuildContext context) => SettingsTile(
    leading: Icons.dns_outlined,
    title: const Text('弹幕服务'),
    description: const Text('弹弹play官方'),
    onPressed: (_) async {
      await showDialog<void>(
        context: context,
        builder: (_) => const _ServiceEditor(),
      );
      if (mounted) setState(() {});
    },
  );
}

class _ServiceEditor extends StatefulWidget {
  const _ServiceEditor();
  @override
  State<_ServiceEditor> createState() => _ServiceEditorState();
}

class _ServiceEditorState extends State<_ServiceEditor> {
  late final _id = TextEditingController(text: dandanCredentials['id']);
  late final _secret = TextEditingController(text: dandanCredentials['value']);
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _id.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    if (_id.text.trim().isEmpty || _secret.text.trim().isEmpty) {
      setState(() => _status = '请填写 App ID 和 App Secret');
      return;
    }
    setState(() {
      _busy = true;
      _status = '正在测试连接…';
    });
    try {
      await GStorage.putSetting(SettingsKeys.dandanAppId, _id.text.trim());
      await GStorage.putSetting(
        SettingsKeys.dandanAppSecret,
        _secret.text.trim(),
      );
      await DanmakuClient.instance.testConnection();
      if (mounted) setState(() => _status = '配置已保存，连接测试成功');
    } catch (_) {
      // Never show raw request errors or credentials on screen/in logs.
      if (mounted) setState(() => _status = '配置已保存，测试失败，请检查网络或凭证');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('弹幕服务'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _id,
              enabled: !_busy,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'App ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _secret,
              enabled: !_busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'App Secret'),
            ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_status!),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('关闭'),
      ),
      FilledButton(
        onPressed: _busy ? null : _saveAndTest,
        child: const Text('保存并测试'),
      ),
    ],
  );
}
