import 'package:flutter/material.dart';

import 'admin_categories_tab.dart';
import 'admin_services_tab.dart';

class AdminServicesScreen extends StatelessWidget {
  const AdminServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Services'),
          bottom: const TabBar(tabs: [Tab(text: 'Categories'), Tab(text: 'Services')]),
        ),
        body: const TabBarView(
          children: [AdminCategoriesTab(), AdminServicesTab()],
        ),
      ),
    );
  }
}
