import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comic.dart';
import '../models/series.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.21:8000/api';

  // Series endpoints
  static Future<List<Series>> getSeries() async {
    try {
      final headers = await AuthService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/series'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> seriesJson = jsonData['data'];

        return seriesJson.map((json) => Series.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to load series');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Series> getSeriesById(int id) async {
    try {
      final headers = await AuthService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/series/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Series.fromJson(jsonData['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to load series');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Comics endpoints
  static Future<List<Comic>> getComics() async {
    try {
      final headers = await AuthService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/comics'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> comicsJson = jsonData['data'];

        return comicsJson.map((json) => Comic.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to load comics');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Comic> getComic(int id) async {
    try {
      final headers = await AuthService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/comics/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Comic.fromJson(jsonData['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to load comic');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<Comic>> getComicsBySeries(int seriesId) async {
    try {
      final headers = await AuthService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/series/$seriesId/comics'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> comicsJson = jsonData['data'];

        return comicsJson.map((json) => Comic.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to load comics');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<Series>> getFavorites() async {
    try {
      final headers = await AuthService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/favorites'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> seriesJson = jsonData['data'];

        return seriesJson.map((json) => Series.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to load favorites');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<bool> toggleFavorite(int seriesId) async {
    try {
      final headers = await AuthService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/$seriesId/toggle'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['is_favorite'] ?? false;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to toggle favorite');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<bool> checkFavorite(int seriesId) async {
    try {
      final headers = await AuthService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/favorites/$seriesId/check'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['is_favorite'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}