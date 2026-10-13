import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:flutter/material.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/bean/widget/kazumi_menu.dart';

class SettingsDropdownTile<T> extends StatefulWidget {
  const SettingsDropdownTile({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.leading,
    this.description,
    this.icons = const {},
    this.fallbackLabel = '',
    this.enabled = true,
  });

  final Widget title;
  final IconData? leading;
  final Widget? description;
  final T value;
  final Map<T, String> options;
  final Map<T, IconData> icons;
  final ValueChanged<T> onChanged;
  final String fallbackLabel;
  final bool enabled;

  @override
  State<SettingsDropdownTile<T>> createState() =>
      _SettingsDropdownTileState<T>();
}

class _SettingsDropdownTileState<T> extends State<SettingsDropdownTile<T>> {
  final _controller = MenuController();
  final _buttonFocus = FocusNode();
  final _optionFocus = <T, FocusNode>{};

  @override
  void dispose() {
    _buttonFocus.dispose();
    for (final node in _optionFocus.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.options.isNotEmpty;
    if (isTv) {
      for (final key in widget.options.keys) {
        _optionFocus.putIfAbsent(key, () => FocusNode());
      }
    }
    return SettingsTile(
      focusNode: isTv ? _buttonFocus : null,
      leading: widget.leading,
      title: widget.title,
      description: widget.description,
      enabled: enabled,
      onPressed: (_) =>
          _controller.isOpen ? _controller.close() : _controller.open(),
      value: KazumiMenuButton(
        controller: _controller,
        childFocusNode: isTv ? _buttonFocus : null,
        trapTvFocus: isTv,
        onOpen: () {
          if (isTv)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _controller.isOpen) {
                (_optionFocus[widget.value] ??
                        _optionFocus[widget.options.keys.first])
                    ?.requestFocus();
              }
            });
        },
        enabled: enabled,
        builder: (_, _) =>
            Text(widget.options[widget.value] ?? widget.fallbackLabel),
        menuChildren: [
          for (final entry in widget.options.entries)
            KazumiMenuItem(
              focusNode: isTv ? _optionFocus[entry.key] : null,
              label: entry.value,
              selected: entry.key == widget.value,
              leadingIcon: widget.icons[entry.key] == null
                  ? null
                  : Icon(widget.icons[entry.key]),
              requestFocusOnHover: false,
              onPressed: enabled ? () => widget.onChanged(entry.key) : null,
            ),
        ],
      ),
      trailing: const Icon(Icons.arrow_drop_down_rounded),
    );
  }
}
