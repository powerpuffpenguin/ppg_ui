import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:king011_icons/king011_icons.dart';
import 'package:tuple/tuple.dart';

import '../state/state.dart';
import './spin.dart';
import './pick.dart';

/// 彈出一個檔案夾選擇頁面，用於用戶從系統選擇一個檔案夾路徑
///
///  * [title], 標題文本
///  * [pickTooltip], 選取文本提示
///  * [home], 家目錄
///  * [current], 當前路徑
///  * [hide], 隱藏以 . 開頭的檔案夾
///  * [nav], 可選的左側導航抽屜
Future<String?> pickDirectory({
  required BuildContext context,
  String title = 'pick directory',
  String pickTooltip = 'pick',
  String showTooltip = 'show all',
  String hideTooltip = 'show normal',
  required PickerNav home,
  String? current,
  bool hide = true,
  List<PickerNav>? nav,
}) {
  return Navigator.of(context).push<String>(MaterialPageRoute(
    builder: (_) => PickDirectory(
      title: title,
      pickTooltip: pickTooltip,
      showTooltip: showTooltip,
      hideTooltip: hideTooltip,
      home: home,
      current: current,
      hide: hide,
      nav: nav,
      multiple: false,
    ),
  ));
}

/// 彈出一個檔案夾選擇頁面，用於用戶從系統選擇多個檔案夾路徑
///
///  * [title], 標題文本
///  * [pickTooltip], 選取文本提示
///  * [home], 家目錄
///  * [current], 當前路徑
///  * [hide], 隱藏以 . 開頭的檔案夾
///  * [nav], 可選的左側導航抽屜
Future<List<String>?> pickMultipleDirectory({
  required BuildContext context,
  String title = 'pick directory',
  String pickTooltip = 'pick',
  String showTooltip = 'show all',
  String hideTooltip = 'show normal',
  required PickerNav home,
  String? current,
  bool hide = true,
  List<PickerNav>? nav,
}) {
  return Navigator.of(context).push<List<String>>(MaterialPageRoute(
    builder: (_) => PickDirectory(
      title: title,
      pickTooltip: pickTooltip,
      showTooltip: showTooltip,
      hideTooltip: hideTooltip,
      home: home,
      current: current,
      hide: hide,
      nav: nav,
      multiple: true,
    ),
  ));
}

class PickDirectory extends StatefulWidget {
  const PickDirectory({
    Key? key,
    this.title = 'pick directory',
    this.pickTooltip = 'pick',
    this.showTooltip = 'show all',
    this.hideTooltip = 'show normal',
    required this.home,
    this.current,
    this.hide = false,
    this.nav,
    this.multiple = false,
  }) : super(key: key);

  /// 標題文本
  final String title;

  /// 選取文本提示
  final String pickTooltip;

  /// 顯示隱藏檔案 文本提示
  final String showTooltip;

  /// 不顯示隱藏檔案 文本提示
  final String hideTooltip;

  /// 家目錄
  final PickerNav home;

  /// 當前路徑
  final String? current;

  /// 隱藏以 . 開頭的檔案夾
  final bool hide;

  /// 是否運行多選
  final bool multiple;

  /// 可選的左側導航抽屜
  final List<PickerNav>? nav;
  @override
  _PickDirectoryState createState() => _PickDirectoryState();
}

