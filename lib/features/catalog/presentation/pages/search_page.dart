import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  final List<Map<String, dynamic>> _allArticles = [
    {'titre': 'Robe longue', 'prix': 5000, 'image': Icons.checkroom},
    {'titre': 'Nike Air Max', 'prix': 25000, 'image': Icons.sports_football},
    {'titre': 'Sac à main', 'prix': 15000, 'image': Icons.wallet},
    {'titre': 'Montre Casio', 'prix': 10000, 'image': Icons.watch},
    {'titre': 'Jean slim', 'prix': 8000, 'image': Icons.checkroom},
    {'titre': 'Veste en cuir', 'prix': 20000, 'image': Icons.checkroom},
  ];

  void _search(String query) {
    setState(() {
      _results = _allArticles
          .where((a) =>
              (a['titre'] as String)
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go(RouteNames.catalog),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _search,
          decoration: const InputDecoration(
            hintText: 'Rechercher un article...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Tapez pour rechercher'
                        : 'Aucun résultat trouvé',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final article = _results[index];
                return GestureDetector(
                  onTap: () => context.go('/product/$index'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            article['image'] as IconData,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article['titre'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${article['prix']} FCFA',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}