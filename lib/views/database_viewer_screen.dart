import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../database/database_service.dart';
import '../theme/app_theme.dart';

class DatabaseViewerScreen extends StatefulWidget {
  const DatabaseViewerScreen({super.key});

  @override
  State<DatabaseViewerScreen> createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen> {
  final tables = const [
    'users',
    'accounts',
    'categories',
    'transactions',
    'budgets',
    'goals',
    'receipts',
    'cards',
  ];
  String? selectedTable;
  List<Map<String, dynamic>> records = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    selectedTable = tables.first;
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      List<Map<String, dynamic>> data = [];
      switch (selectedTable) {
        case 'users':
          data = DatabaseService.getUsersBox().values
              .map((e) => e.toJson())
              .toList();
          break;
        case 'accounts':
          data = DatabaseService.getAccountsBox().values
              .map((e) => e.toJson())
              .toList();
          break;
        case 'categories':
          data = DatabaseService.getCategoriesBox().values
              .map((e) => e.toJson())
              .toList();
          break;
        case 'transactions':
          final cats = DatabaseService.getCategoriesBox();
          data = DatabaseService.getTransactionsBox().values.map((e) {
            final m = e.toJson();
            final cat = cats.get(m['category_id']);
            m.remove('id');
            m['category_name'] = cat?.name ?? m['category_id'];
            return m;
          }).toList();
          break;
        case 'budgets':
          data = DatabaseService.getBudgetsBox().values
              .map((e) => e.toJson())
              .toList();
          break;
        case 'goals':
          data = DatabaseService.getGoalsBox().values
              .map((e) => e.toJson())
              .toList();
          break;
        case 'receipts':
          data = DatabaseService.getReceiptsBox().values
              .map((e) => e.toJson())
              .toList();
          break;
        case 'cards':
          data = DatabaseService.getCardsBox().values
              .map((e) => e.toJson())
              .toList();
          break;
        default:
          data = [];
      }
      setState(() => records = data);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = <String>{};
    for (final r in records) {
      columns.addAll(r.keys);
    }
    final cols = columns.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visor de Base de Datos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedTable,
                      items: tables
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(t.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) async {
                        setState(() => selectedTable = v);
                        await _load();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Tabla a visualizar',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${records.length} registros',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(8),
                      child: cols.isEmpty
                          ? Center(
                              child: Text(
                                'Sin registros',
                                style: AppTheme.bodyMedium,
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth:
                                      MediaQuery.of(context).size.width - 64,
                                ),
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    columns: cols
                                        .map((c) => DataColumn(label: Text(c)))
                                        .toList(),
                                    rows: records.map((r) {
                                      return DataRow(
                                        cells: cols
                                            .map(
                                              (c) => DataCell(
                                                Text(
                                                  _formatValue(r[c]),
                                                  style: AppTheme.bodySmall,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }
}
