import 'package:fluency/core/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluency/features/home/presentation/pages/component_gallery_page.dart';

import '../widgets/home_content.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          const Expanded(child: HomeContent()),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Select Theme:',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return ListView.builder(
                  itemCount: themeProvider.availableThemes.length,
                  itemBuilder: (context, index) {
                    final themePath = themeProvider.availableThemes[index];
                    final themeName =
                        themePath.split('/').last.replaceAll('.json', '');
                    return ListTile(
                      title: Text(themeName),
                      subtitle: Text(themePath),
                      onTap: () {
                        themeProvider.loadTheme(themePath);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ComponentGalleryPage(),
            ),
          );
        },
        child: const Icon(Icons.widgets),
      ),
    );
  }
}
