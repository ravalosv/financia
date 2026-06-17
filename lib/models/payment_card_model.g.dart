// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_card_model.dart';

class PaymentCardAdapter extends TypeAdapter<PaymentCard> {
  @override
  final int typeId = 7;

  @override
  PaymentCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final legacyShape = fields[13] is DateTime;
    return PaymentCard(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      cardType: fields[3] as String,
      encryptedNumber: fields[4] as String,
      last4: fields[5] as String,
      expiryMonth: fields[6] as int,
      expiryYear: fields[7] as int,
      encryptedCvv: fields[8] as String,
      isVirtual: fields[9] as bool,
      encryptedPin: fields[10] as String?,
      statementDay: fields[11] as int?,
      paymentDay: fields[12] as int?,
      linkedAccountId: legacyShape ? null : fields[13] as String?,
      createdAt: (legacyShape ? fields[13] : fields[14]) as DateTime,
      updatedAt: (legacyShape ? fields[14] : fields[15]) as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentCard obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.cardType)
      ..writeByte(4)
      ..write(obj.encryptedNumber)
      ..writeByte(5)
      ..write(obj.last4)
      ..writeByte(6)
      ..write(obj.expiryMonth)
      ..writeByte(7)
      ..write(obj.expiryYear)
      ..writeByte(8)
      ..write(obj.encryptedCvv)
      ..writeByte(9)
      ..write(obj.isVirtual)
      ..writeByte(10)
      ..write(obj.encryptedPin)
      ..writeByte(11)
      ..write(obj.statementDay)
      ..writeByte(12)
      ..write(obj.paymentDay)
      ..writeByte(13)
      ..write(obj.linkedAccountId)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
