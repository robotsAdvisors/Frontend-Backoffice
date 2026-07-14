import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:8000/api", // ajustá la URL de tu backend
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  /// -------------------------
  /// CAMPAÑAS
  /// -------------------------
  Future<Response> createCampaign(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/campaigns/", data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getCampaigns() async {
    try {
      final response = await _dio.get("/campaigns/");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> updateCampaign(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put("/campaigns/$id/", data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> deleteCampaign(int id) async {
    try {
      final response = await _dio.delete("/campaigns/$id/");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// -------------------------
  /// TICKETS
  /// -------------------------
  Future<Response> getTickets() async {
    try {
      final response = await _dio.get("/tickets/");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> approveTicket(int id) async {
    try {
      final response = await _dio.post("/tickets/$id/approve/");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> rejectTicket(int id) async {
    try {
      final response = await _dio.post("/tickets/$id/reject/");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// -------------------------
  /// DISPUTAS STRIPE
  /// -------------------------
  Future<Response> getDisputes() async {
    try {
      final response = await _dio.get("/disputes/");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> openDispute(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/disputes/", data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> resolveDispute(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/disputes/$id/resolve/", data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
