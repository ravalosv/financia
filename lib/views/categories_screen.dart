import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/category_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final categories = Get.find<CategoryController>();
  final auth = Get.find<AuthController>();
  String _query = '';
  final Map<String, IconData> _iconOptions = const {
    'category': Icons.category,
    'attach_money': Icons.attach_money,
    'work': Icons.work,
    'trending_up': Icons.trending_up,
    'business': Icons.business,
    'card_giftcard': Icons.card_giftcard,
    'more_horiz': Icons.more_horiz,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_cart': Icons.shopping_cart,
    'movie': Icons.movie,
    'receipt': Icons.receipt,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'flight': Icons.flight,
    'home': Icons.home,
    'spa': Icons.spa,
  };

  IconData _iconFromName(String name) => _iconOptions[name] ?? Icons.category;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCategoryForm({
    Category? initial,
    required String type,
  }) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    String currentType = type;
    String color = initial?.color ?? '#6B7280';
    String icon = initial?.icon ?? 'category';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      initial == null ? 'Nueva categoría' : 'Editar categoría',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Ingreso'),
                          selected: currentType == 'income',
                          onSelected: (_) =>
                              setModalState(() => currentType = 'income'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Egreso'),
                          selected: currentType == 'expense',
                          onSelected: (_) =>
                              setModalState(() => currentType = 'expense'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Color: $color',
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(_iconFromName(icon)),
                              const SizedBox(width: 6),
                              Text('Icono: $icon', style: AppTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _iconOptions.entries
                          .map(
                            (e) => ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(e.value, size: 18),
                                  const SizedBox(width: 6),
                                  Text(e.key),
                                ],
                              ),
                              selected: icon == e.key,
                              onSelected: (_) =>
                                  setModalState(() => icon = e.key),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          Get.snackbar('Validación', 'Ingresa un nombre');
                          return;
                        }
                        if (initial == null) {
                          await categories.createCustomCategory(
                            name: name,
                            type: currentType,
                            icon: icon,
                            color: color,
                          );
                        } else {
                          final updated = initial.copyWith(
                            name: name,
                            type: currentType,
                            color: color,
                            icon: icon,
                          );
                          await categories.updateCategory(updated);
                        }
                        if (mounted) Navigator.of(ctx).pop();
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildList(List<Category> data) {
    final list = _query.isEmpty
        ? data
        : data
              .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Sin categorías',
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final c = list[i];
        return Dismissible(
          key: Key('cat_${c.id}'),
          background: Container(
            color: AppTheme.successColor.withValues(alpha: 0.12),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Icon(Icons.edit, color: Colors.green),
                SizedBox(width: 8),
                Text('Editar'),
              ],
            ),
          ),
          secondaryBackground: Container(
            color: AppTheme.errorColor.withValues(alpha: 0.12),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text('Eliminar'),
                SizedBox(width: 8),
                Icon(Icons.delete, color: Colors.red),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _openCategoryForm(initial: c, type: c.type);
              return false;
            } else {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirmar eliminación'),
                  content: Text('¿Eliminar la categoría "${c.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await categories.deleteCategory(c.id);
                return true;
              }
              return false;
            }
          },
          child: ListTile(
            leading: Icon(_iconFromName(c.icon)),
            title: Text(c.name),
            subtitle: Text(c.type == 'income' ? 'Ingreso' : 'Egreso'),
            onTap: () => _openCategoryForm(initial: c, type: c.type),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final idx = _tabController.index;
              final type = idx == 1 ? 'income' : 'expense';
              _openCategoryForm(type: type);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Ingresos'),
            Tab(text: 'Egresos'),
          ],
        ),
      ),
      body: Obx(() {
        final incomes = categories.getIncomeCategories();
        final expenses = categories.getExpenseCategories();
        final all = categories.categories.toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar categoría',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 16),
              if (_tabController.index == 0)
                _buildList(all)
              else if (_tabController.index == 1)
                _buildList(incomes)
              else
                _buildList(expenses),
            ],
          ),
        );
      }),
    );
  }
}
