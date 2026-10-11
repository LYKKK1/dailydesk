import 'package:dailydesk/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('P0-P3 priority colors are stable', () {
    expect(AppColors.priorityColor(0), AppColors.p0);
    expect(AppColors.priorityColor(1), AppColors.p1);
    expect(AppColors.priorityColor(2), AppColors.p2);
    expect(AppColors.priorityColor(3), AppColors.p3);
  });

  test('Morandi palette contains six colors', () {
    expect(AppColors.morandiPalette, hasLength(6));
  });

  test('out-of-range priority falls back to P3', () {
    expect(AppColors.priorityColor(9), AppColors.p3);
  });
}
