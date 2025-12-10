import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/account_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/account_model.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final accounts = Get.find<AccountController>();
  final auth = Get.find<AuthController>();
  String _query = '';

  Future<bool> _confirmDeleteAccount(Account a) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar la cuenta "${a.name}"?'),
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
    return result ?? false;
  }

  Future<void> _openAccountForm({Account? initial}) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    String type = initial?.type ?? 'cash';
    String currency = initial?.currency ?? auth.currentUserCurrency;
    bool isActive = initial?.isActive ?? true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
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
                  initial == null ? 'Nueva cuenta' : 'Editar cuenta',
                  style: AppTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                    DropdownMenuItem(
                      value: 'checking',
                      child: Text('Cuenta corriente'),
                    ),
                    DropdownMenuItem(
                      value: 'savings',
                      child: Text('Caja de ahorro'),
                    ),
                    DropdownMenuItem(
                      value: 'credit',
                      child: Text('Tarjeta de crédito'),
                    ),
                    DropdownMenuItem(
                      value: 'investment',
                      child: Text('Inversión'),
                    ),
                  ],
                  onChanged: (v) => setState(() => type = v ?? 'cash'),
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: currency),
                  onChanged: (v) => currency = v,
                  decoration: const InputDecoration(labelText: 'Moneda'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text('Activo')),
                    Switch(
                      value: isActive,
                      onChanged: (v) => setState(() => isActive = v),
                    ),
                  ],
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
                      await accounts.createCustomAccount(
                        name: name,
                        type: type,
                        currency: currency,
                      );
                    } else {
                      final updated = initial.copyWith(
                        name: name,
                        type: type,
                        currency: currency,
                        isActive: isActive,
                      );
                      await accounts.updateAccount(updated);
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
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'cash':
        return Icons.account_balance_wallet;
      case 'checking':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'credit':
        return Icons.credit_card;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAccountForm(),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        final list = _query.isEmpty
            ? accounts.accounts
            : accounts.searchAccounts(_query);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Buscar cuenta'),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Sin cuentas',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final a = list[i];
                    return Dismissible(
                      key: Key('acc_${a.id}'),
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
                          await _openAccountForm(initial: a);
                          return false;
                        } else {
                          final ok = await _confirmDeleteAccount(a);
                          if (!ok) return false;
                          await accounts.deleteAccount(a.id);
                          return true;
                        }
                      },
                      child: ListTile(
                        leading: Icon(_iconForType(a.type)),
                        title: Text(a.name),
                        subtitle: Text(
                          '${a.type} • ${Helpers.formatCurrency(accounts.computeBalanceForAccount(a.id), auth.currentUserCurrency)}',
                        ),
                        trailing: Switch(
                          value: a.isActive,
                          onChanged: (_) => accounts.toggleAccountActive(a.id),
                        ),
                        onTap: () => _openAccountForm(initial: a),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }
}
