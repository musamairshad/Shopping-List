import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:shopping_list/data/dummy_items.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/data/project_id.dart';
import 'package:shopping_list/data/categories.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  // Before it was final.
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  // late Future<List<GroceryItem>> _loadedItems;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
    // _loadedItems = _loadItems();
  }

  // Before it was returning Future<List<GroceryItem>>.
  // Future<List<GroceryItem>> _loadItems() async {
  void _loadItems() async {
    final url = Uri.https(projectID, 'shopping-list.json');

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to load data. Please try again later.';
        });
        // throw Exception('Failed to fetch grocery items. Please try again later.');
      }

      // print(response.body);
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
        // return [];
      }

      // final Map<String, Map<String, dynamic>> listData =
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      // return loadedItems;
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
    // print(response.body);
    // print(response.statusCode);

    // print(response.body);

    // throw Exception('An error occurred!');
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    // _loadItems();
    // print(response);

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(projectID, 'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      // Optional : Show error message.
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  Future<void> refresh() async {
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text(
        'You got no items yet!',
        style: TextStyle(
          fontSize: 25.0,
        ),
      ),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = RefreshIndicator(
        onRefresh: refresh,
        child: ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (ctx, index) => Dismissible(
            key: ValueKey(_groceryItems[index].id),
            onDismissed: (direction) {
              _removeItem(_groceryItems[index]);
            },
            child: ListTile(
              title: Text(_groceryItems[index].name),
              leading: Container(
                width: 24.0,
                height: 24.0,
                color: _groceryItems[index].category.color,
              ),
              trailing: Text(
                _groceryItems[index].quantity.toString(),
              ),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      // ignore: unused_local_variable
      content = Center(
        child: Text(
          _error!,
          style: const TextStyle(
            fontSize: 17.0,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
      // body: FutureBuilder(
      //   future: _loadedItems,
      //   // _loadItems(),
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(
      //         child: CircularProgressIndicator(),
      //       );
      //     }

      //     if (snapshot.hasError) {
      //       return Center(
      //         child: Text(
      //           snapshot.error.toString(),
      //           style: const TextStyle(
      //             fontSize: 18.0,
      //           ),
      //         ),
      //       );
      //     }

      //     if (snapshot.data!.isEmpty) {
      //       return const Center(
      //         child: Text(
      //           'You got no items yet!',
      //           style: TextStyle(
      //             fontSize: 25.0,
      //           ),
      //         ),
      //       );
      //     }
      //     return RefreshIndicator(
      //       onRefresh: refresh,
      //       child: ListView.builder(
      //         itemCount: snapshot.data!.length,
      //         itemBuilder: (ctx, index) => Dismissible(
      //           key: ValueKey(snapshot.data![index].id),
      //           onDismissed: (direction) {
      //             _removeItem(snapshot.data![index]);
      //           },
      //           child: ListTile(
      //             title: Text(snapshot.data![index].name),
      //             leading: Container(
      //               width: 24.0,
      //               height: 24.0,
      //               color: snapshot.data![index].category.color,
      //             ),
      //             trailing: Text(
      //               snapshot.data![index].quantity.toString(),
      //             ),
      //           ),
      //         ),
      //       ),
      //     );
      //   },
      // ),
    );
  }
}
