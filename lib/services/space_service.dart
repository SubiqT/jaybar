import 'dart:async';
import '../models/space.dart';

abstract class SpaceService {
  Stream<List<Space>> get spaceStream;
  
  Future<void> start();
  Future<void> switchToSpace(int index);
  void dispose();
}
