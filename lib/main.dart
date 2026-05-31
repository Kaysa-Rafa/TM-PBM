import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'detail.dart';
import 'add_data.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRUD Pegawai',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: SplashScreen(),
    );
  }
}

// ---------- SPLASH SCREEN ----------
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Data Pegawai',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Ganti IP ini sesuai dengan IP server Anda
  final String baseUrl = 'http://192.168.x.x/crud_pegawai/';
  List<Map<String, dynamic>> pegawaiList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('${baseUrl}read.php'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        pegawaiList = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _deleteData(int id) async {
    await http.delete(Uri.parse('${baseUrl}delete.php?id=$id'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Pegawai'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddDataPage()),
          );
          if (result == true) _fetchData();
        },
        icon: Icon(Icons.add),
        label: Text('Tambah'),
        backgroundColor: Colors.teal,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : pegawaiList.isEmpty
            ? Center(child: Text('Belum ada data pegawai'))
            : ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: pegawaiList.length,
          itemBuilder: (context, index) {
            final peg = pegawaiList[index];
            return Card(
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, color: Colors.teal),
                ),
                title: Text(peg['nama'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(peg['posisi'] ?? ''),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPage(pegawai: peg),
                    ),
                  );
                  if (result == true) _fetchData();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}