import 'package:flutter/widgets.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';
import 'package:turf/helpers.dart';
import 'package:turf/midpoint.dart';

class PolyEditor {
  final List<LatLng> points;
  final Widget pointIcon;
  final Size pointIconSize;
  final Widget? intermediateIcon;
  final Size intermediateIconSize;
  final void Function(LatLng? updatePoint)? callbackRefresh;
  final bool addClosePathMarker;
  final bool addLineStartMarker;
  final bool addLineEndMarker;

  PolyEditor({
    required this.points,
    required this.pointIcon,
    this.intermediateIcon,
    this.callbackRefresh,
    this.addLineStartMarker = false,
    this.addLineEndMarker = false,
    this.addClosePathMarker = false,
    this.pointIconSize = const Size(30, 30),
    this.intermediateIconSize = const Size(30, 30),
  });

  int? _markerToUpdate;

  void updateMarker(details, point) {
    if (_markerToUpdate != null) {
      points[_markerToUpdate!] = LatLng(point.latitude, point.longitude);
    }
    callbackRefresh?.call(LatLng(point.latitude, point.longitude));
  }

  List add(List<LatLng> pointsList, LatLng point) {
    pointsList.add(point);
    callbackRefresh?.call(point);
    return pointsList;
  }

  LatLng remove(int index) {
    final point = points.removeAt(index);
    callbackRefresh?.call(point);
    return point;
  }

  List<DragMarker> edit() {
    List<DragMarker> dragMarkers = [];

    final startC = addLineStartMarker || addClosePathMarker ? 0 : 1;
    final endC = addLineEndMarker || addClosePathMarker
        ? points.length
        : points.length - 1;
    for (var c = startC; c < endC; c++) {
      final indexClosure = c;
      dragMarkers.add(DragMarker(
        point: points[c],
        size: pointIconSize,
        builder: (_, __, ___) => pointIcon,
        onDragStart: (_, __) => _markerToUpdate = indexClosure,
        onDragUpdate: updateMarker,
        onLongPress: (ll) => remove(indexClosure),
      ));
    }

    for (var c = 0; c < points.length - 1; c++) {
      final polyPoint = points[c];
      final polyPoint2 = points[c + 1];

      if (intermediateIcon != null) {
        final indexClosure = c;
        final intermediatePoint = _intermediatePoint(polyPoint, polyPoint2);

        dragMarkers.add(DragMarker(
          point: intermediatePoint,
          size: intermediateIconSize,
          builder: (_, __, ___) => intermediateIcon!,
          onDragStart: (details, point) {
            points.insert(indexClosure + 1, intermediatePoint);
            _markerToUpdate = indexClosure + 1;
          },
          onDragUpdate: updateMarker,
        ));
      }
    }

    /// Final close marker from end back to beginning we want if its a closed polygon.
    if (addClosePathMarker && (points.length > 2)) {
      if (intermediateIcon != null) {
        final finalPointIndex = points.length - 1;
        final intermediatePoint = _intermediatePoint(points[finalPointIndex], points[0]);
        final indexClosure = points.length - 1;

        dragMarkers.add(DragMarker(
          point: intermediatePoint,
          size: intermediateIconSize,
          builder: (_, __, ___) => intermediateIcon!,
          onDragStart: (details, point) {
            points.insert(indexClosure + 1, intermediatePoint);
            _markerToUpdate = indexClosure + 1;
          },
          onDragUpdate: updateMarker,
        ));
      }
    }

    return dragMarkers;
  }
}

LatLng _intermediatePoint(LatLng p1, LatLng p2) {
  return _pointToLatLng(midpoint(_latLngToPoint(p1) , _latLngToPoint(p2)));
}

Point _latLngToPoint(LatLng ll) {
  return Point(coordinates: Position(ll.longitude, ll.latitude));
}

LatLng _pointToLatLng(Point p) {
  return LatLng(p.coordinates.lat.toDouble(), p.coordinates.lng.toDouble());
}