// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_model.dart';

class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 4;

  @override
  Budget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Budget(
      id: fields[0] as String,
      userId: fields[1] as String,
      categoryId: fields[2] as String,
      amount: fields[3] as double,
      monthYear: fields[4] as String,
      spent: fields[5] as double,
      remaining: fields[6] as double,
      rolloverFromPrevious: fields[7] as double,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.monthYear)
      ..writeByte(5)
      ..write(obj.spent)
      ..writeByte(6)
      ..write(obj.remaining)
      ..writeByte(7)
      ..write(obj.rolloverFromPrevious)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}