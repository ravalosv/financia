// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 3;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      userId: fields[1] as String,
      accountId: fields[2] as String,
      categoryId: fields[3] as String,
      amount: fields[4] as double,
      type: fields[5] as String,
      transactionDate: fields[6] as DateTime,
      description: fields[7] as String?,
      merchant: fields[8] as String?,
      isRecurring: fields[9] as bool,
      createdAt: fields[10] as DateTime,
      exchangeRate: (fields[11] as double?) ?? 1.0,
      installmentPlanId: fields[12] as String?,
      installmentIndex: fields[13] as int?,
      installmentCount: fields[14] as int?,
      purchaseDate: (fields[15] as DateTime?) ?? fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.accountId)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.transactionDate)
      ..writeByte(15)
      ..write(obj.purchaseDate)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.merchant)
      ..writeByte(9)
      ..write(obj.isRecurring)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.exchangeRate)
      ..writeByte(12)
      ..write(obj.installmentPlanId)
      ..writeByte(13)
      ..write(obj.installmentIndex)
      ..writeByte(14)
      ..write(obj.installmentCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
