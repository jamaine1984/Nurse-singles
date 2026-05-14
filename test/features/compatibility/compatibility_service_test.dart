import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/features/compatibility/services/compatibility_service.dart';

void main() {
  group('CompatibilityService hospital-friendly scoring', () {
    test('rewards clinical fit, verification, and separate workplaces', () {
      final current = _user(
        id: 'nurse-a',
        hospital: 'General Hospital',
        department: 'Emergency',
        isVerified: true,
        interests: const ['Coffee', 'Hiking', 'Travel'],
        languages: const ['English', 'Spanish'],
      );
      final candidate = _user(
        id: 'nurse-b',
        hospital: 'County Clinic',
        department: 'ICU',
        isVerified: true,
        interests: const ['Coffee', 'Travel'],
        languages: const ['English', 'Spanish'],
      );

      final result = CompatibilityService.score(current, candidate);

      expect(result.totalScore, greaterThanOrEqualTo(85));
      expect(result.workplaceScore, 10);
      expect(result.verificationScore, 5);
      expect(result.matchTier, 'Elite care fit');
      expect(result.careSignals, contains('Workplace privacy respected'));
      expect(result.topReasons, contains('Separate workplaces'));
    });

    test('flags same-workplace conflicts when either user opts out', () {
      final current = _user(
        id: 'nurse-a',
        hospital: 'General Hospital',
        avoidSameWorkplace: true,
      );
      final candidate = _user(id: 'nurse-b', hospital: 'general hospital');

      final result = CompatibilityService.score(current, candidate);

      expect(result.workplaceScore, 0);
      expect(
        result.cautionSignals,
        contains('Same workplace preference conflict'),
      );
    });

    test(
      'does not over-reward same department when privacy preference blocks it',
      () {
        final current = _user(
          id: 'nurse-a',
          department: 'Emergency',
          avoidSameDepartment: true,
        );
        final candidate = _user(id: 'nurse-b', department: 'Emergency');

        final result = CompatibilityService.score(current, candidate);

        expect(result.departmentScore, 3);
        expect(
          result.cautionSignals,
          contains('Same department preference conflict'),
        );
      },
    );

    test('rewards matching off-shift dating windows', () {
      final current = _user(
        id: 'nurse-a',
        shiftType: ShiftType.dayShift,
        preferredDatingWindow: DatingWindow.eveningDinner,
        availableAfterShift: true,
      );
      final candidate = _user(
        id: 'nurse-b',
        shiftType: ShiftType.nightShift,
        preferredDatingWindow: DatingWindow.eveningDinner,
        availableAfterShift: true,
      );

      final result = CompatibilityService.score(current, candidate);

      expect(result.shiftScore, greaterThanOrEqualTo(10));
      expect(result.topReasons, contains('Same dating window: Evening Dinner'));
      expect(result.careSignals, contains('Matching off-shift window'));
      expect(result.careSignals, contains('Both available after shift'));
    });
  });
}

UserModel _user({
  required String id,
  String hospital = 'General Hospital',
  String department = 'Emergency',
  bool avoidSameWorkplace = false,
  bool avoidSameDepartment = false,
  bool isVerified = false,
  List<String> interests = const ['Coffee'],
  List<String> languages = const ['English'],
  ShiftType shiftType = ShiftType.dayShift,
  DatingWindow? preferredDatingWindow,
  bool availableAfterShift = false,
}) {
  return UserModel(
    id: id,
    name: 'Test $id',
    email: '$id@example.com',
    jobTitle: 'Registered Nurse',
    hospital: hospital,
    department: department,
    avoidSameWorkplace: avoidSameWorkplace,
    avoidSameDepartment: avoidSameDepartment,
    location: 'Dallas, United States',
    age: 32,
    shiftType: shiftType,
    preferredDatingWindow: preferredDatingWindow,
    availableAfterShift: availableAfterShift,
    interests: interests,
    languages: languages,
    isVerified: isVerified,
  );
}
