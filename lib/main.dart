import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // <-- Nuevo import
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'database_helper.dart';
import 'pantalla_sincronizacion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const InventarioApp());
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario Offline',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PantallaCaptura(),
    );
  }
}

class PantallaCaptura extends StatefulWidget {
  const PantallaCaptura({super.key});

  @override
  State<PantallaCaptura> createState() => _PantallaCapturaState();
}

class _PantallaCapturaState extends State<PantallaCaptura> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  Future<void> _guardarProducto() async {
    final codigo = _codigoController.text;
    final cantidad = _cantidadController.text;

    if (codigo.isEmpty || cantidad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena ambos campos')),
      );
      return;
    }

    Map<String, dynamic> nuevoProducto = {
      'codigo': codigo,
      'cantidad': int.parse(cantidad),
    };

    final dbHelper = DatabaseHelper();
    await dbHelper.insertarProducto(nuevoProducto);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guardado en base de datos local'),
          backgroundColor: Colors.green,
        ),
      );
    }

    _codigoController.clear();
    _cantidadController.clear();
  }

  // --- NUEVA FUNCIÓN PARA ABRIR LA CÁMARA ---
  Future<void> _abrirEscaner() async {
    // Esperamos el resultado que devuelva la pantalla del escáner
    final String? codigoEscaneado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LectorCodigoPantalla()),
    );

    // Si detectó un código (no canceló volviendo atrás), lo asignamos al input
    if (codigoEscaneado != null && mounted) {
      setState(() {
        _codigoController.text = codigoEscaneado;
      });
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturar Producto'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PantallaSincronizacion()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- FILA CON INPUT Y BOTÓN DE CÁMARA ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigoController,
                    decoration: const InputDecoration(
                      labelText: 'Código de Barras',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _abrirEscaner,
                  icon: const Icon(Icons.camera_alt),
                  iconSize: 32,
                  padding: const EdgeInsets.all(12),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardarProducto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Guardar Localmente',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- NUEVA PANTALLA DE ESCÁNER A PANTALLA COMPLETA ---
class LectorCodigoPantalla extends StatefulWidget {
  const LectorCodigoPantalla({super.key});

  @override
  State<LectorCodigoPantalla> createState() => _LectorCodigoPantallaState();
}

class _LectorCodigoPantallaState extends State<LectorCodigoPantalla> {
  // Bandera para evitar que lea el mismo código varias veces seguidas de golpe
  bool _codigoDetectado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Producto'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_codigoDetectado) return; // Si ya lo leyó, ignorar el resto

          final List<Barcode> barcodes = capture.barcodes;

          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            _codigoDetectado = true; // Bloqueamos nuevas lecturas
            final String codigoFinal = barcodes.first.rawValue!;

            // Regresamos a la pantalla anterior pasándole el código detectado
            Navigator.pop(context, codigoFinal);
          }
        },
      ),
    );
  }
}