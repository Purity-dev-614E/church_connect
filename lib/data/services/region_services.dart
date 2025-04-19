import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_endpoints.dart';
import '../models/region_model.dart';

class RegionServices {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  // Get all regions
  Future<List<RegionModel>> getRegions() async {
    try {
      final token = await secureStorage.read(key: 'accessToken');
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.regions),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> regionsData = data['data'] ?? [];
        
        return regionsData.map((region) => RegionModel.fromJson(region)).toList();
      } else {
        throw Exception('Failed to load regions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching regions: $e');
      return [];
    }
  }

  // Get region by ID
  Future<RegionModel?> getRegionById(String regionId) async {
    try {
      final token = await secureStorage.read(key: 'accessToken');
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.getRegionById(regionId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RegionModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to load region: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching region: $e');
      return null;
    }
  }

  // Create a new region (for super admin)
  Future<bool> createRegion(String name, String? description) async {
    try {
      final token = await secureStorage.read(key: 'accessToken');
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.regions),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error creating region: $e');
      return false;
    }
  }

  // Update a region (for super admin)
  Future<bool> updateRegion(String regionId, String name, String? description) async {
    try {
      final token = await secureStorage.read(key: 'accessToken');
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse(ApiEndpoints.updateRegion(regionId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating region: $e');
      return false;
    }
  }

  // Delete a region (for super admin)
  Future<bool> deleteRegion(String regionId) async {
    try {
      final token = await secureStorage.read(key: 'accessToken');
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse(ApiEndpoints.deleteRegion(regionId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting region: $e');
      return false;
    }
  }
}