import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // ENVÍO DE DATOS AL SERVIDOR
  Future<void> sincronizarInventario(List<Map<String, dynamic>> productosLocal) async {
    try {
      // OBTENER IP DESDE EL .ENV
      final String baseUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000';


      final url = Uri.parse('$baseUrl/api/sincronizar-inventario');
      print('URL de destino: $url'); // para checkear que la url sea la correcta. Tema de debugs :D

      // ARMADO DE JSON
      final body = jsonEncode({
        'productos': productosLocal,
      });

      // PETICION POST
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      // RESPONDE EL SERVIDOR LARAVEL?
      if (response.statusCode == 200) {
        print('Sincronización exitosa: ${response.body}');

      } else {
        print('Error del servidor: Código ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      print('Error de conexión o red: $e');
    }
  }
}