class _PickDirectoryState extends UIState<PickDirectory> {
  late Directory _current;
  late bool _hide;
  dynamic _error;
  var _source = <Tuple2<FileSystemEntity, FileStat>>[];
  final _checked = <String>{};
  List<String>? _path;
  bool _edit = false;
  final _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.current?.isEmpty ?? true) {
      _current = widget.home.dir;
    } else {
      _current = Directory(widget.current!).absolute;
    }
    _hide = widget.hide;
    _ls(_current);
  }

  _ls(Directory dir) async {
    if (enabled || _error != null) {
      setState(() {
        _error = null;
        enabled = false;
      });
    }
    try {
      final source = <Tuple2<FileSystemEntity, FileStat>>[];
      await for (var item in dir.list()) {
        if (isClosed) {
          return;
        }
        try {
          final stat = await item.stat();
          if (stat.type == FileSystemEntityType.directory) {
            source.add(Tuple2(item, stat));
          }
        } catch (e) {
          debugPrint('stat error: $item -> $e');
        }
      }
      aliveSetState(() {
        source.sort((l, r) =>
            path.basename(l.item1.path).compareTo(path.basename(r.item1.path)));
        _source = source;
        _current = dir;
        _path = path.split(dir.path);
        _controller.text = dir.path;
        _checked.clear();
      });
    } catch (e) {
      aliveSetState(() => _error = e);
    } finally {
      aliveSetState(() => enabled = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNav = widget.nav?.isNotEmpty ?? false;

    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Text(widget.title),
        leadingWidth: hasNav ? null : 0,
        leading: hasNav ? null : Container(),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: widget.home.name,
            onPressed: disabled ? null : () => _ls(widget.home.dir),
          ),
          IconButton(
            icon: Icon(
                _hide ? Icons.visibility_off_sharp : Icons.visibility_sharp),
            tooltip: _hide ? widget.showTooltip : widget.hideTooltip,
            onPressed: disabled
                ? null
                : () => setState(() {
                      _hide = !_hide;
                    }),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back_sharp),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget? _buildDrawer(context) {
    final nav = widget.nav;
    if (nav?.isEmpty ?? true) {
      return null;
    }
    final children = <Widget>[];
    children.addAll(nav!.map<Widget>((data) => ListTile(
          leading: const Icon(Icons.folder),
          title: Text(data.name),
          onTap: disabled
              ? null
              : () {
                  Navigator.of(context).pop();
                  _ls(data.dir);
                },
        )));
    return Drawer(
      child: ListView(
        children: children,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final children = <Widget>[
      _buildBottom(context),
    ];
    if (_error != null) {
      children.add(Text(
        '$_error',
        style: TextStyle(color: Theme.of(context).errorColor),
      ));
    }
    children.add(Expanded(
      child: ListView.builder(
          itemCount: _source.length,
          itemBuilder: (context, i) {
            final data = _source[i];
            final name = path.basename(data.item1.path);
            if (_hide && name.startsWith('.')) {
              return Container();
            }
            return ListTile(
              leading: const Icon(Icons.folder),
              title: Text(name),
              subtitle: Text('${data.item2.modified}'),
              trailing: widget.multiple
                  ? Checkbox(
                      value: _checked.contains(data.item1.path),
                      onChanged: (v) {
                        setState(() {
                          if (v != null && v) {
                            _checked.add(data.item1.path);
                          } else {
                            _checked.remove(data.item1.path);
                          }
                        });
                      })
                  : IconButton(
                      icon: const Icon(AntDesign.select1),
                      tooltip: widget.pickTooltip,
                      onPressed: disabled
                          ? null
                          : () => Navigator.of(context).pop(data.item1.path),
                    ),
              onTap: disabled ? null : () => _ls(Directory(data.item1.path)),
            );
          }),
    ));
    return Column(
      children: children,
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (disabled) {
      return const FloatingActionButton(
        child: Spin(
          child: Icon(
            FontAwesome.spinner,
            size: 32,
          ),
        ),
        onPressed: null,
      );
    }

    return FloatingActionButton(
      child: const Icon(AntDesign.select1),
      tooltip: widget.pickTooltip,
      onPressed: disabled
          ? null
          : () {
              if (widget.multiple) {
                if (_checked.isEmpty) {
                  Navigator.of(context).pop(<String>[_current.path]);
                } else {
                  final result = _checked.toList();
                  result.sort((l, r) => l.compareTo(r));
                  Navigator.of(context).pop(result);
                }
              } else {
                Navigator.of(context).pop(_current.path);
              }
            },
    );
  }

  Widget _buildBottom(BuildContext context) {
    const double height = 70;
    final toggle = IconButton(
      icon: Icon(_edit
          ? MaterialCommunityIcons.toggle_switch
          : MaterialCommunityIcons.toggle_switch_off),
      onPressed: disabled
          ? null
          : () => setState(() {
                _edit = !_edit;
              }),
    );
    if (_edit) {
      return SizedBox(
        height: 70,
        child: Row(
          children: [
            toggle,
            Expanded(
              child: TextFormField(
                enabled: enabled,
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'path',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: MaterialLocalizations.of(context).okButtonLabel,
                    onPressed: disabled
                        ? null
                        : () {
                            setState(() {
                              _edit = false;
                            });
                            _ls(Directory(_controller.text));
                          },
                  ),
                ),
                onEditingComplete: disabled
                    ? null
                    : () {
                        setState(() {
                          _edit = false;
                        });
                        _ls(Directory(_controller.text));
                      },
              ),
            ),
          ],
        ),
      );
    }
    final children = <Widget>[
      toggle,
    ];
    if (_path?.isNotEmpty ?? false) {
      String str = '';
      for (var i = 0; i < _path!.length; i++) {
        String name = _path![i];
        if (i == 0) {
          str = name;
          name = ' $name ';
        } else {
          str = path.join(str, name);
        }
        final child = _buildPathNode(context, name, str);
        if (i > 1) {
          children.add(
            Center(
              child: Text(path.separator),
            ),
          );
        }
        children.add(child);
      }
    }
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: children,
      ),
    );
  }

  Widget _buildPathNode(BuildContext context, String name, String path) {
    return InkWell(
      child: Center(
        child: Text(name),
      ),
      onTap: disabled ? null : () => _ls(Directory(path)),
    );
  }
}
