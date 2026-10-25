import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserService {
  static const String baseUrl = 'https://reqres.in/api';

  // API key ReqRes (dari dialog "Your API key").
  static const String apiKey = 'free_user_3LAkzI7ky4CRCeROOpEWLXlG4ro';

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'x-api-key': apiKey,
  };

  // Membaca pesan error dari server
  String _getErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        return data['message']?.toString() ??
            data['error']?.toString() ??
            body;
      }
      return body;
    } catch (_) {
      return body;
    }
  }

  // GET: mengambil daftar user
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/users?page=1'),
        headers: headers,
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil user. HTTP ${response.statusCode}: '
              '${_getErrorMessage(response.body)}',
        );
      }

      final Map<String, dynamic> result =
      jsonDecode(response.body) as Map<String, dynamic>;

      final List<dynamic> users = result['data'] as List<dynamic>;

      return users
          .map(
            (user) => UserModel.fromJson(
          user as Map<String, dynamic>,
        ),
      )
          .toList();
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw Exception('Server terlalu lama merespons. Coba lagi.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server ReqRes.');
    } on FormatException {
      throw Exception('Format data dari server tidak valid.');
    }
  }

  // POST: membuat user
  Future<Map<String, dynamic>> createUser({
    required String name,
    required String job,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/users'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'job': job,
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 201) {
        throw Exception(
          'Gagal membuat user. HTTP ${response.statusCode}: '
              '${_getErrorMessage(response.body)}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw Exception('Permintaan terlalu lama. Coba lagi.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server ReqRes.');
    } on FormatException {
      throw Exception('Format respons server tidak valid.');
    }
  }

  // PUT: memperbarui user
  Future<Map<String, dynamic>> updateUser({
    required int id,
    required String name,
    required String job,
  }) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'job': job,
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal memperbarui user. HTTP ${response.statusCode}: '
              '${_getErrorMessage(response.body)}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw Exception('Permintaan terlalu lama. Coba lagi.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server ReqRes.');
    } on FormatException {
      throw Exception('Format respons server tidak valid.');
    }
  }

  // DELETE: menghapus user
  Future<void> deleteUser(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 204) {
        throw Exception(
          'Gagal menghapus user. HTTP ${response.statusCode}: '
              '${_getErrorMessage(response.body)}',
        );
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw Exception('Permintaan terlalu lama. Coba lagi.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server ReqRes.');
    }
  }
}