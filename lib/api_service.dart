import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Función para enviar los datos al servidor
  Future<void> sincronizarInventario(List<Map<String, dynamic>> productosLocal) async {
    try {
      // 1. Obtenemos la IP de tu PC principal desde el archivo .env
      // Asegúrate de que en tu .env la variable sea algo como: API_URL=http://192.168.1.X:8000
      final String baseUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000';

      // Construimos la URL apuntando a la ruta exacta del backend
      final url = Uri.parse('$baseUrl/api/sincronizar-inventario');
      print('URL de destino: $url');

      // 2. Preparamos el cuerpo de la petición armando el JSON
      // productosLocal debe tener la estructura: [{"codigo": "123", "cantidad": 5}]
      final body = jsonEncode({
        'productos': productosLocal,
      });

      // 3. Disparamos la petición POST
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      // 4. Evaluamos la respuesta del servidor Laravel
      if (response.statusCode == 200) {
        print('Sincronización exitosa: ${response.body}');
        // TODO: Aquí podrías ejecutar la lógica para limpiar tu tabla SQLite
        // o cambiar el estado de los registros a "sincronizados".
      } else {
        print('Error del servidor: Código ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      print('Error de conexión o red: $e');
    }
  }
}