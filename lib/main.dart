import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';  // Added this import
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Station',
      debugShowCheckedModeBanner: false, // Removes debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebSocketChannel? channel;
  double temperature = 0;
  double humidity = 0;
  double pressure = 0;
  double altitude = 0;
  String rainfall = "No Rainfall";
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  void connectWebSocket() {
    try {
      setState(() {
        isConnected = false;
      });
      channel = IOWebSocketChannel.connect(
        'ws://192.168.233.191:81',
        pingInterval: const Duration(seconds: 1),
      );
      setState(() {
        isConnected = true;
      });
      channel!.stream.listen(
        (dynamic data) {
          try {
            final parsedData = jsonDecode(data.toString());
            print('Received data: $parsedData'); // Debug print
            setState(() {
              temperature = double.tryParse(parsedData['temp'].toString()) ?? temperature;
              humidity = double.tryParse(parsedData['humidity'].toString()) ?? humidity;
              pressure = double.tryParse(parsedData['pressure'].toString()) ?? pressure;
              altitude = double.tryParse(parsedData['altitude'].toString()) ?? altitude;
              rainfall = parsedData['rainfall']?.toString() ?? rainfall;
            });
          } catch (e) {
            print('Error parsing data: $e');
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
          setState(() {
            isConnected = false;
          });
          // Attempt to reconnect after error
          Future.delayed(const Duration(seconds: 2), connectWebSocket);
        },
        onDone: () {
          print('WebSocket connection closed');
          setState(() {
            isConnected = false;
          });
          // Attempt to reconnect when connection closes
          Future.delayed(const Duration(seconds: 2), connectWebSocket);
        },
      );
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      setState(() {
        isConnected = false;
      });
      // Attempt to reconnect on connection error
      Future.delayed(const Duration(seconds: 2), connectWebSocket);
    }
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/weather_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Connection Status & Date header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'October 24 Thursday',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConnected ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pune',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Temperature display
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              temperature.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              '°C',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rainfall,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Curved container with bottom cards
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Pressure',
                                  '${pressure.toStringAsFixed(1)} hPa',
                                  Colors.blue.shade100,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  'Altitude',
                                  '${altitude.toStringAsFixed(1)} m',
                                  Colors.purple.shade100,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  'Humidity',
                                  '${humidity.toStringAsFixed(1)}%',
                                  Colors.green.shade100,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Reconnection button (only shows when disconnected)
          if (!isConnected)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: connectWebSocket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  child: const Text('Reconnect'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}



























// // main.dart
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';  // Add this import
// import 'dart:convert';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Weather Station',
//       debugShowCheckedModeBanner: false,  // Removes debug banner
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   WebSocketChannel? channel;
//   double temperature = 0;
//   double humidity = 0;
//   double pressure = 0;
//   double altitude = 0;
//   String rainfall = "No Rainfall";
//   bool isConnected = false;

//   @override
//   void initState() {
//     super.initState();
//     connectWebSocket();
//   }

//   void connectWebSocket() {
//     try {
//       setState(() {
//         isConnected = false;
//       });

//       channel = IOWebSocketChannel.connect(
//         'ws://192.168.233.191:81',
//         pingInterval: const Duration(seconds: 1),
//       );
      
//       setState(() {
//         isConnected = true;
//       });

//       channel!.stream.listen(
//         (dynamic data) {
//           try {
//             final parsedData = jsonDecode(data.toString());
//             print('Received data: $parsedData'); // Debug print

//             setState(() {
//               temperature = double.tryParse(parsedData['temp'].toString()) ?? temperature;
//               humidity = double.tryParse(parsedData['humidity'].toString()) ?? humidity;
//               pressure = double.tryParse(parsedData['pressure'].toString()) ?? pressure;
//               altitude = double.tryParse(parsedData['altitude'].toString()) ?? altitude;
//               rainfall = parsedData['rainfall']?.toString() ?? rainfall;
//             });
//           } catch (e) {
//             print('Error parsing data: $e');
//           }
//         },
//         onError: (error) {
//           print('WebSocket Error: $error');
//           setState(() {
//             isConnected = false;
//           });
//           // Attempt to reconnect after error
//           Future.delayed(const Duration(seconds: 2), connectWebSocket);
//         },
//         onDone: () {
//           print('WebSocket connection closed');
//           setState(() {
//             isConnected = false;
//           });
//           // Attempt to reconnect when connection closes
//           Future.delayed(const Duration(seconds: 2), connectWebSocket);
//         },
//       );
//     } catch (e) {
//       print('Error connecting to WebSocket: $e');
//       setState(() {
//         isConnected = false;
//       });
//       // Attempt to reconnect on connection error
//       Future.delayed(const Duration(seconds: 2), connectWebSocket);
//     }
//   }

//   @override
//   void dispose() {
//     channel?.sink.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Container(
//             width: double.infinity,
//             height: double.infinity,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('assets/images/weather_bg.jpg'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   // Connection Status & Date header
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           'October 24 Thursday',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 20,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         Row(
//                           children: [
//                             Container(
//                               width: 8,
//                               height: 8,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: isConnected ? Colors.green : Colors.red,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               'Pune',
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.8),
//                                 fontSize: 16,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Temperature display
//                   Expanded(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               temperature.toStringAsFixed(1),
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 72,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const Text(
//                               '°C',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           rainfall,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Curved container with bottom cards
//                   Container(
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(30),
//                         topRight: Radius.circular(30),
//                       ),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(20.0),
//                       child: Column(
//                         children: [
//                           const SizedBox(height: 10),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildMetricCard(
//                                   'Pressure',
//                                   '${pressure.toStringAsFixed(1)} hPa',
//                                   Colors.blue.shade100,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: _buildMetricCard(
//                                   'Altitude',
//                                   '${altitude.toStringAsFixed(1)} m',
//                                   Colors.purple.shade100,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: _buildMetricCard(
//                                   'Humidity',
//                                   '${humidity.toStringAsFixed(1)}%',
//                                   Colors.green.shade100,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // Reconnection button (only shows when disconnected)
//           if (!isConnected)
//             Positioned(
//               top: MediaQuery.of(context).padding.top + 60,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: ElevatedButton(
//                   onPressed: connectWebSocket,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     foregroundColor: Colors.blue,
//                   ),
//                   child: const Text('Reconnect'),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMetricCard(String title, String value, Color backgroundColor) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 2,
//             blurRadius: 5,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               color: Colors.grey[800],
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.black87,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }































// // main.dart
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'dart:convert';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Weather Station',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   WebSocketChannel? channel;
//   double temperature = 12;
//   double rainfall = 0;
//   double pressure = 1003;
//   double humidity = 94;
//   double windSpeed = 7;

//   @override
//   void initState() {
//     super.initState();
//     connectWebSocket();
//   }

//   void connectWebSocket() {
//     try {
//       channel = WebSocketChannel.connect(
//         Uri.parse('ws://192.168.233.191:81'), // Replace with your ESP8266 WebSocket URL
//       );
      
//       channel!.stream.listen(
//         (data) {
//           // Parse the incoming data
//           final parsedData = jsonDecode(data);
//           setState(() {
//             temperature = parsedData['temperature']?.toDouble() ?? temperature;
//             rainfall = parsedData['rainfall']?.toDouble() ?? rainfall;
//             pressure = parsedData['pressure']?.toDouble() ?? pressure;
//             humidity = parsedData['humidity']?.toDouble() ?? humidity;
//             windSpeed = parsedData['windSpeed']?.toDouble() ?? windSpeed;
//           });
//         },
//         onError: (error) {
//           print('WebSocket Error: $error');
//           // Implement reconnection logic here if needed
//         },
//         onDone: () {
//           print('WebSocket connection closed');
//           // Implement reconnection logic here if needed
//         },
//       );
//     } catch (e) {
//       print('Error connecting to WebSocket: $e');
//     }
//   }

//   @override
//   void dispose() {
//     channel?.sink.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('assets/images/weather_bg.jpg'),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Date header
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'October 24 Thursday',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     Text(
//                       'Pune',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.8),
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Temperature display
//               Expanded(
//                 flex: 2,
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             temperature.toStringAsFixed(0),
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 72,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const Text(
//                             '°C',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 32,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Text(
//                         'Rainfall: ${rainfall.toStringAsFixed(1)} mm',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // Bottom cards
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: _buildMetricCard(
//                         'Wind',
//                         '$windSpeed m/s',
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: _buildMetricCard(
//                         'Pressure',
//                         '${pressure.toStringAsFixed(0)} hPa',
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: _buildMetricCard(
//                         'Humidity',
//                         '$humidity%',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMetricCard(String title, String value) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Column(
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }









// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/status.dart' as status;

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'ESP8266 Weather App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         brightness: Brightness.dark,
//       ),
//       home: WeatherScreen(),
//     );
//   }
// }

// class WeatherScreen extends StatefulWidget {
//   @override
//   _WeatherScreenState createState() => _WeatherScreenState();
// }

// class _WeatherScreenState extends State<WeatherScreen> {
//   late WebSocketChannel channel;
//   Map<String, dynamic> weatherData = {
//     "temp": 0.0,
//     "humidity": 0.0,
//     "pressure": 0.0,
//     "altitude": 0.0,
//     "rainfall": "No Rainfall",
//   };

//   @override
//   void initState() {
//     super.initState();
//     _connectWebSocket();
//   }

//   // Function to connect WebSocket
//   void _connectWebSocket() {
//     channel = WebSocketChannel.connect(
//       Uri.parse('ws://192.168.233.191:81'), // ESP8266 WebSocket server IP
//     );
//   }

//   // Manual reload function
//   void _reloadWeatherData() {
//     channel.sink.close(status.goingAway); // Close the existing connection
//     _connectWebSocket(); // Reconnect WebSocket
//   }

//   @override
//   void dispose() {
//     channel.sink.close(); // Ensure WebSocket is closed when app is disposed
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('ESP8266 Weather App'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _reloadWeatherData, // Reload WebSocket connection manually
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Expanded(
//               child: StreamBuilder(
//                 stream: channel.stream, // Listen to the WebSocket stream
//                 builder: (context, snapshot) {
//                   if (snapshot.hasError) {
//                     return Center(child: Text("Error: ${snapshot.error}"));
//                   }
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return Center(child: CircularProgressIndicator());
//                   }
//                   if (snapshot.hasData) {
//                     // Parse the JSON data received from ESP8266
//                     weatherData = jsonDecode(snapshot.data.toString());
//                     return Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           "${weatherData['temp'].toStringAsFixed(1)}°C",
//                           style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
//                         ),
//                         SizedBox(height: 16),
//                         Text("Humidity: ${weatherData['humidity']}%"),
//                         Text("Pressure: ${weatherData['pressure']} hPa"),
//                         Text("Altitude: ${weatherData['altitude']} m"),
//                         Text("Rainfall: ${weatherData['rainfall']}"),
//                         SizedBox(height: 20),
//                         _buildWeatherDetails(),
//                       ],
//                     );
//                   } else {
//                     return Center(child: Text('No Data Available'));
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Widget for weather details list
//   Widget _buildWeatherDetails() {
//     return Expanded(
//       child: ListView(
//         children: [
//           _buildWeatherDetail("Temperature", "${weatherData['temp']}°C"),
//           _buildWeatherDetail("Humidity", "${weatherData['humidity']}%"),
//           _buildWeatherDetail("Pressure", "${weatherData['pressure']} hPa"),
//           _buildWeatherDetail("Altitude", "${weatherData['altitude']} m"),
//           _buildWeatherDetail("Rainfall", "${weatherData['rainfall']}"),
//         ],
//       ),
//     );
//   }

//   Widget _buildWeatherDetail(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: TextStyle(fontSize: 18)),
//           Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }
// }


