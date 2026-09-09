import 'package:flutter/material.dart';

import 'working_hours_tab.dart';
import 'time_off_tab.dart';

class NurseAvailabilityScreen extends StatelessWidget {
  const NurseAvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Availability'),
          bottom: const TabBar(tabs: [Tab(text: 'Working Hours'), Tab(text: 'Time Off')]),
        ),
        body: const TabBarView(children: [WorkingHoursTab(), TimeOffTab()]),
      ),
    );
  }
}
