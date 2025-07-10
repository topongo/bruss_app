
import 'dart:async';

import 'package:bruss/api.dart';
import 'package:bruss/data/area_type.dart';
import 'package:bruss/data/route.dart' as br;
import 'package:bruss/data/path.dart' as bp;
import 'package:bruss/data/schedule.dart';
import 'package:bruss/data/stop.dart';
import 'package:bruss/data/trip_bundle.dart';
import 'package:bruss/database/database.dart';
import 'package:bruss/ui/pages/map/map.dart';
import 'package:bruss/ui/pages/map/markers.dart';
import 'package:bruss/ui/pages/map/sheet/details.dart';
import 'package:bruss/ui/pages/map/sheet/details_sheet.dart' show DetailsSheet, Dragger;
import 'package:bruss/ui/pages/map/sheet/route_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'stop_route_tile.dart';
import 'schedule_stop_tile.dart';


abstract class DetailsCard extends StatefulWidget {
  DetailsCard({super.key, required this.sizeController, required this.dragger});
  final BrussDB db = BrussDB();
  final trips = TripBundle.empty();
  final ValueNotifier<double> sizeController;
  DateTime referenceTime = DateTime.now();
  Key attemptKey = UniqueKey();
  final StreamController<void> _needsRebuildController = StreamController();
  void needsRebuild() => _needsRebuildController.add(null);
  Dragger dragger;
  
  Stop? stopReference();
  
  void favorite();
  Widget title();
  Widget icon();
  bool isFavorite();
  Future<void> loadMore() ;
  Future<void> update() async {
    final interactor = MapInteractor();
    try {
      await trips.getRtUpdates();
      if (interactor.focusedSched != null && trips.contains(interactor.focusedSched!)) {
        interactor.focusOnSched(interactor.focusedSched!, trips.routes[interactor.focusedSched!.trip.route]!);
      }
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.error, stack: e.stack, retry: () => update());
      } else {
        rethrow;
      }
    }
    needsRebuild();
  }
  bool hasMore() => trips.hasMore;
  Widget cardContent(BuildContext context, bool isLoading, int total, TickerProvider vsync, Function() loadMore);

  static const Duration updateDuration = Duration(seconds: 15);

  @override
  State<StatefulWidget> createState() => _DetailsCardState();
}

class _DetailsCardState extends State<DetailsCard> with TickerProviderStateMixin {
  bool _init = false;
  bool _loading = false;
  late final Future<void> _autoUpdateRoutine;
  late final StreamSubscription<void> _needsRebuildSub;

  Future<void> _autoUpdate() async {
    await Future.delayed(DetailsCard.updateDuration);
    while (mounted) {
      await widget.update();
      if (mounted) {
        setState(() {});
      }
      await Future.delayed(DetailsCard.updateDuration);
    }
  }

  Future<void> loadMoreInner() async {
    print("============> called loadMoreInner <=============");
    if(_loading || !widget.trips.hasMore) return;
    if (_init) {
      setState(() {
        _loading = true;
      });
    }
    await widget.loadMore();
    widget.trips.getRtUpdates().then((_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    });
    setState(() {
      _init = true;
    });
  }

  Future<void> loadMore() {
    return loadMoreInner().catchError((e, stack) {
      if (e is ApiException) {
        throw ApiException(e.error, stack: e.stack, retry: () => loadMore());
      } else {
        throw e;
      }
    });
  }

  @override
  void didUpdateWidget(covariant DetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trips.length == 0) {
      loadMore();
    } else {
      widget.trips.merge(oldWidget.trips);
    }
  }

  @override
  void initState() {
    super.initState();
    // on widget build finish
    print("called loadMore");
    loadMore();
    _needsRebuildSub = widget._needsRebuildController.stream.listen(_onNeedRebuild);
    WidgetsBinding.instance.addPostFrameCallback(_onPostFrame);
    _autoUpdateRoutine = _autoUpdate();
  }

  void _onNeedRebuild(_) {
    setState(() {
      // print("NEEDSREBUILD has been called!");
    });
  } 

  void _onPostFrame(_) {
    if (DetailsSheet.controller.isAttached && DetailsSheet.controller.size == 0) {
      DetailsSheet.controller.animateTo(DetailsSheet.initialSheetSize, duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
    } else {
      print("warning: tried to animate a detached controller, while loading card");
    }
  }

  @override
  void dispose() {
    super.dispose();
    _needsRebuildSub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return widget.cardContent(
      context,
      _loading,
      widget.trips.length,
      this,
      loadMore
    );
  }
}

