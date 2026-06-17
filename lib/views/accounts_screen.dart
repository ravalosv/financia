import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/account_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/card_controller.dart';
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
  final cards = Get.find<CardController>();
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
    final currencyController = TextEditingController(
      text: initial?.currency ?? auth.currentUserCurrency,
    );
    final cutoffDayController = TextEditingController(
      text: initial?.creditCutoffDay?.toString() ?? '',
    );
    String type = initial?.type ?? 'cash';
    bool isActive = initial?.isActive ?? true;
    String? linkedCardId = initial == null
        ? null
        : cards.getCardByLinkedAccountId(initial.id)?.id;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableCards = cards.getAvailableCardsForAccount(
              initial?.id,
            );
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
                        DropdownMenuItem(
                          value: 'cash',
                          child: Text('Efectivo'),
                        ),
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
                      onChanged: (v) => setModalState(() => type = v ?? 'cash'),
                      decoration: const InputDecoration(labelText: 'Tipo'),
                    ),
                    const SizedBox(height: 12),
                    if (type == 'credit') ...[
                      TextField(
                        controller: cutoffDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Día de corte',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: linkedCardId,
                      decoration: const InputDecoration(
                        labelText: 'Tarjeta asociada',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin tarjeta asociada'),
                        ),
                        ...availableCards.map(
                          (card) => DropdownMenuItem<String?>(
                            value: card.id,
                            child: Text(card.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() => linkedCardId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: currencyController,
                      decoration: const InputDecoration(labelText: 'Moneda'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(child: Text('Activo')),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setModalState(() => isActive = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final selectedCurrency = currencyController.text.trim();
                        final cutoffText = cutoffDayController.text.trim();
                        final cutoffDay = cutoffText.isEmpty
                            ? null
                            : int.tryParse(cutoffText);
                        if (name.isEmpty) {
                          Get.snackbar('Validación', 'Ingresa un nombre');
                          return;
                        }
                        if (selectedCurrency.isEmpty) {
                          Get.snackbar('Validación', 'Ingresa una moneda');
                          return;
                        }
                        if (type == 'credit' &&
                            cutoffDay != null &&
                            (cutoffDay < 1 || cutoffDay > 31)) {
                          Get.snackbar(
                            'Validación',
                            'El día de corte debe estar entre 1 y 31',
                          );
                          return;
                        }
                        if (initial == null) {
                          final createdAccount = await accounts
                              .createCustomAccount(
                                name: name,
                                type: type,
                                currency: selectedCurrency,
                              );
                          if (type == 'credit') {
                            await accounts.updateAccount(
                              createdAccount.copyWith(
                                creditCutoffDay: cutoffDay,
                              ),
                            );
                          }
                          await cards.assignCardToAccount(
                            accountId: createdAccount.id,
                            cardId: linkedCardId,
                          );
                        } else {
                          final updated = initial.copyWith(
                            name: name,
                            type: type,
                            currency: selectedCurrency,
                            creditCutoffDay: type == 'credit'
                                ? cutoffDay
                                : null,
                            isActive: isActive,
                          );
                          await accounts.updateAccount(updated);
                          await cards.assignCardToAccount(
                            accountId: initial.id,
                            cardId: linkedCardId,
                          );
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
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
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final a = list[i];
                    final linkedCard = cards.getCardByLinkedAccountId(a.id);
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
                          [
                            a.type,
                            Helpers.formatCurrency(
                              accounts.computeBalanceForAccount(a.id),
                              auth.currentUserCurrency,
                            ),
                            if (linkedCard != null)
                              'Tarjeta: ${linkedCard.name} • ****${linkedCard.last4}',
                          ].join(' • '),
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
