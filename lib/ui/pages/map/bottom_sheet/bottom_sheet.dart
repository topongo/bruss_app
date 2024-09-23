import 'package:flutter/material.dart';
import 'package:bruss/database/database.dart';

class BottomSheet extends StatefulWidget {
  BottomSheet({required this.selectedEntity, super.key});
  final BrussDB db = BrussDB();
  final ValueNotifier<DetailsType?> selectedEntity;

  @override
  State<StatefulWidget> createState() => _BottomSheetState();
}

class _BottomSheetState extends State<BottomSheet> {
  final _sheet = GlobalKey();
  final _controller = DraggableScrollableController();
  static const _initialChildSize = 0.1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    // if (dontHide) return;
    // print("collapsing sheet: (dontHide = $dontHide)");
    // final currentSize = _controller.size;
    // if (currentSize <= 0.05) _collapse();
  }

  void _min() => _animateSheet(sheet.snapSizes!.first);

  void _middle() => _animateSheet(sheet.snapSizes![1]);

  void _max() => _animateSheet(sheet.maxChildSize);

  void _hidden() => _animateSheet(0);
  
  void _toggle() {
    if (_controller.size == sheet.maxChildSize) {
      _min();
    } else {
      _max();
    }
  }

  void _animateSheet(double size) {
    _controller.animateTo(
      size,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  DraggableScrollableSheet get sheet => (_sheet.currentWidget as DraggableScrollableSheet);

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      key: _sheet,
      initialChildSize: _initialChildSize,
      maxChildSize: 1,
      minChildSize: 0,
      expand: true,
      snap: true,
      snapSizes: const [_initialChildSize, 0.4],
      controller: _controller,
      builder: (BuildContext context, ScrollController scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter( 
                  child: Center(
                    child: GestureDetector(
                      onTap: _toggle,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(width: 45, height: 26, child: Center(child: Container( 
                        decoration: BoxDecoration( 
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        height: 6,
                        width: 25,
                      ))),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ValueListenableBuilder(
                    valueListenable: widget.selectedEntity, 
                    builder: (context, value, child) {
                      if(value == null) {
                        _hidden();
                        return const Text("empty");
                      } else {
                        _middle();
                        return value.render(context);
                      }
                    }
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
