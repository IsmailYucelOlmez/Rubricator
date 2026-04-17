import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rubricator Gizlilik Politikasi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Rubricator, hesap olusturma ve uygulama deneyimini sunma amaciyla '
                'asagidaki verileri isler:',
              ),
              SizedBox(height: AppSpacing.sm),
              Text('- E-posta adresi'),
              Text('- Kullanici adi'),
              Text('- Profil fotografiniz (opsiyonel)'),
              SizedBox(height: AppSpacing.md),
              Text(
                'Bu veriler:',
              ),
              SizedBox(height: AppSpacing.sm),
              Text('- Kimlik dogrulama (giris/kayit)'),
              Text('- Profilinizi gosterme'),
              Text('- Uygulama ozelliklerini kisisellestirme'),
              SizedBox(height: AppSpacing.md),
              Text(
                'amaclariyla kullanilir. Verileriniz, yasal zorunluluklar haricinde '
                'izniniz olmadan ucuncu kisilerle paylasilmaz.',
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Hesap olusturarak bu politikayi kabul etmis olursunuz.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
