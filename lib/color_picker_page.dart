import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ColorPickerPage extends StatefulWidget {
  @override
  _ColorPickerPageState createState() => _ColorPickerPageState();
}

class _ColorPickerPageState extends State<ColorPickerPage> {
  double _redValue = 0;
  double _greenValue = 0;
  double _blueValue = 0;
  String _colorName = "Black";

  // color based on RGB values
  Color _getCurrentColor() {
    return Color.fromARGB(255, _redValue.toInt(), _greenValue.toInt(), _blueValue.toInt());
  }

  //text color based on the brightness of the current color
  Color _getTextColor() {
    double brightness = (0.299 * _redValue + 0.587 * _greenValue + 0.114 * _blueValue);
    return brightness > 128 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.8;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppBar(
                  title: Text('Color Picker', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.blue.shade400,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.list, color: Colors.white),
                      onPressed: () {
                        Navigator.pushNamed(context, '/saved_colors');
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: FractionallySizedBox(
                    widthFactor: 0.9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getCurrentColor(),
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20.0,
                            offset: Offset(4, 8),
                          ),
                        ],
                        border: Border.all(
                          color: _getTextColor().withOpacity(0.7),
                          width: 3.0,
                        ),
                      ),
                      height: 180,
                      child: Center(
                        child: Text(
                          '$_colorName',
                          style: TextStyle(
                            color: _getTextColor(),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2.0,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _buildSlider('Red', _redValue, Colors.red, (value) {
                  setState(() {
                    _redValue = value;
                    _getColorName();
                  });
                }),
                _buildSlider('Green', _greenValue, Colors.green, (value) {
                  setState(() {
                    _greenValue = value;
                    _getColorName();
                  });
                }),
                _buildSlider('Blue', _blueValue, Colors.blue, (value) {
                  setState(() {
                    _blueValue = value;
                    _getColorName();
                  });
                }),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveColor,
                  child: Text('Save Color'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.black87,
                    minimumSize: Size(buttonWidth, 45),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _fetchRandomPalette,
                  child: Text('Get Random Palette'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black87,
                    minimumSize: Size(buttonWidth, 45),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label: ${value.toInt()}',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _saveColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final colorName = _colorName;
    final colorValue = '${_redValue.toInt()},${_greenValue.toInt()},${_blueValue.toInt()}';
    final savedColors = prefs.getStringList('saved_colors') ?? [];
    savedColors.add('$colorName:$colorValue');
    await prefs.setStringList('saved_colors', savedColors);
  }

  Future<void> _fetchRandomPalette() async {
    const url = 'http://colormind.io/api/';
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode({"model": "default"}),
    );
    if (response.statusCode == 200) {
      final List<dynamic> palette = jsonDecode(response.body)['result'];
      setState(() {
        _redValue = palette[0][0].toDouble();
        _greenValue = palette[0][1].toDouble();
        _blueValue = palette[0][2].toDouble();
        _getColorName();
      });
    } else {
      throw Exception('Failed to load palette');
    }
  }

  Future<void> _getColorName() async {
    final url = 'https://www.thecolorapi.com/id?rgb=${_redValue.toInt()},${_greenValue.toInt()},${_blueValue.toInt()}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        _colorName = data['name']['value'];
      });
    } else {
      setState(() {
        _colorName = 'Unknown';
      });
    }
  }
}
