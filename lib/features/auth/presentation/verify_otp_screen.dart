import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email; // İlk ekrandan gelen e-posta adresi

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    setState(() => _isLoading = true);
    try {
      final otpToken = _otpController.text.trim();
      final newPassword = _passwordController.text.trim();

      if (otpToken.length < 6) throw 'Lütfen 6 haneli kodu eksiksiz girin.';
      if (newPassword.length < 6) throw 'Yeni şifre en az 6 karakter olmalıdır.';

      // 1. OTP Kodunu doğrula (Kullanıcı otomatik giriş yapmış olur)
      final AuthResponse response = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: otpToken,
        type: OtpType.recovery,
      );

      if (response.session != null) {
        // 2. Oturum açıldığı için şifreyi güncelle
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Şifreniz başarıyla güncellendi!')),
          );
          // Kullanıcıyı giriş ekranına veya ana sayfaya yönlendirin
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        throw 'Doğrulama başarısız oldu.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifreyi Yenile')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${widget.email} adresine gelen kodu girin.'),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6 Haneli Doğrulama Kodu',
                border: OutlineInputBorder(),
                counterText: "",
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text('Şifreyi Güncelle'),
                  ),
          ],
        ),
      ),
    );
  }
}