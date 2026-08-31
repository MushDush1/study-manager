import 'dart:math';

int _idSeq = 0;
final Random _idRandom = Random();

/// Windows 上 DateTime 精度可能只到毫秒，同一循环里会生成相同 id
String createUniqueId() {
    _idSeq += 1;
    return "${DateTime.now().microsecondsSinceEpoch}_${_idSeq}_${_idRandom.nextInt(1 << 30)}";
}
