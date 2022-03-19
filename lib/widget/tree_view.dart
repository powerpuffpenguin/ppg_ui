import 'package:flutter/material.dart';

/// 節點定義
class TreeValue<TypeID extends Object, TypeData> {
  /// 節點 id
  final TypeID? id;

  /// 是否被選中
  bool checked;

  /// 是否展開節點
  bool expand;

  /// 顯示文本
  String text;

  /// 節點關聯數據
  TypeData? userdata;

  TreeValue({
    this.id,
    this.checked = false,
    this.expand = false,
    this.text = '',
    this.userdata,
  });
}

/// 節點控制器
class TreeValueController<TypeID extends Object, TypeData>
    extends ValueNotifier<TreeValue<TypeID, TypeData>> {
  TreeValueController({
    TypeID? id,
    bool checked = false,
    bool expand = false,
    String? text,
    TypeData? userdata,
  }) : super(TreeValue(
          id: id,
          checked: checked,
          expand: expand,
          text: text ?? '',
          userdata: userdata,
        ));
  final _children = <TreeValueController<TypeID, TypeData>>[];

  void _push(TreeValueController<TypeID, TypeData> child, TreeItemSort? sort) {
    child._parent?._remove(child.id);
    child._parent = this;
    _children.add(child);
    if (sort != null) {
      _children.sort(sort);
    }
    notifyListeners();
  }

  void _removeAndNotifyListeners(TypeID id) {
    if (_remove(id)) {
      notifyListeners();
    }
  }

  bool _remove(TypeID id) {
    for (var i = 0; i < _children.length; i++) {
      if (_children[i].id == id) {
        _children.removeAt(i);
        return true;
      }
    }
    debugPrint("TreeValueController remove id == $id not found");
    return false;
  }

  TreeValueController? _parent;
  TreeValueController? get parent => _parent;
  TypeID get id => value.id!;
  bool get checked => value.checked;
  bool get expand => value.expand;
  String get text => value.text;
  TypeData? get userdata => value.userdata;
  bool get isChildrenNotEmpty => _children.isNotEmpty;
  bool get isChildrenEmpty => _children.isEmpty;
  set checked(bool v) {
    if (v != value.checked) {
      value.checked = v;
      notifyListeners();
    }
  }

  set expand(bool v) {
    if (v != value.expand) {
      value.expand = v;
      notifyListeners();
    }
  }

  set text(String text) {
    if (text != value.text) {
      value.text = text;
      notifyListeners();
    }
  }

  set userdata(TypeData? val) {
    if (val != value.userdata) {
      value.userdata = val;
      notifyListeners();
    }
  }

  /// 清空子節點
  void clear() {
    if (_children.isNotEmpty) {
      for (var child in _children) {
        child._parent = null;
      }
      _children.clear();
      notifyListeners();
    }
  }

  /// 對所有節點調用 函數 f
  forEach(ForEach f) => _forEach(f);
  bool _forEach(ForEach f) {
    if (f(this)) {
      return true;
    }
    for (var child in _children) {
      if (child._forEach(f)) {
        return true;
      }
    }
    return false;
  }

  /// 對所有被選中的節點調用函數 f
  void forChecked(ForEach f) => _forChecked(f);
  bool _forChecked(ForEach f) {
    if (checked && f(this)) {
      return true;
    }
    for (var child in _children) {
      if (child._forChecked(f)) {
        return true;
      }
    }
    return false;
  }

  /// 對所有被選中的頂層節點調用函數 f
  void forTopChecked(ForEach f) => _forTopChecked(f);
  bool _forTopChecked(ForEach f) {
    if (checked && f(this)) {
      return true;
    }
    for (var child in _children) {
      if (child._forTopChecked(f)) {
        return true;
      }
    }
    return false;
  }

  /// 遍歷子節點
  Iterator<TreeValueController> get iterator {
    if (_children.isEmpty) {
      return _Iterator();
    }
    return _children.iterator;
  }
}

class _Iterator extends Iterator<TreeValueController> {
  @override
  bool moveNext() {
    return false;
  }

  @override
  TreeValueController get current {
    throw Exception('iterator ended');
  }
}

/// 遍歷節點的回調函數，如果返回 true 則會結束遍歷
typedef ForEach = bool Function(TreeValueController element);

/// 節點建築函數
typedef TreeItemBuilder<TypeID extends Object, TypeData> = Widget Function(
  BuildContext context,
  TreeValueController<TypeID, TypeData> item,
);

/// 節點排序函數
typedef TreeItemSort = int Function(TreeValueController, TreeValueController);

