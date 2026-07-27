import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_helper.dart';
import 'api_service.dart'; // Importamos el servicio centralizado

class PantallaSincronizacion extends StatefulWidget {
  const PantallaSincronizacion({super.key});

  @override
  State<PantallaSincronizacion> createState() => _PantallaSincronizacionState();
}

class _PantallaSincronizacionState extends State<PantallaSincronizacion> {
  List<Map<String, dynamic>> _productos = [];
  bool _hayConexion = false;
  bool _estaCargando = false; // Estado para dar feedback visual al sincronizar

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

    setState(() {
      _estaCargando = true;
    });

    try {
      // Usamos el ApiService que creamos
      final apiService = ApiService();
      await apiService.sincronizarInventario(_productos);

      // Si no lanza excepción, asumimos éxito -> limpiamos la base local
      final dbHelper = DatabaseHelper();
      await dbHelper.vaciarInventario();
      await _cargarDatos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventario sincronizado en el servidor'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al sincronizar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _estaCargando = false;
        });
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
              child: _productos.isEmpty
                  ? const Center(
                child: Text('No hay registros pendientes por sincronizar'),
              )
                  : ListView.builder(
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
                  onPressed: (_productos.isEmpty || _estaCargando) ? null : _sincronizar,
                  icon: _estaCargando
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_estaCargando ? 'Sincronizando...' : 'Subir ${_productos.length} registros'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}