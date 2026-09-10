import '../core/network/api_client.dart';
import '../core/network/paginated.dart';
import '../models/json_utils.dart';
import '../models/product.dart';

class InventoryRepository {
  const InventoryRepository(this._api);

  final ApiClient _api;

  // ------------------------------------------------------------------
  // Produtos
  // ------------------------------------------------------------------
  Future<Paginated<Product>> products({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? categoryId,
    bool? isActive,
  }) async {
    final data = await _api.get(
      '/products/',
      query: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null) 'category': categoryId,
        if (isActive != null) 'is_active': isActive,
      },
    );
    return Paginated.fromResponse<Product>(data, Product.fromJson);
  }

  Future<Product> product(int id) async {
    final data = await _api.get('/products/$id/');
    return Product.fromJson(Json.asMap(data));
  }

  Future<Product> createProduct(Map<String, dynamic> payload) async {
    final data = await _api.post('/products/', data: payload);
    return Product.fromJson(Json.asMap(data));
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> payload) async {
    final data = await _api.patch('/products/$id/', data: payload);
    return Product.fromJson(Json.asMap(data));
  }

  Future<void> deleteProduct(int id) => _api.delete('/products/$id/');

  // ------------------------------------------------------------------
  // Estoque
  // ------------------------------------------------------------------
  Future<Paginated<StockItem>> stock({
    int page = 1,
    int pageSize = 50,
    int? branchId,
    String? search,
    bool belowMinimum = false,
  }) async {
    final data = await _api.get(
      '/inventory/stock/',
      query: {
        'page': page,
        'page_size': pageSize,
        if (branchId != null) 'branch': branchId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (belowMinimum) 'below_minimum': 'true',
      },
    );
    return Paginated.fromResponse<StockItem>(data, StockItem.fromJson);
  }

  Future<List<StockItem>> lowStock({int? branchId}) async {
    final data = await _api.get(
      '/inventory/stock/low-stock/',
      query: {if (branchId != null) 'branch': branchId},
    );
    return Json.asMapList(data).map(StockItem.fromJson).toList();
  }

  Future<StockItem> updateMinimumStock(
      int stockItemId, int minimumStock) async {
    final data = await _api.patch(
      '/inventory/stock/$stockItemId/',
      data: {'minimum_stock': minimumStock},
    );
    return StockItem.fromJson(Json.asMap(data));
  }

  Future<Paginated<StockMovement>> movements({
    int page = 1,
    int pageSize = 20,
    int? productId,
    int? branchId,
    String? type,
  }) async {
    final data = await _api.get(
      '/inventory/movements/',
      query: {
        'page': page,
        'page_size': pageSize,
        if (productId != null) 'product': productId,
        if (branchId != null) 'branch': branchId,
        if (type != null) 'type': type,
      },
    );
    return Paginated.fromResponse<StockMovement>(data, StockMovement.fromJson);
  }

  Future<StockMovement> registerMovement({
    required int productId,
    required int branchId,
    required String type,
    required int quantity,
    double? unitCost,
    String reason = '',
  }) async {
    final data = await _api.post(
      '/inventory/movements/',
      data: {
        'product_id': productId,
        'branch_id': branchId,
        'type': type,
        'quantity': quantity,
        if (unitCost != null) 'unit_cost': unitCost.toStringAsFixed(2),
        if (reason.isNotEmpty) 'reason': reason,
      },
    );
    return StockMovement.fromJson(Json.asMap(data));
  }

  // ------------------------------------------------------------------
  // Vendas
  // ------------------------------------------------------------------
  Future<Paginated<Sale>> sales({
    int page = 1,
    int pageSize = 20,
    int? branchId,
    String? status,
  }) async {
    final data = await _api.get(
      '/sales/',
      query: {
        'page': page,
        'page_size': pageSize,
        if (branchId != null) 'branch': branchId,
        if (status != null) 'status': status,
      },
    );
    return Paginated.fromResponse<Sale>(data, Sale.fromJson);
  }

  Future<Sale> createSale({
    required int branchId,
    required List<CartLine> items,
    int? clientId,
    int? barberId,
    int? appointmentId,
    double discountAmount = 0,
    String? paymentMethod,
    String notes = '',
  }) async {
    final data = await _api.post(
      '/sales/',
      data: {
        'branch_id': branchId,
        'items': items.map((line) => line.toJson()).toList(),
        if (clientId != null) 'client_id': clientId,
        if (barberId != null) 'barber_id': barberId,
        if (appointmentId != null) 'appointment_id': appointmentId,
        'discount_amount': discountAmount.toStringAsFixed(2),
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    return Sale.fromJson(Json.asMap(data));
  }

  Future<Sale> completeSale(int saleId, String paymentMethod) async {
    final data = await _api.post(
      '/sales/$saleId/complete/',
      data: {'payment_method': paymentMethod},
    );
    return Sale.fromJson(Json.asMap(data));
  }

  Future<Sale> cancelSale(int saleId, {String reason = ''}) async {
    final data = await _api.post(
      '/sales/$saleId/cancel/',
      data: {if (reason.isNotEmpty) 'reason': reason},
    );
    return Sale.fromJson(Json.asMap(data));
  }
}