class StopCard extends DetailsCard {
  Map<int, br.Route> routes = {};

  StopCard({required this.stop, required super.sizeController, super.key, required super.dragger});
  final Stop stop;

  @override
  void favorite() {
    if(stop.isFavorite == null || !stop.isFavorite!) {
      stop.isFavorite = true;
    } else {
      stop.isFavorite = false;
    }
    db.updateStop(stop);
  }
  
  @override
  bool isFavorite() => stop.isFavorite ?? false;

  @override
  Stop? stopReference() => stop;

  @override
  Future<void> loadMore() async {
    var req = Schedule.apiGetByStop(stop);
    // final DateFormat fmt = DateFormat("HH:mm");
    req.query = "?limit=10&skip=${trips.length}&time=${referenceTime.toUtc().toIso8601String()}Z";
    final newBundle = await TripBundle.fromRequest(req);
    await MapInteractor().getPaths(newBundle.schedules.map((t) => t.trip.path).toSet());
    trips.merge(newBundle);
  }

  @override
  Widget cardContent(BuildContext context, bool isLoading, int total, TickerProvider _, Function() loadMore) {
    final scheds;
    if (!isLoading) {
      scheds = trips.schedsSortedByStop(stop).toList();
    } else {
      scheds = <Schedule>[];
    }
    return Scaffold(
      appBar: AppBar(
        title: title(),
        actions: [
          IconButton(
            icon: Icon(isFavorite() ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              favorite();
              needsRebuild();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              update();
            }
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              dragger.collapse().then((_) => selectedEntity.value = null);
            },
          ),
        ]
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) :
        ListView.builder(
          controller: dragger.controller,
          itemCount: scheds.length + 1,
          itemBuilder: (context, index) {
            if (index == scheds.length) {
              return hasMore() ? ElevatedButton(
                onPressed: loadMore, 
                child: isLoading ? const CircularProgressIndicator()
                  : const Text("Load more")
              ) : total == 0 ? const Text("No trips") : const Text("No more trips");
            }
            return StopRouteTile(
              sched: scheds[index],
              hasPassed: () => trips.hasPassedFromStop(scheds[index], stop),
              stop: stopReference()!,
              route: trips.routes[scheds[index].trip.route]!,
              onTap: () {
                final newDets = RouteDetails(
                  route: trips.routes[scheds[index].trip.route]!,
                  schedule: scheds[index],
                );
                newDets.dragger = dragger;
                selectedEntity.value = newDets;
              }
            );
          }
        )
    );
  }

  @override
  Widget title() => Text(stop.name, style: const TextStyle(fontSize: 20));

  @override
  Widget icon() => Image.asset(MarkerType.values[stop.type.index].asset);
}

class RouteCard extends DetailsCard {
  RouteCard({required this.route, required super.sizeController, this.stop, Schedule? schedule, super.key, required super.dragger}) {
    // set previousSchedIndex
    if (schedule != null) {
      setParentTab(schedule);
    }
  }
  final br.Route route;
  final Stop? stop;
  TabController? tabController;
  int? previousSchedIndex;
  int? parentSchedIndex;
  DateTime? refTimeWithDelay;

  @override
  void favorite() {
    if(route.isFavorite == null || !route.isFavorite!) {
      route.isFavorite = true;
    } else {
      route.isFavorite = false;
    }
    db.updateRoute(route);
  }
  
  @override
  bool isFavorite() => route.isFavorite ?? false;

  @override
  Stop? stopReference() => stop;

