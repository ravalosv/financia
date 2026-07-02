import 'package:get/get.dart';

import 'account_controller.dart';
import '../database/database_service.dart';
import '../models/payment_card_model.dart';
import '../security/card_security_service.dart';
import '../utils/credit_card_date_utils.dart';
import '../utils/helpers.dart';

class CardController extends GetxController {
  final DatabaseService _databaseService = Get.find<DatabaseService>();
  final CardSecurityService _securityService = CardSecurityService();

  final cards = <PaymentCard>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCards();
  }

  Future<void> loadCards() async {
    try {
      isLoading(true);
      final loadedCards = await _databaseService.getAllCards();
      loadedCards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      cards.assignAll(loadedCards);
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar las tarjetas: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<bool> authenticateAccess(String reason) {
    return _securityService.authenticate(reason: reason);
  }

  Future<void> createCard({
    required String userId,
    required String name,
    required String cardType,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
    required bool isVirtual,
    String? pin,
    int? statementDay,
    int? paymentDay,
    int? paymentGraceDays,
    bool requiresPaymentReminder = true,
    int paymentReminderDays = 3,
    String? linkedAccountId,
  }) async {
    try {
      isLoading(true);
      final normalizedNumber = _digitsOnly(cardNumber);
      if (normalizedNumber.length != 16) {
        throw Exception('El numero de tarjeta debe tener 16 digitos');
      }
      _validateLinkedAccount(
        linkedAccountId: linkedAccountId,
        cardType: cardType,
      );
      final encryptedNumber = await _securityService.encryptText(
        normalizedNumber,
      );
      final encryptedCvv = await _securityService.encryptText(_digitsOnly(cvv));
      final encryptedPin = (pin != null && pin.trim().isNotEmpty)
          ? await _securityService.encryptText(_digitsOnly(pin))
          : null;
      final now = DateTime.now();
      final card = PaymentCard(
        id: Helpers.generateId(),
        userId: userId,
        name: name.trim(),
        cardType: cardType,
        encryptedNumber: encryptedNumber,
        last4: normalizedNumber.substring(normalizedNumber.length - 4),
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        encryptedCvv: encryptedCvv,
        isVirtual: isVirtual,
        encryptedPin: encryptedPin,
        statementDay: statementDay,
        paymentDay: paymentDay,
        linkedAccountId: linkedAccountId,
        paymentGraceDays: paymentGraceDays,
        requiresPaymentReminder: requiresPaymentReminder,
        paymentReminderDays: paymentReminderDays,
        createdAt: now,
        updatedAt: now,
      );
      await _databaseService.insertCard(card);
      cards.insert(0, card);
      Get.snackbar('Exito', 'Tarjeta guardada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo guardar la tarjeta: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateCard({
    required PaymentCard existing,
    required String name,
    required String cardType,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
    required bool isVirtual,
    String? pin,
    int? statementDay,
    int? paymentDay,
    int? paymentGraceDays,
    bool requiresPaymentReminder = true,
    int paymentReminderDays = 3,
    String? linkedAccountId,
  }) async {
    try {
      isLoading(true);
      final normalizedNumber = _digitsOnly(cardNumber);
      if (normalizedNumber.length != 16) {
        throw Exception('El numero de tarjeta debe tener 16 digitos');
      }
      _validateLinkedAccount(
        linkedAccountId: linkedAccountId,
        cardType: cardType,
        excludingCardId: existing.id,
      );
      final encryptedNumber = await _securityService.encryptText(
        normalizedNumber,
      );
      final encryptedCvv = await _securityService.encryptText(_digitsOnly(cvv));
      final encryptedPin = (pin != null && pin.trim().isNotEmpty)
          ? await _securityService.encryptText(_digitsOnly(pin))
          : null;
      final updated = existing.copyWith(
        name: name.trim(),
        cardType: cardType,
        encryptedNumber: encryptedNumber,
        last4: normalizedNumber.substring(normalizedNumber.length - 4),
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        encryptedCvv: encryptedCvv,
        isVirtual: isVirtual,
        encryptedPin: encryptedPin,
        clearPin: isVirtual,
        statementDay: statementDay,
        paymentDay: paymentDay,
        linkedAccountId: linkedAccountId,
        paymentGraceDays: paymentGraceDays,
        requiresPaymentReminder: requiresPaymentReminder,
        paymentReminderDays: paymentReminderDays,
        clearLinkedAccountId:
            linkedAccountId == null || linkedAccountId.isEmpty,
        clearStatementDay: cardType != 'credit',
        clearPaymentDay: cardType != 'credit',
        clearPaymentGraceDays: cardType != 'credit',
        updatedAt: DateTime.now(),
      );
      await _databaseService.updateCard(updated);
      final index = cards.indexWhere((card) => card.id == updated.id);
      if (index != -1) {
        cards[index] = updated;
        cards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
      Get.snackbar('Exito', 'Tarjeta actualizada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la tarjeta: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      isLoading(true);
      await _databaseService.deleteCard(cardId);
      cards.removeWhere((card) => card.id == cardId);
      Get.snackbar('Exito', 'Tarjeta eliminada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar la tarjeta: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, String?>> revealSensitiveData(PaymentCard card) async {
    final number = await _securityService.decryptText(card.encryptedNumber);
    final cvv = await _securityService.decryptText(card.encryptedCvv);
    final pin = (card.encryptedPin != null && card.encryptedPin!.isNotEmpty)
        ? await _securityService.decryptText(card.encryptedPin!)
        : null;
    return {'number': number, 'cvv': cvv, 'pin': pin};
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  PaymentCard? getCardById(String cardId) {
    try {
      return cards.firstWhere((card) => card.id == cardId);
    } catch (_) {
      return null;
    }
  }

  PaymentCard? getCardByLinkedAccountId(String accountId) {
    try {
      return cards.firstWhere((card) => card.linkedAccountId == accountId);
    } catch (_) {
      return null;
    }
  }

  CreditCardPaymentConfig? getPaymentConfigForAccount(
    String accountId, {
    int? fallbackStatementDay,
  }) {
    final card = getCardByLinkedAccountId(accountId);
    final statementDay = (card?.cardType == 'credit')
        ? (card?.statementDay ?? fallbackStatementDay)
        : fallbackStatementDay;
    if (statementDay == null) return null;

    return CreditCardPaymentConfig(
      cardId: card?.id,
      cardName: card?.name ?? 'Tarjeta de credito',
      accountId: accountId,
      statementDay: statementDay,
      paymentGraceDays: card?.paymentGraceDays,
      legacyPaymentDay: card?.paymentDay,
      requiresReminder: card?.requiresPaymentReminder ?? false,
      reminderDays: card?.paymentReminderDays ?? 3,
    );
  }

  List<PaymentCard> getAvailableCardsForAccount(
    String? accountId, {
    String? accountType,
  }) {
    return cards
        .where(
          (card) =>
              card.linkedAccountId == null ||
              card.linkedAccountId!.isEmpty ||
              card.linkedAccountId == accountId,
        )
        .where((card) {
          if (accountType == null || accountType.isEmpty) return true;
          if (accountType == 'credit') return card.cardType == 'credit';
          return card.cardType != 'credit';
        })
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> assignCardToAccount({
    required String accountId,
    String? cardId,
  }) async {
    try {
      isLoading(true);

      final currentCard = getCardByLinkedAccountId(accountId);
      final selectedCard = cardId == null || cardId.isEmpty
          ? null
          : getCardById(cardId);

      if (cardId != null && cardId.isNotEmpty && selectedCard == null) {
        throw Exception('La tarjeta seleccionada no existe');
      }

      final account = Get.find<AccountController>().getAccountById(accountId);
      if (account == null) {
        throw Exception('La cuenta seleccionada no existe');
      }
      if (selectedCard != null) {
        final expectsCredit = account.type == 'credit';
        final isCreditCard = selectedCard.cardType == 'credit';
        if (expectsCredit != isCreditCard) {
          throw Exception(
            expectsCredit
                ? 'Solo puedes ligar tarjetas de credito a cuentas de credito'
                : 'No puedes ligar una tarjeta de credito a una cuenta que no es de credito',
          );
        }
      }

      if (selectedCard != null &&
          selectedCard.linkedAccountId != null &&
          selectedCard.linkedAccountId!.isNotEmpty &&
          selectedCard.linkedAccountId != accountId) {
        throw Exception('La tarjeta seleccionada ya esta ligada a otra cuenta');
      }

      if (currentCard != null && currentCard.id != cardId) {
        final unlinkedCard = currentCard.copyWith(
          clearLinkedAccountId: true,
          updatedAt: DateTime.now(),
        );
        await _databaseService.updateCard(unlinkedCard);
        final currentIndex = cards.indexWhere(
          (card) => card.id == unlinkedCard.id,
        );
        if (currentIndex != -1) {
          cards[currentIndex] = unlinkedCard;
        }
      }

      if (selectedCard != null && selectedCard.linkedAccountId != accountId) {
        final linkedCard = selectedCard.copyWith(
          linkedAccountId: accountId,
          updatedAt: DateTime.now(),
        );
        await _databaseService.updateCard(linkedCard);
        final selectedIndex = cards.indexWhere(
          (card) => card.id == linkedCard.id,
        );
        if (selectedIndex != -1) {
          cards[selectedIndex] = linkedCard;
        }
      }

      cards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la tarjeta asociada: $e');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  void _validateLinkedAccount({
    String? linkedAccountId,
    String? cardType,
    String? excludingCardId,
  }) {
    if (linkedAccountId == null || linkedAccountId.isEmpty) return;

    final account = Get.find<AccountController>().getAccountById(
      linkedAccountId,
    );
    if (account == null) {
      throw Exception('La cuenta seleccionada no existe');
    }
    if (cardType == 'credit' && account.type != 'credit') {
      throw Exception(
        'Las tarjetas de credito solo se pueden ligar a cuentas de credito',
      );
    }
    if (cardType != 'credit' && account.type == 'credit') {
      throw Exception(
        'Las tarjetas que no son de credito no se pueden ligar a cuentas de credito',
      );
    }

    final duplicated = cards.any(
      (card) =>
          card.linkedAccountId == linkedAccountId && card.id != excludingCardId,
    );
    if (duplicated) {
      throw Exception('La cuenta seleccionada ya tiene una tarjeta ligada');
    }
  }
}
