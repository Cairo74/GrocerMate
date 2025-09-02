import 'package:flutter/material.dart';
import 'package:grocermate/screens/create_post_screen.dart';
import 'package:grocermate/screens/create_template_screen.dart';
import 'package:grocermate/widgets/blog_feed.dart';
import 'package:grocermate/widgets/modern_app_bar.dart';
import 'package:grocermate/widgets/template_feed.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<BlogFeedState> _blogFeedKey = GlobalKey<BlogFeedState>();
  final GlobalKey<TemplateFeedState> _templateFeedKey = GlobalKey<TemplateFeedState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Add a listener to rebuild the widget when the tab changes, so the FAB can be shown/hidden
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Community',
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.article), text: 'Blog'),
              Tab(icon: Icon(Icons.grid_view_rounded), text: 'Templates'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                BlogFeed(key: _blogFeedKey),
                TemplateFeed(key: _templateFeedKey),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    if (_tabController.index == 0) { // Blog tab
      return FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
          if (result == true) {
            _blogFeedKey.currentState?.refreshFeed();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Post',
      );
    } else if (_tabController.index == 1) { // Templates tab
      return FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const CreateTemplateScreen()),
          );
          if (result == true) {
            _templateFeedKey.currentState?.refreshFeed();
          }
        },
        child: const Icon(Icons.post_add_rounded),
        tooltip: 'Create Template',
      );
    }
    return null;
  }
} 