  @override
  Future<void> loadMore() async {
    final Schedule? schedule;
    if (selectedEntity.value is RouteDetails) {
      schedule = (selectedEntity.value as RouteDetails).schedule;
    } else {
      schedule = null;
    }

    int count = 0;

    // only set this once!!
    refTimeWithDelay ??= referenceTime.subtract(Duration(minutes: schedule?.trip.delay ?? 0));

    do {
      print("loadMore iteration $count");
      var req = Schedule.apiGetByRoute(route);
      final DateFormat fmt = DateFormat("HH:mm");
      req.query = "?limit=5&skip=${trips.length}&time=${refTimeWithDelay!.toUtc().toIso8601String()}Z";
      final newBundle = await TripBundle.fromRequest(req);
      await MapInteractor().getPaths(newBundle.schedules.map((t) => t.trip.path).toSet());
      trips.merge(newBundle);
      count++;
      if (count > 4) {
        print("loadMore iteration limit reached");
        referenceTime = referenceTime.subtract(const Duration(minutes: 5));
        needsRebuild();
        break;
      }
    } while (schedule != null && !trips.contains(schedule));

    if (schedule != null) {
      setParentTab(schedule);
    }
  }

  Future<void> onTabChange(TabController tabController) async {
    final interactor = MapInteractor();
    // print("UPDATED previousSchedIndex: ${previousSchedIndex} -> ${tabController.index}");
    previousSchedIndex = tabController.index;
    if (tabController.index == trips.schedules.length) {
      // print("LOADING MORE SCHEDULES");
      await loadMore();
      needsRebuild();
    } else {
      // load trip path on map
      final targetSched = trips.schedules.skip(tabController.index).first;
      await interactor.focusOnSched(targetSched, route);
    }
  }

  void setParentTab(Schedule schedule) {
    int count = 0;
    int index = -1;
    for (final sched in trips.schedules) {
      if (sched.trip.id == schedule.trip.id) {
        index = count;
        break;
      }
      count++;
    }
    parentSchedIndex = index == -1 ? null : index;
  }