/// 樹控制器
class TreeController<TypeID extends Object, TypeData> {
  final _keys = <TypeID, TreeValueController<TypeID, TypeData>>{};
  final TreeItemSort? sort;
  final root = TreeValueController<TypeID, TypeData>(
    text: "root",
    expand: true,
  );
  TreeController({
    this.sort,
  });

  /// 如果節點存在返回 true
  bool containsKey(TypeID id) => _keys.containsKey(id);

  /// 如果節點存在返回控制器
  TreeValueController? controller(TypeID id) => _keys[id];

  /// 向樹添加一個節點
  bool add(TreeValue<TypeID, TypeData> value, {TypeID? parentID}) {
    final id = value.id;
    if (id == null) {
      debugPrint("TreeController not support push id == null");
      return false;
    } else if (_keys.containsKey(id)) {
      debugPrint("TreeController id == $id,already exists");
      return false;
    }
    TreeValueController? parent;
    if (parentID == null) {
      parent = root;
    } else {
      parent = _keys[parentID];
      if (parent == null) {
        debugPrint("TreeController parentID no found $parentID.");
        return false;
      }
    }
    final child = TreeValueController(
      id: id,
      checked: value.checked,
      expand: value.expand,
      text: value.text,
      userdata: value.userdata,
    );
    _keys[id] = child;
    parent._push(child, sort);
    return true;
  }

  /// 從樹中刪除節點
  bool remove(TypeID id) {
    final controller = _keys[id];
    if (controller == null) {
      return false;
    }
    controller._parent?._removeAndNotifyListeners(id);
    _keys.remove(id);
    return true;
  }

  /// 清空節點
  void clear() {
    _keys.clear();
    _keys.forEach((key, value) => value._parent = null);
    root.clear();
  }

  bool get isEmpty => _keys.isEmpty;
  bool get isNotEmpty => _keys.isNotEmpty;

  forEach(ForEach f) {
    for (var child in root._children) {
      child._forEach(f);
    }
  }

  void forChecked(ForEach f) {
    for (var child in root._children) {
      child._forChecked(f);
    }
  }

  void forTopChecked(ForEach f) {
    for (var child in root._children) {
      child._forTopChecked(f);
    }
  }
}

/// 樹視圖
class TreeView<TypeID extends Object, TypeData> extends StatefulWidget {
  const TreeView({
    Key? key,
    required this.controller,
    required this.builder,
    this.emptyBuilder,
    this.left = 20,
  })  : assert(left >= 0),
        super(key: key);

  /// 節點建築函數
  final TreeItemBuilder<TypeID, TypeData> builder;

  /// 節點爲空時的建築函數
  final WidgetBuilder? emptyBuilder;

  /// 控制器
  final TreeController<TypeID, TypeData> controller;
  // 子節點左側填充距離
  final double left;
  @override
  _TreeViewState<TypeID, TypeData> createState() =>
      _TreeViewState<TypeID, TypeData>();
}

class _TreeViewState<TypeID extends Object, TypeData>
    extends State<TreeView<TypeID, TypeData>> {
  TreeValueController<TypeID, TypeData> get root => widget.controller.root;
  @override
  void initState() {
    super.initState();
    root.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(TreeView<TypeID, TypeData> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.root.removeListener(_handleControllerChanged);
      root.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    root.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final children = root._children;
    if (children.isEmpty) {
      return widget.emptyBuilder == null
          ? const Text('')
          : widget.emptyBuilder!(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((item) {
        return _TreeItem<TypeID, TypeData>(
          key: widget.key,
          builder: widget.builder,
          controller: item,
          left: widget.left,
        );
      }).toList(),
    );
  }
}

class _TreeItem<TypeID extends Object, TypeData> extends StatefulWidget {
  const _TreeItem({
    Key? key,
    required this.builder,
    required this.controller,
    required this.left,
  })  : assert(left >= 0),
        super(key: key);
  final TreeItemBuilder<TypeID, TypeData> builder;
  final TreeValueController<TypeID, TypeData> controller;
  // children left padding
  final double left;
  @override
  _TreeItemState<TypeID, TypeData> createState() =>
      _TreeItemState<TypeID, TypeData>();
}

class _TreeItemState<TypeID extends Object, TypeData>
    extends State<_TreeItem<TypeID, TypeData>> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(_TreeItem<TypeID, TypeData> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.controller._children;
    if (children.isEmpty || !widget.controller.value.expand) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          widget.builder(context, widget.controller),
        ],
      );
    }
    final double left = widget.controller.value.id == null ? 0 : widget.left;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        widget.builder(context, widget.controller),
        Padding(
          padding: EdgeInsets.only(left: left),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.map((item) {
              return _TreeItem<TypeID, TypeData>(
                key: widget.key,
                builder: widget.builder,
                controller: item,
                left: widget.left,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
