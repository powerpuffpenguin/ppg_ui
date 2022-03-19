import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:king011_icons/king011_icons.dart';
import 'package:tuple/tuple.dart';

import '../state/state.dart';
import './spin.dart';
import './pick.dart';

/// 彈出一個檔案夾選擇頁面，用於用戶從系統選擇一個檔案路徑
///
///  * [title], 標題文本
///  * [pickTooltip], 選取文本提示
///  * [home], 家目錄
///  * [current], 當前路徑
///  * [hide], 隱藏以 . 開頭的檔案夾
///  * [nav], 可選的左側導航抽屜
///  * [filter], 後綴名過濾 ignoreCase=true [ Tuple3('txt|text','文本',ignoreCase) ]
Future<String?> pickFile({
  required BuildContext context,
  String title = 'pick file',
  String pickTooltip = 'pick',
  String showTooltip = 'show all',
  String hideTooltip = 'show normal',
  String filterTooltip = 'filter',
  required PickerNav home,
  String? current,
  bool hide = true,
  List<PickerNav>? nav,
  List<Tuple3<String, String, bool?>>? filter,
  int initialFilter = 0,
}) {
  return Navigator.of(context).push<String>(MaterialPageRoute(
    builder: (_) => PickFile(
      title: title,
      pickTooltip: pickTooltip,
      showTooltip: showTooltip,
      hideTooltip: hideTooltip,
      filterTooltip: filterTooltip,
      home: home,
      current: current,
      hide: hide,
      nav: nav,
      multiple: false,
      filter: filter,
      initialFilter: initialFilter,
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
///  * [filter], 後綴名過濾 ignoreCase=true [ Tuple3('txt|text','文本',ignoreCase) ]
Future<List<String>?> pickMultipleFile({
  required BuildContext context,
  String title = 'pick file',
  String pickTooltip = 'pick',
  String showTooltip = 'show all',
  String hideTooltip = 'show normal',
  String filterTooltip = 'filter',
  required PickerNav home,
  String? current,
  bool hide = true,
  List<PickerNav>? nav,
  List<Tuple3<String, String, bool?>>? filter,
  int initialFilter = 0,
}) {
  return Navigator.of(context).push<List<String>>(MaterialPageRoute(
    builder: (_) => PickFile(
      title: title,
      pickTooltip: pickTooltip,
      showTooltip: showTooltip,
      hideTooltip: hideTooltip,
      filterTooltip: filterTooltip,
      home: home,
      current: current,
      hide: hide,
      nav: nav,
      multiple: true,
      filter: filter,
      initialFilter: initialFilter,
    ),
  ));
}

class PickFile extends StatefulWidget {
  const PickFile({
    Key? key,
    this.title = 'pick file',
    this.pickTooltip = 'pick',
    this.showTooltip = 'show all',
    this.hideTooltip = 'show normal',
    this.filterTooltip = 'filter',
    required this.home,
    this.current,
    this.hide = false,
    this.nav,
    this.multiple = false,
    this.filter,
    this.initialFilter = 0,
  }) : super(key: key);

  /// 標題文本
  final String title;

  /// 選取文本提示
  final String pickTooltip;

  /// 顯示隱藏檔案 文本提示
  final String showTooltip;

  /// 不顯示隱藏檔案 文本提示
  final String hideTooltip;
  final String filterTooltip;

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

  /// 後綴名過濾 ignoreCase=true [ Tuple3('txt|text','文本',ignoreCase) ]
  final List<Tuple3<String, String, bool?>>? filter;
  final int initialFilter;
  @override
  _PickFileState createState() => _PickFileState();
}

class _PickFileState extends UIState<PickFile> {
  late Directory _current;
  late bool _hide;
  dynamic _error;
  var _source = <Tuple2<FileSystemEntity, FileStat>>[];
  final _checked = <String>{};
  List<String>? _path;
  bool _edit = false;
  final _controller = TextEditingController();
  int _filter = 0;
  @override
  void initState() {
    super.initState();
    if (widget.current?.isEmpty ?? true) {
      _current = widget.home.dir;
    } else {
      _current = Directory(widget.current!);
    }
    _hide = widget.hide;
    if (widget.initialFilter >= 0 &&
        widget.initialFilter < (widget.filter?.length ?? 0)) {
      _filter = widget.initialFilter;
    }
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
          source.add(Tuple2(item, stat));
        } catch (e) {
          debugPrint('stat error: $item -> $e');
        }
      }
      aliveSetState(() {
        source.sort((l, r) {
          final lv = l.item2.type == FileSystemEntityType.directory ? 0 : 1;
          final rv = r.item2.type == FileSystemEntityType.directory ? 0 : 1;
          final v = lv - rv;
          if (v != 0) {
            return v;
          }
          return path
              .basename(l.item1.path)
              .compareTo(path.basename(r.item1.path));
        });
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
          _buildFilter(context),
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

  Widget _buildFilter(BuildContext context) {
    if ((widget.filter?.length ?? 0) < 2) {
      return Container();
    }
    return PopupMenuButton<IconData>(
        enabled: enabled,
        tooltip: widget.filterTooltip,
        icon: const Icon(Icons.filter_list),
        itemBuilder: (BuildContext context) {
          final result = <PopupMenuItem<IconData>>[];

          for (var i = 0; i < widget.filter!.length; i++) {
            final data = widget.filter![i];
            result.add(PopupMenuItem<IconData>(
              child: ListTile(
                trailing:
                    _filter == i ? const Icon(Icons.check_outlined) : null,
                title: Text(data.item2),
              ),
              onTap: () => setState(() {
                _filter = i;
              }),
            ));
          }
          return result;
        });
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
    if (!widget.multiple) {
      return null;
    }
    return FloatingActionButton(
      child: const Icon(Icons.done),
      tooltip: widget.pickTooltip,
      onPressed: disabled
          ? null
          : () {
              if (_checked.isNotEmpty) {
                final result = _checked.toList();
                result.sort((l, r) => l.compareTo(r));
                Navigator.of(context).pop(result);
              }
            },
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
            final dir = data.item2.type == FileSystemEntityType.directory;
            if (!dir &&
                _filter > 0 &&
                (_filter < (widget.filter?.length ?? 0))) {
              final filter = widget.filter![_filter];
              if (filter.item1 != '') {
                var ext = path.extension(name);
                if (filter.item3 ?? false) {
                  ext = ext.toLowerCase();
                }
                final strs = filter.item1.split('|');
                var matched = false;
                for (var str in strs) {
                  if (str == '') {
                    matched = true;
                    break;
                  }
                  if (filter.item3 ?? false) {
                    str = str.toLowerCase();
                  }
                  if (ext == '.$str') {
                    matched = true;
                    break;
                  }
                }
                if (!matched) {
                  return Container();
                }
              }
            }
            if (dir) {
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(name),
                subtitle: Text('${data.item2.modified}'),
                onTap: disabled ? null : () => _ls(Directory(data.item1.path)),
              );
            }
            return ListTile(
              leading: const Icon(Icons.file_open),
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
              onTap: null,
            );
          }),
    ));
    return Column(
      children: children,
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
