import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale_heart/core/localization/app_language.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

void main() {
  test('language catalog stays aligned with Flutter supported locales', () {
    final catalogCodes = AppLanguages.supported
        .map((language) => language.code)
        .toList();
    final fullySupportedCodes = AppLanguages.fullySupported
        .map((language) => language.code)
        .toList();

    expect(AppLanguages.supportedLocaleCodes, catalogCodes);
    expect(AppLanguages.fullySupportedLocaleCodes, fullySupportedCodes);
    expect(
      AppLanguages.fullySupportedLocales.map((locale) => locale.languageCode),
      fullySupportedCodes,
    );
  });

  test('locale normalization handles aliases and unsupported codes', () {
    expect(AppLanguages.normalizeCode('tl'), 'fil');
    expect(AppLanguages.normalizeCode('MS'), 'ms');
    expect(AppLanguages.normalizeCode('unknown'), AppLanguages.fallbackCode);
    expect(AppLanguages.normalizeFullySupportedCode('fr'), 'en');
    expect(AppLanguages.normalizeFullySupportedCode('ms'), 'ms');
  });

  test('app copy translates core UI for Spanish and Malay', () {
    expect(
      AppLocalizations.translate('login', const Locale('ms')),
      'Log Masuk',
    );
    expect(
      AppLocalizations.translate('settings', const Locale('ms')),
      'Tetapan',
    );
    expect(
      AppLocalizations.translate('nav_feed', const Locale('ms')),
      'Suapan',
    );
    expect(AppLocalizations.translate('nav_hub', const Locale('es')), 'Centro');
    expect(
      AppLocalizations.translate('login', const Locale('es')),
      'Iniciar sesion',
    );
    expect(
      AppLocalizations.translate('settings', const Locale('es')),
      'Configuracion',
    );
    expect(
      AppLocalizations.translate(
        'no_profiles_nearby',
        const Locale('en'),
      ).contains('No more profiles nearby'),
      isFalse,
    );
    expect(
      AppLocalizations.translate('ways_to_earn_minutes', const Locale('es')),
      'Formas de ganar minutos',
    );
    expect(
      AppLocalizations.format(
        'complete_profile_bonus_body',
        const Locale('es'),
        {'percent': 85},
      ),
      'Completa tu perfil para ganar 10 minutos extra. (85% completo)',
    );
    expect(
      AppLocalizations.translate('watch_short_ad', const Locale('ms')),
      'Tonton iklan pendek',
    );
    expect(
      AppLocalizations.format(
        'complete_profile_bonus_body',
        const Locale('ms'),
        {'percent': 85},
      ),
      'Lengkapkan profil untuk mendapat 10 minit bonus. (85% lengkap)',
    );
    expect(
      AppLocalizations.translate(
        'speed_room_er_coffee_bay_name',
        const Locale('es'),
      ),
      'Cafe de urgencias',
    );
    expect(
      AppLocalizations.translate(
        'speed_room_night_shift_lounge_description',
        const Locale('ms'),
      ),
      'Bertemu selepas rondaan tengah malam',
    );
    expect(
      AppLocalizations.translate(
        'speed_room_scholarship_circle_name',
        const Locale('ms'),
      ),
      'Bulatan biasiswa',
    );
    expect(
      AppLocalizations.translate('nurse_hub', const Locale('es')),
      'Centro de enfermeria',
    );
    expect(
      AppLocalizations.translate('nurse_hub_hero_title', const Locale('ms')),
      'Dibina untuk pekerja kesihatan',
    );
    expect(
      AppLocalizations.translate(
        'nurse_hub_partner_notes_title',
        const Locale('es'),
      ),
      'Notas de staffing listas para socios',
    );
    expect(
      AppLocalizations.translate(
        'code_heart_match_confirmed',
        const Locale('es'),
      ),
      'Codigo Corazon: match confirmado',
    );
    expect(
      AppLocalizations.translate('community', const Locale('ms')),
      'Suapan Hospital',
    );
    expect(
      AppLocalizations.translate('workplace_privacy', const Locale('ms')),
      'Privasi tempat kerja',
    );
    expect(
      AppLocalizations.healthcareCredentialLabel(
        'travelNurse',
        const Locale('es'),
      ),
      'Enfermera viajera verificada',
    );
    expect(
      AppLocalizations.shiftTypeLabel('nightShift', const Locale('ms')),
      'Syif malam',
    );
    expect(
      AppLocalizations.translate('not_a_real_key', const Locale('ms')),
      'Not a real key',
    );
  });

  test('safety and moderation copy translates for Spanish and Malay', () {
    expect(
      AppLocalizations.translate('report_user', const Locale('es')),
      'Reportar usuario',
    );
    expect(
      AppLocalizations.translate('block_user', const Locale('es')),
      'Bloquear usuario',
    );
    expect(
      AppLocalizations.translate('submit_report', const Locale('es')),
      'Enviar reporte',
    );
    expect(
      AppLocalizations.translate(
        'report_reason_harassment',
        const Locale('es'),
      ),
      'Acoso',
    );
    expect(
      AppLocalizations.format('block_user_body', const Locale('es'), {
        'name': 'Maria',
      }),
      'Bloquear a Maria elimina chats y matches existentes, y evita futuros mensajes de este perfil.',
    );
    expect(
      AppLocalizations.format('incoming_video_call_body', const Locale('es'), {
        'name': 'Maria',
      }),
      'Maria te esta llamando ahora.',
    );
    expect(
      AppLocalizations.translate('report_user', const Locale('ms')),
      'Lapor pengguna',
    );
    expect(
      AppLocalizations.translate('block_user', const Locale('ms')),
      'Sekat pengguna',
    );
    expect(
      AppLocalizations.translate('submit_report', const Locale('ms')),
      'Hantar laporan',
    );
    expect(
      AppLocalizations.translate('no_blocked_users', const Locale('ms')),
      'Tiada pengguna disekat',
    );
    expect(
      AppLocalizations.format('block_user_body', const Locale('ms'), {
        'name': 'Aisha',
      }),
      'Menyekat Aisha memadam chat dan padanan sedia ada, serta menghalang mesej masa depan daripada profil ini.',
    );
    expect(
      AppLocalizations.translate('incoming_video_call', const Locale('ms')),
      'Panggilan video masuk',
    );
    expect(
      AppLocalizations.translate('room_join_auth_failed', const Locale('es')),
      'Fallo la verificacion segura de la sala. Reinicia la app e intentalo de nuevo.',
    );
    expect(
      AppLocalizations.translate(
        'failed_join_room_generic',
        const Locale('ms'),
      ),
      'Tidak dapat menyertai bilik ini. Sila cuba lagi.',
    );
  });
}