  @override
  Widget cardContent(BuildContext context, bool isLoading, int total, TickerProvider vsync, Function() loadMore) {
    if (isLoading) {
      tabController = null;
      return const CircularProgressIndicator();
    } else {
      this.tabController = TabController(vsync: vsync, length: trips.schedules.length + 1);
      final tabController = this.tabController!;
      tabController.addListener(() {
        onTabChange(tabController);
      });

      final tabs = <ScheduleTab>[];
      for (final sched in trips.schedules) {
        tabs.add(ScheduleTab(
          scrollController: dragger.controller,
          schedule: sched,
          route: route,
          stops: trips.stops,
          parentStop: stop,
        ));
      }

      final index = previousSchedIndex ?? parentSchedIndex ?? 0;
      if (index < trips.schedules.length) {
        final initialSchedule = tabs[previousSchedIndex ?? parentSchedIndex ?? 0].schedule;
        MapInteractor().focusOnSched(initialSchedule,route);
      }

      // print("BUILDING ROUTE CARD: previousSchedIndex=$previousSchedIndex parentSchedIndex=$parentSchedIndex");
      if (index != 0) {
        tabController.animateTo(index, duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
      }
      return DefaultTabController(
        length: trips.length + 1,
        child: Scaffold(
          appBar: AppBar(
            // title: Column(
            //   mainAxisSize: MainAxisSize.max,
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   children: [
            //     dragger,
            //     title(),
            //   ],
            // ),
            title: title(),
            leading: Padding(padding: const EdgeInsets.all(8), child: icon()),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(isFavorite() ? Icons.favorite : Icons.favorite_border),
                onPressed: () {
                  favorite();
                  needsRebuild();
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  update();
                }
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  dragger.collapse().then((_) => selectedEntity.value = null);
                },
              ),
            ],
            bottom: TabBar(
              controller: tabController,
              isScrollable: true,
              tabs: [
                for(final t in trips.schedules.map((sched) {
                  final dep = DateFormat("HH:mm").format(sched.departure.toLocal());
                  return Tab(text: "${sched.trip.headsign} ${sched.trip.direction.icon} ($dep)");
                }))
                  t,
                trips.length == 0 ? const Text("-") : const Tab(text: "Load more"),
              ],
            ),
          ),
          body: TabBarView(
            controller: tabController,
            children: [
              for (final t in tabs)
                t,
              trips.length == 0 ? const Center(child: CircularProgressIndicator()) : const Tab(text: "Load more"),
            ],
          )
        ),
      );
    }
  }

  @override
  Widget icon() => RouteIcon(label: route.code, color: route.color);

  @override
  Widget title() => 
    Text(route.name, style: const TextStyle(fontSize: 16));
}

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key, required this.schedule, required this.route, required this.stops, required this.scrollController, this.parentStop});

  final Schedule schedule;
  final Map<(int, AreaType), Stop> stops;
  final br.Route route;
  final ScrollController scrollController;
  static const double tileHeight = 55;
  final Stop? parentStop;

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  // final ScrollOffsetController _scrollOffsetController = ScrollOffsetController();
  // final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  // final ScrollOffsetListener _scrollOffsetListener = ScrollOffsetListener.create();
  late final bp.Path? path;
  final scrollKeys = Map<int, GlobalKey>();

  @override
  void initState() {
    super.initState();
    path = MapInteractor().paths[widget.schedule.trip.path];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = path?.passedStopIndex(widget.schedule.trip) ?? 0;
      widget.scrollController.animateTo(
      index * ScheduleTab.tileHeight, 
        duration: const Duration(milliseconds: 500), 
        curve: Curves.easeInOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sched = widget.schedule;
    final trip = sched.trip;
    final path = MapInteractor().paths[trip.path];
    final currentStop = path?.passedStopIndex(trip);

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: (path?.sequence.length ?? 0) + 1,
      itemBuilder: (context, index) {
        if (path == null) {
          return const Center(child: Text("No path found"));
        }
        if (index == path.sequence.length) {
          return Center(child: GestureDetector(
            child: Column(
              children: [
                Text("Bus ID: ${trip.busId}"),
                if (trip.delay != null)
                  Text("${trip.delay! < 0 ? "Early" : "Delay"}: ${trip.delay} min"),
                if (trip.lastEvent != null)
                  Text("Last update: ${DateTime.now().difference(trip.lastEvent!).inSeconds} seconds ago"),
                Text("Trip ID: ${trip.id}"),
              ],
            ),
            onTap: () {
              showDialog(context: context, builder: (context) {
                return Dialog(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final (key, value) in [
                        ("Trip ID", trip.id),
                        ("Bus ID", trip.busId),
                      ])
                        ListTile(
                          title: Text(key),
                          subtitle: Text(value.toString()),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: value.toString()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("$key copied to clipboard"))
                            );
                          },
                        )
                    ]
                  )
                );
              });
            }
          ));
        }
        scrollKeys[index] = GlobalKey();
        // print("Trip tracking info: nextStop=${trip.nextStop} lastStop=${trip.lastStop}");
        final indexPassed = path.passedStopIndex(trip);
        // print("sequence: ${path.sequence}[${path.passedStopIndex(trip)}] = ${busAtStop}");
        final currentStop = path.sequence[index];
        final stop = widget.stops[(currentStop, widget.route.areaType)]!;
        // print("currentStop: ${route.areaType}/$currentStop");
        return SizedBox(height: ScheduleTab.tileHeight, child: ScheduleStopTile(
          sched: sched,
          route: widget.route,
          highlight: widget.parentStop == stop,
          passed: indexPassed == null ? null : index <= indexPassed, 
          stop: stop,
          onTap: () async {
            if (DetailsSheet.controller.isAttached) {
              await DetailsSheet.controller.animateTo(DetailsSheet.initialSheetSize, duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
            }
            MapInteractor().focusOnStop(widget.stops[(currentStop, widget.route.areaType)]!);
          }));
      }
    );
  }
}
