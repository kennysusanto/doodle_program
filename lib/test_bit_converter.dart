import 'dart:math';

void main() {
  num n = 4278190080;
  print(n);
  List r = u32tou8(n, debug: true);
  print(r);
  List c = [255, 80, 80, 80];
  print('');
  print(c);
  num cr = u8tou32(c, debug: true);
  print(cr);
}

num u8tou32(List c, {bool debug = false}) {
  String bit = '';
  for (var i = 0; i < c.length; i++) {
    String bit2 = '00000000';
    var n = c[i];
    for (var j = 0; j < bit2.length; j++) {
      var div = pow(2, bit2.length - 1 - j);
      if (n / div >= 1) {
        n -= div;
        bit2 = replaceCharAt(bit2, j, '1');
      }
    }
    bit += bit2;
  }
  if (debug) {
    print(bit);
  }
  num res = bitToDec(bit);
  return res;
}

List u32tou8(num n, {bool debug = false}) {
  String bit = '00000000000000000000000000000000';
  // ke bit dulu klo uint32 => 1111 1111 1111 1111 1111 1111 1111 1111
  for (var i = 0; i < bit.length; i++) {
    var div = pow(2, bit.length - 1 - i);
//     print('${n / div}, $n, $div');
    if (n / div >= 1) {
      n -= div;
      bit = replaceCharAt(bit, i, '1');
    }
  }
  if (debug) {
    print(bit);
  }
  var b1 = bit.substring(0, 8);
  var b2 = bit.substring(8, 16);
  var b3 = bit.substring(16, 24);
  var b4 = bit.substring(24, 32);

  num d1 = bitToDec(b1);
  num d2 = bitToDec(b2);
  num d3 = bitToDec(b3);
  num d4 = bitToDec(b4);

  return [d1, d2, d3, d4];
}

num bitToDec(String bit) {
  num total = 0;
  for (var i = 0; i < bit.length; i++) {
    if (bit[i] == '1') {
      total += pow(2, bit.length - 1 - i);
    }
  }
  return total;
}

String replaceCharAt(String oldString, int index, String newChar) {
  return oldString.substring(0, index) +
      newChar +
      oldString.substring(index + 1);
}
