//  '#FFE82A'   ->   0xFFFFE82A
int getColorFromHex(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) hexColor = "FF" + hexColor;
  return int.parse(hexColor, radix: 16);
}