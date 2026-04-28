# Google Play Incelemeci Erisim Talimatlari (BookApp)

Bu dokuman, Google Play inceleme ekibinin uygulamadaki giris gerektiren bolumlere erisebilmesi icin hazirlanmistir.

## 1) Uygulama Erisim Ozeti

- Uygulamada kisitli erisim vardir: **EVET**
- Incelemeciler hesap olusturamaz; bu nedenle asagidaki test hesabi kullanilmalidir.

## 2) Test Hesabi (Play Console App Access Alanina Girilecek)

- E-posta / Kullanici adi: `BURAYA_TEST_HESABI`
- Sifre: `BURAYA_TEST_SIFRESI`
- Hesap durumu: `aktif`

Not:
- Incelemeciler yeni hesap olusturamaz.
- Incelemeciler mevcut kendi hesaplarini kullanamaz.
- Incelemeciler ucretsiz deneme ile erisim saglayamaz.

## 3) Giris Yapmayan Kullanicinin Yapamayacagi Islemler

Asagidaki ozellikler giris yapilmadan kullanilamaz:

1. **Profil tabinda** profil bilgilerini gorme, duzenleme ve cikis yapma.
2. **Reading Habit** (okuma aliskanligi) ekraninda:
   - log ekleme (hizli log dahil),
   - takvim, grafik, seriler ve log gecmisini gorme.
3. **Reading Stats** (istatistik) ekraninda tum istatistikleri gorme.
4. **Listelerim / Kaydettiklerim** ve kisinin okuma listesi sekmeleri.
5. Kitaplarda:
   - favorilere ekleme/kaldirma,
   - okuma durumu secme (To Read/Reading/Completed vb.),
   - ilerleme yuzdesi girme,
   - puan verme.
6. Kitap detayinda:
   - kullanici yorumu ekleme/duzenleme/silme,
   - dis yorum linki ekleme,
   - alinti ekleme.
7. Listelerde:
   - yeni liste olusturma,
   - mevcut listeyi duzenleme/silme (sahip oldugu listede),
   - listeye yorum gonderme,
   - liste begenme/kaydetme.

## 4) Google Play Incelemecisi Icin Test Adimlari

1. Uygulamayi acin.
2. Alt menuden **Profile** tabina gidin.
3. **Sign In** butonuna basin.
4. Yukaridaki test hesap bilgileri ile giris yapin.
5. Giris sonrasi asagidaki bolumleri test edin:
   - Profile > Profili duzenle
   - Profile > Reading Habit (quick log ve detay sayfasi)
   - Profile > Reading Stats
   - Lists > List olusturma / mevcut listeye girip yorum gonderme
   - Bir kitap detayina girip favori, durum, puan, yorum, alinti islevleri

## 5) 2FA / Konum / Abonelik / Ek Cihaz

- 2 adimli dogrulama: **YOK**
- Konum tabanli erisim kisiti: **YOK**
- Ucretli abonelik gereksinimi: **YOK**
- Baska cihazda tamamlanmasi gereken adim: **YOK**

## 6) Play Console Icin Kisa Metin

`App access icin test hesabi saglanmistir. Incelemeciler hesap olusturmadan giris yapip profil, reading habit, reading stats, list olusturma/yorum, favori, okuma durumu, puan, yorum ve alinti dahil tum ozellikleri test edebilir.`
