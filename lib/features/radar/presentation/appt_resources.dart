import 'package:url_launcher/url_launcher.dart' as url_launcher;

const String kApptOrg = 'https://appt.org/';

const String kApptHandbookPdf =
    'https://appt.org/en/pdf/appt-accessibility-handbook.pdf';

Future<void> openAccessibilityHandbookUrl(Uri uri) async {
  if (await url_launcher.canLaunchUrl(uri)) {
    await url_launcher.launchUrl(
      uri,
      mode: url_launcher.LaunchMode.externalApplication,
    );
  }
}
