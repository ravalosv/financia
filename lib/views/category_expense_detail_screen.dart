import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class CategoryExpenseDetailScreen extends StatelessWidget {
  const CategoryExpenseDetailScreen({super.key});

  Color _randomColorForKey(String key) {
    final hash = key.codeUnits.fold<int>(
      0,
      (acc, c) => (acc * 31 + c) & 0xFFFFFFFF,
    );
    final hue = (hash % 360).toDouble();
    const saturation = 0.7;
    const lightness = 0.55;
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<DashboardController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de gasto por categoría')),
      body: Obx(() {
        final data = dashboard.categoryExpenseData;
        if (data.isEmpty) {
          return Center(
            child: Text('Sin datos de gasto', style: AppTheme.bodyMedium),
          );
        }
        final total = data.fold<double>(
          0.0,
          (s, e) => s + (e['amount'] as double),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: AppTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      Helpers.formatCurrency(total, auth.currentUserCurrency),
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final e = data[i];
                    final amount = e['amount'] as double;
                    final pct = total > 0 ? (amount / total) * 100 : 0.0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _randomColorForKey(
                          e['categoryId'] as String,
                        ),
                        radius: 10,
                      ),
                      title: Text(e['categoryName'] as String),
                      subtitle: Text('${pct.toStringAsFixed(1)}%'),
                      trailing: Text(
                        Helpers.formatCurrency(
                          amount,
                          auth.currentUserCurrency,
                        ),
                        style: AppTheme.titleSmall,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
