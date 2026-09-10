import 'json_utils.dart';

class BranchStock {
  const BranchStock({
    required this.branchId,
    required this.branchName,
    required this.quantity,
    required this.minimumStock,
    required this.isBelowMinimum,
  });

  final int branchId;
  final String branchName;
  final int quantity;
  final int minimumStock;
  final bool isBelowMinimum;

  factory BranchStock.fromJson(Map<String, dynamic> json) => BranchStock(
        branchId: Json.asInt(json['branch_id']),
        branchName: Json.asString(json['branch_name']),
        quantity: Json.asInt(json['quantity']),
        minimumStock: Json.asInt(json['minimum_stock']),
        isBelowMinimum: Json.asBool(json['is_below_minimum']),
      );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.salePrice,
    this.uuid = '',
    this.description = '',
    this.barcode = '',
    this.categoryId,
    this.categoryName,
    this.costPrice = 0,
    this.margin = 0,
    this.commissionPercentage = 0,
    this.unit = 'UN',
    this.imageUrl,
    this.isActive = true,
    this.totalStock = 0,
    this.stockByBranch = const [],
  });

  final int id;
  final String uuid;
  final String name;
  final String description;
  final String sku;
  final String barcode;
  final int? categoryId;
  final String? categoryName;
  final double costPrice;
  final double salePrice;
  final double margin;
  final double commissionPercentage;
  final String unit;
  final String? imageUrl;
  final bool isActive;
  final int totalStock;
  final List<BranchStock> stockByBranch;

  int stockAt(int branchId) => stockByBranch
      .where((item) => item.branchId == branchId)
      .fold(0, (sum, item) => sum + item.quantity);

  bool get hasLowStock => stockByBranch.any((item) => item.isBelowMinimum);

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        name: Json.asString(json['name']),
        description: Json.asString(json['description']),
        sku: Json.asString(json['sku']),
        barcode: Json.asString(json['barcode']),
        categoryId: Json.asIntOrNull(json['category']),
        categoryName: Json.asStringOrNull(json['category_name']),
        costPrice: Json.asDouble(json['cost_price']),
        salePrice: Json.asDouble(json['sale_price']),
        margin: Json.asDouble(json['margin']),
        commissionPercentage: Json.asDouble(json['commission_percentage']),
        unit: Json.asString(json['unit'], fallback: 'UN'),
        imageUrl: Json.asStringOrNull(json['image_url']),
        isActive: Json.asBool(json['is_active'], fallback: true),
        totalStock: Json.asInt(json['total_stock']),
        stockByBranch: Json.asMapList(json['stock_by_branch'])
            .map(BranchStock.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'sku': sku,
        'barcode': barcode,
        'category': categoryId,
        'cost_price': costPrice.toStringAsFixed(2),
        'sale_price': salePrice.toStringAsFixed(2),
        'commission_percentage': commissionPercentage.toStringAsFixed(2),
        'unit': unit,
        'is_active': isActive,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class StockItem {
  const StockItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.branchId,
    required this.branchName,
    required this.quantity,
    required this.minimumStock,
    this.productSku = '',
    this.isBelowMinimum = false,
  });

  final int id;
  final int productId;
  final String productName;
  final String productSku;
  final int branchId;
  final String branchName;
  final int quantity;
  final int minimumStock;
  final bool isBelowMinimum;

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        id: Json.asInt(json['id']),
        productId: Json.asInt(json['product']),
        productName: Json.asString(json['product_name']),
        productSku: Json.asString(json['product_sku']),
        branchId: Json.asInt(json['branch']),
        branchName: Json.asString(json['branch_name']),
        quantity: Json.asInt(json['quantity']),
        minimumStock: Json.asInt(json['minimum_stock']),
        isBelowMinimum: Json.asBool(json['is_below_minimum']),
      );
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productName,
    required this.branchName,
    required this.type,
    required this.typeLabel,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    this.reason = '',
    this.createdByName,
    this.createdAt,
  });

  final int id;
  final String productName;
  final String branchName;
  final String type;
  final String typeLabel;
  final int quantity;
  final int previousQuantity;
  final int newQuantity;
  final String reason;
  final String? createdByName;
  final DateTime? createdAt;

  bool get isPositive => quantity >= 0;

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
        id: Json.asInt(json['id']),
        productName: Json.asString(json['product_name']),
        branchName: Json.asString(json['branch_name']),
        type: Json.asString(json['type']),
        typeLabel: Json.asString(json['type_display']),
        quantity: Json.asInt(json['quantity']),
        previousQuantity: Json.asInt(json['previous_quantity']),
        newQuantity: Json.asInt(json['new_quantity']),
        reason: Json.asString(json['reason']),
        createdByName: Json.asStringOrNull(json['created_by_name']),
        createdAt: Json.asDate(json['created_at']),
      );
}

class SaleItem {
  const SaleItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    final detail = Json.asMap(json['product_detail']);
    return SaleItem(
      id: Json.asInt(json['id']),
      productId: Json.asInt(json['product']),
      productName: Json.asString(detail['name']),
      quantity: Json.asInt(json['quantity']),
      unitPrice: Json.asDouble(json['unit_price']),
      total: Json.asDouble(json['total']),
    );
  }
}

class Sale {
  const Sale({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.status,
    required this.statusLabel,
    required this.subtotal,
    required this.total,
    this.branchName = '',
    this.clientName,
    this.barberName,
    this.discountAmount = 0,
    this.items = const [],
    this.completedAt,
    this.createdAt,
  });

  final int id;
  final String uuid;
  final int branchId;
  final String branchName;
  final String? clientName;
  final String? barberName;
  final String status;
  final String statusLabel;
  final double subtotal;
  final double discountAmount;
  final double total;
  final List<SaleItem> items;
  final DateTime? completedAt;
  final DateTime? createdAt;

  bool get isOpen => status == 'OPEN';

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: Json.asInt(json['id']),
        uuid: Json.asString(json['uuid']),
        branchId: Json.asInt(json['branch']),
        branchName: Json.asString(json['branch_name']),
        clientName: Json.asStringOrNull(json['client_name']),
        barberName: Json.asStringOrNull(json['barber_name']),
        status: Json.asString(json['status']),
        statusLabel: Json.asString(json['status_display']),
        subtotal: Json.asDouble(json['subtotal']),
        discountAmount: Json.asDouble(json['discount_amount']),
        total: Json.asDouble(json['total']),
        items: Json.asMapList(json['items']).map(SaleItem.fromJson).toList(),
        completedAt: Json.asDate(json['completed_at']),
        createdAt: Json.asDate(json['created_at']),
      );
}

/// Item do carrinho antes de enviar a venda ao backend.
class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get total => product.salePrice * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);

  Map<String, dynamic> toJson() => {
        'product_id': product.id,
        'quantity': quantity,
      };
}
