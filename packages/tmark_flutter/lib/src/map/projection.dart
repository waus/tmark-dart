part of tmark_flutter;

const double _leafletTileSize = 256;

final class TmarkLatLng {
  const TmarkLatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  TmarkLatLng clamped() {
    return TmarkLatLng(
      latitude.clamp(-85.05112878, 85.05112878).toDouble(),
      longitude.clamp(-180, 180).toDouble(),
    );
  }
}

final class TmarkTileCoord {
  const TmarkTileCoord(this.x, this.y, this.z);

  final int x;
  final int y;
  final int z;

  @override
  bool operator ==(Object other) =>
      other is TmarkTileCoord && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'TmarkTileCoord($x, $y, $z)';
}

final class _LeafletProjection {
  const _LeafletProjection();

  double worldSize(int zoom) => _leafletTileSize * math.pow(2, zoom);

  Offset project(TmarkLatLng input, int zoom) {
    final point = input.clamped();
    final size = worldSize(zoom);
    final sinLat = math.sin(point.latitude * math.pi / 180);
    final x = size * (point.longitude + 180) / 360;
    final y =
        size * (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi));
    return Offset(x, y);
  }
}
