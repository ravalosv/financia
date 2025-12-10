import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../database/database_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final auth = Get.find<AuthController>();

  Future<void> _exportData() async {
    try {
      final data = await DatabaseService().exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Exportar datos',
        fileName: 'financia_export.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      String targetPath = savePath ?? '';
      if (targetPath.isEmpty) {
        if (Platform.isAndroid) {
          final baseDir = Directory('/storage/emulated/0/Documents/Financia');
          if (!await baseDir.exists()) {
            await baseDir.create(recursive: true);
          }
          final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
          targetPath = '${baseDir.path}/financia_export_$ts.json';
        } else {
          final dir = await getApplicationDocumentsDirectory();
          final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
          targetPath = '${dir.path}/financia_export_$ts.json';
        }
      }
      final file = File(targetPath);
      await file.writeAsBytes(bytes);
      Get.snackbar('Exportación', 'Datos exportados a ${file.path}');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo exportar: $e');
    }
  }

  Future<void> _importData() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (picked == null ||
          picked.files.isEmpty ||
          picked.files.single.path == null) {
        Get.snackbar('Importación', 'No se seleccionó archivo');
        return;
      }
      final file = File(picked.files.single.path!);
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      await DatabaseService().importAllData(map);
      Get.snackbar('Importación', 'Datos importados correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo importar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Preferencias', style: AppTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: auth.currentUserCurrency,
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                      DropdownMenuItem(value: 'MXN', child: Text('MXN')),
                    ],
                    onChanged: (v) async {
                      if (v != null) {
                        await auth.updateUser(currency: v);
                        setState(() {});
                        Get.snackbar('Moneda', 'Moneda base actualizada a $v');
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Moneda base'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Copia de seguridad', style: AppTheme.titleMedium),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Exportar datos'),
                    onTap: _exportData,
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_for_offline),
                    title: const Text('Importar datos'),
                    onTap: _importData,
                  ),
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('Ver base de datos'),
                    onTap: () => Get.toNamed('/db-viewer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
