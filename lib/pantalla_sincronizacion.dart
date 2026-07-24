import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PantallaSincronizacion extends StatefulWidget {
  const PantallaSincronizacion({super.key});

  @override
  State<PantallaSincronizacion> createState() => _PantallaSincronizacionState();
}

class _PantallaSincronizacionState extends State<PantallaSincronizacion> {
  List<Map<String, dynamic>> _productos = [];
  bool _hayConexion = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _verificarConexion();
  }

  Future<void> _cargarDatos() async {
    final dbHelper = DatabaseHelper();
    final datos = await dbHelper.obtenerProductos();
    setState(() {
      _productos = datos;
    });
  }

  Future<void> _verificarConexion() async {
    final resultados = await Connectivity().checkConnectivity();
    setState(() {
      _hayConexion = !resultados.contains(ConnectivityResult.none);
    });
  }

  Future<void> _sincronizar() async {
    await _verificarConexion();

    if (!_hayConexion) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay conexión a la red'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      // 1. Obtenemos la URL base desde el archivo .env
      final String baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/api';

      // 2. Construimos la ruta completa y la convertimos a un objeto Uri
      final url = Uri.parse('$baseUrl/sincronizar-inventario');

      // 3. Hacemos la petición POST enviando la lista de productos
      final response = await http.post(
        url, // Ahora sí reconoce la variable 'url' en formato Uri
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'productos': _productos}),
      );

      // 3. Si Laravel responde con un 200 OK, borramos la base local
      if (response.statusCode == 200) {
        final dbHelper = DatabaseHelper();
        await dbHelper.vaciarInventario();
        await _cargarDatos();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inventario sincronizado en el servidor'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Error en el servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al sincronizar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronizar Datos'),
        actions: [
          Icon(
            _hayConexion ? Icons.wifi : Icons.wifi_off,
            color: _hayConexion ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _productos.length,
                itemBuilder: (context, index) {
                  final prod = _productos[index];
                  return ListTile(
                    leading: const Icon(Icons.inventory_2),
                    title: Text('Código: ${prod['codigo']}'),
                    subtitle: Text('Cantidad: ${prod['cantidad']}'),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _productos.isEmpty ? null : _sincronizar,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text('Subir ${_productos.length} registros'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}