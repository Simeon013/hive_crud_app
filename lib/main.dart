import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('shopping_box');
  runApp(const MyApp());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Hive',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MyHomePage(title: 'Hive'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  List<Map<String, dynamic>> _items = [];

  final _shoppingBox = Hive.box('shopping_box');

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _refreshItems() {
    final data = _shoppingBox.keys.map((key) {
      final item = _shoppingBox.get(key);
      return {
        "key": key,
        "name": item['name'],
        "quantity": item['quantity'],
      };
    }).toList();
    setState(() {
      _items = data.reversed.toList();
      print(_items.length);
      //we use reversed to sort items in order from the latest to the oldest
    });
  }

  //Create new item
  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _shoppingBox.add(newItem);
    _refreshItems();
  }

  //Update item
  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    await _shoppingBox.put(itemKey, item);
    _refreshItems();
  }

  //Delete item
  Future<void> _deleteItem(int key) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      // false = user must tap button, true = tap outside dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Avertissement'),
          content: const Text('Voulez-vous supprimer cet élément ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Non'),
              onPressed:(){
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Oui'),
              onPressed: () async {
                await _shoppingBox.delete(key);
                _refreshItems();
                Navigator.of(dialogContext).pop(); // Dismiss alert dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _showForm(BuildContext ctx, int? itemKey) async {

    if (itemKey != null) {
      final item = _shoppingBox.get(itemKey);
      _nameController.text = item['name'];
      _quantityController.text = item['quantity'].toString();
    }

    showModalBottomSheet(
      context: ctx,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 15,
          left: 15,
          right: 15,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
              )
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
              )
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (itemKey == null) {
                  _createItem({
                    "name": _nameController.text,
                    "quantity": _quantityController.text
                  });
                }

                if (itemKey != null) {
                  _updateItem(itemKey, {
                    "name": _nameController.text.trim(),
                    "quantity": _quantityController.text.trim()
                  });

                }

                _nameController.text = '';
                _quantityController.text = '';

                Navigator.of(context).pop();
              },
              child: Text(itemKey==null? 'Save' : 'Update'),
            ),
            const SizedBox(height: 15),
          ],
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, index) {
          final item = _items[index];
          return Card(
            color: Colors.grey,
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: ListTile(
              title: Text(item['name']),
              subtitle: Text(item['quantity'].toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showForm(context, item['key']),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () => _deleteItem(item['key']),
                    icon: const Icon(Icons.delete),
                  )
                ]
              ),
            )
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
