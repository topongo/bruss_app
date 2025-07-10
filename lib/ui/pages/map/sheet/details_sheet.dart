import 'package:bruss/ui/pages/map/map.dart';
import 'package:flutter/material.dart';
import 'package:bruss/database/database.dart';

class DetailsSheet extends StatefulWidget {
  DetailsSheet({super.key}) {
    DetailsSheet.buildCount++;
    print("====> DetailsSheet build count: $buildCount (${super.key})");
  }
  final BrussDB db = BrussDB();
  static int buildCount = 0;
  static const initialSheetSize = 0.4;
  static late DraggableScrollableController controller;
  double? previousSize;

  @override
  State<StatefulWidget> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<DetailsSheet> {
  final _sheet = GlobalKey();
  late final double initialChildSize;

  DraggableScrollableController get controller => DetailsSheet.controller;
  set controller(DraggableScrollableController value) {
    DetailsSheet.controller = value;
  }

  @override
  void initState() {
    super.initState();
    controller = DraggableScrollableController();
    controller.addListener(() {
      if (controller.size == 0) {
        selectedEntity.value?.updateSize(0);
        selectedEntity.value = null;
      } else {
        selectedEntity.value?.updateSize(controller.sizeToPixels(controller.size));
      }
    });
    selectedEntity.addListener(_onSelectedEntityChanged);
    // initialChildSize = selectedEntity.value == null ? 0 : DetailsSheet.initialSheetSize;
  }

  void _onSelectedEntityChanged() {
    print("====> selectedEntity changed: ${selectedEntity.value}");
    if (selectedEntity.value == null) {
      if (controller.isAttached) {
        controller.jumpTo(0);
      }
    } else {
      if (controller.size == 0) {
        _middle();
      }
    }
  }

  void _min() => _animateSheet(DetailsSheet.initialSheetSize);

  void _middle() => _animateSheet(DetailsSheet.initialSheetSize);

  void _max() => _animateSheet(1);

  void _hidden() => _animateSheet(0);

  void _offset(double off) {
    controller.jumpTo(controller.pixelsToSize(controller.sizeToPixels(controller.size) - off));
  }

  void _onDrag(DragUpdateDetails details) {
    _offset(details.primaryDelta!);
    final size = controller.sizeToPixels(controller.size) - details.primaryDelta!;
    print("size: $size");
    widget.previousSize = size;
  }

  void _toggle() {
    if (controller.size == sheet.maxChildSize) {
      _min();
    } else {
      _max();
    }
  }

  Future<void> _animateSheet(double size) async {
    print("===> called animateSheet($size)");
    if (controller.isAttached) {
      await controller.animateTo(
        size,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else {
      print("warning: tried to animate a detached details sheet controller");
    }
  }

  DraggableScrollableSheet get sheet => (_sheet.currentWidget as DraggableScrollableSheet);

  @override
  void dispose() {
    super.dispose();
    print("disposing of details sheet controller");
    selectedEntity.removeListener(_onSelectedEntityChanged);
    controller.dispose();
    selectedEntity.value?.updateSize(0);
  }

  @override
  Widget build(BuildContext context) {
    final double initialSize = selectedEntity.value != null ? DetailsSheet.initialSheetSize : 0;
    selectedEntity.value?.updateSize(initialSize);
    print("====> details sheet controller id: ${controller.hashCode}");
    return DraggableScrollableSheet(
      key: _sheet,
      maxChildSize: 1,
      minChildSize: 0,
      expand: true,
      initialChildSize: initialSize,
      snapSizes: const [DetailsSheet.initialSheetSize, 1],
      snap: true,
      controller: controller,
      builder: (BuildContext context, ScrollController scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: ValueListenableBuilder(
            valueListenable: selectedEntity,
            builder: (context, value, child) {
              if (value == null) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: const SizedBox(height: 0),
                );
              } else {
                value.dragger = Dragger(
                  onTap: _toggle,
                  onDrag: (details) {
                    _onDrag(details);
                  },
                  collapse: () async {
                    await _animateSheet(0);
                  },
                  controller: scrollController,
                );
                _middle();
                return value;
              }
            },
          ),
        );
      },
    );
  }

}

class Dragger extends StatelessWidget {
  const Dragger({required this.onTap, required this.onDrag, required this.controller, required this.collapse, super.key});
  final Function(DragUpdateDetails) onDrag;
  final Function() onTap;
  final Future<void> Function() collapse;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onVerticalDragUpdate: (details) { onDrag(details); },
      child: SizedBox(
        width: 45,
        height: 26,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(5.0),
            ),
            height: 6,
            width: 25,
          ),
        ),
      ),
    );
  }
}
