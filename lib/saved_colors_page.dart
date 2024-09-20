import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // For clipboard functionality

class SavedColorsPage extends StatefulWidget {
  @override
  _SavedColorsPageState createState() => _SavedColorsPageState();
}

class _SavedColorsPageState extends State<SavedColorsPage> {
  List<String> _savedColors = [];

  @override
  void initState() {
    super.initState();
    _loadSavedColors();
  }

  Future<void> _loadSavedColors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedColors = prefs.getStringList('saved_colors') ?? [];
    });
  }

  Future<void> _deleteColor(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedColors = prefs.getStringList('saved_colors') ?? [];
    savedColors.removeAt(index);

    // Save the updated list to SharedPreferences
    await prefs.setStringList('saved_colors', savedColors);
  }

  void _copyColorToClipboard(String colorCode) {
    Clipboard.setData(ClipboardData(text: colorCode));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Color code $colorCode copied to clipboard!'),
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Colors'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: _savedColors.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.color_lens_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 10),
            Text(
              'No Saved Colors Yet!',
              style: TextStyle(
                fontSize: 22,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
          itemCount: _savedColors.length,
          itemBuilder: (context, index) {
          final colorData = _savedColors[index];
          final splitData = colorData.split(':');
          final colorName = splitData[0];
          final colorValues = splitData[1].split(',').map(int.parse).toList();
          final color = Color.fromARGB(255, colorValues[0], colorValues[1], colorValues[2]);
          final colorCode = 'RGB(${colorValues[0]}, ${colorValues[1]}, ${colorValues[2]})';

          return Dismissible(
            key: Key(colorName),
            direction: DismissDirection.endToStart,

            confirmDismiss: (direction) async {
              //confirmation dialog
              final bool res = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Confirm"),
                    content: Text("Are you sure you want to delete $colorName?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text("DELETE"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text("CANCEL"),
                      ),
                    ],
                  );
                },
              );
              return res;
            },

            // Handle the dismissal after confirmation
            onDismissed: (direction) {
              //remove the item from the list
              setState(() {
                _savedColors.removeAt(index);
              });

              // Then remove from SharedPreferences
              _deleteColor(index);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$colorName has been deleted.'),
                ),
              );
            },
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(
                Icons.delete,
                color: Colors.white,
                size: 30,
              ),
            ),
            child: GestureDetector(
              onTap: () => _copyColorToClipboard(colorCode),
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    colorName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    colorCode,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Icon(
                    Icons.copy,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
