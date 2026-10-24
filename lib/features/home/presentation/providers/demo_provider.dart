import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/demo_model.dart';

final demoListProvider = Provider<List<DemoItem>>((ref) {
  return const [
    DemoItem(
      id: 'demo_1',
      title: 'Demo 1: Foundations',
      questions: 10,
      minutes: 15,
      subdiscipline: 'Core Fundamentals',
      level: 'Beginner',
    ),
    DemoItem(
      id: 'demo_2',
      title: 'Demo 2: Practical Applications',
      questions: 15,
      minutes: 20,
      subdiscipline: 'Applied Concepts',
      level: 'Intermediate',
    ),
  ];
});

class SelectedDemoNotifier extends Notifier<DemoItem?> {
  @override
  DemoItem? build() => null;

  void selectDemo(DemoItem? demo) {
    state = demo;
  }
}

final selectedDemoProvider =
    NotifierProvider<SelectedDemoNotifier, DemoItem?>(SelectedDemoNotifier.new);
