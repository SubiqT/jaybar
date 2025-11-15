import 'dart:async';
import '../models/space.dart';

abstract class SpaceService {
  Stream<List<Space>> get spaceStream;
  Duration get averagePollLatency;
  int get pollCount;
  
  Future<void> start();
  Future<void> switchToSpace(int index);
  void dispose();
}
