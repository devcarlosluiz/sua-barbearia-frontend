import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/paginated.dart';
import '../models/product.dart';
import 'core_providers.dart';

class ProductFilter {
  const ProductFilter(
      {this.page = 1, this.search, this.categoryId, this.isActive});

  final int page;
  final String? search;
  final int? categoryId;
  final bool? isActive;

  ProductFilter copyWith({
    int? page,
    String? search,
    int? categoryId,
    bool? isActive,
    bool clearCategory = false,
    bool clearActive = false,
  }) {
    return ProductFilter(
      page: page ?? this.page,
      search: search ?? this.search,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      isActive: clearActive ? null : (isActive ?? this.isActive),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProductFilter &&
      other.page == page &&
      other.search == search &&
      other.categoryId == categoryId &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(page, search, categoryId, isActive);
}

final productFilterProvider =
    StateProvider<ProductFilter>((ref) => const ProductFilter());

final productsProvider = FutureProvider<Paginated<Product>>((ref) {
  final filter = ref.watch(productFilterProvider);
  return ref.watch(inventoryRepositoryProvider).products(
        page: filter.page,
        search: filter.search,
        categoryId: filter.categoryId,
        isActive: filter.isActive,
      );
});

/// Catálogo completo, usado nos seletores de venda.
final activeProductsProvider = FutureProvider<List<Product>>((ref) async {
  final page = await ref
      .watch(inventoryRepositoryProvider)
      .products(pageSize: 100, isActive: true);
  return page.results;
});

final stockBranchFilterProvider = StateProvider<int?>((ref) => null);

/// Página atual da listagem de saldos de estoque.
final stockPageProvider = StateProvider<int>((ref) {
  // Trocar de filial volta para a primeira página.
  ref.watch(stockBranchFilterProvider);
  return 1;
});

final stockProvider = FutureProvider<Paginated<StockItem>>((ref) {
  final branchId = ref.watch(stockBranchFilterProvider);
  final page = ref.watch(stockPageProvider);
  return ref
      .watch(inventoryRepositoryProvider)
      .stock(branchId: branchId, page: page);
});

final lowStockProvider = FutureProvider<List<StockItem>>((ref) {
  final branchId = ref.watch(stockBranchFilterProvider);
  return ref.watch(inventoryRepositoryProvider).lowStock(branchId: branchId);
});

final stockMovementsProvider = FutureProvider<Paginated<StockMovement>>((ref) {
  final branchId = ref.watch(stockBranchFilterProvider);
  return ref.watch(inventoryRepositoryProvider).movements(branchId: branchId);
});

final salesProvider = FutureProvider<Paginated<Sale>>((ref) {
  final branchId = ref.watch(stockBranchFilterProvider);
  return ref.watch(inventoryRepositoryProvider).sales(branchId: branchId);
});

/// Carrinho da venda em edição (PDV).
class CartController extends StateNotifier<List<CartLine>> {
  CartController() : super(const []);

  void add(Product product, {int quantity = 1}) {
    final index = state.indexWhere((line) => line.product.id == product.id);
    if (index >= 0) {
      final updated = [...state];
      updated[index] =
          updated[index].copyWith(quantity: updated[index].quantity + quantity);
      state = updated;
      return;
    }
    state = [...state, CartLine(product: product, quantity: quantity)];
  }

  void setQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    state = [
      for (final line in state)
        if (line.product.id == productId)
          line.copyWith(quantity: quantity)
        else
          line,
    ];
  }

  void remove(int productId) {
    state = state.where((line) => line.product.id != productId).toList();
  }

  void clear() => state = const [];

  double get total => state.fold(0, (sum, line) => sum + line.total);

  int get itemCount => state.fold(0, (sum, line) => sum + line.quantity);
}

final cartProvider = StateNotifierProvider<CartController, List<CartLine>>(
  (ref) => CartController(),
);

final cartTotalProvider = Provider<double>((ref) {
  final lines = ref.watch(cartProvider);
  return lines.fold<double>(0, (sum, line) => sum + line.total);
});
