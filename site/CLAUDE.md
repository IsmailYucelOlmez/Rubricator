# site/ — Rubricator web sitesi

Deno ile TypeScript şablonlarından üretilen statik site (rubricator.site). React, Tailwind veya bundler yok.

## UI / Tasarım kuralları
- Her UI işinden önce `design/DESIGN.md` dosyasını oku. İşe `rubricator-web` skill'iyle başla (genel ilkeler için `ui-design`).
- **Stil sadece `site/static/site.css` içinde yazılır.** `style=""`, `<style>`, harici CSS/font/script kullanılmaz; CSP bunları engeller.
- Renkler yalnızca `var(--token)` ile kullanılır. Yeni renk hem açık hem koyu bloğa token olarak eklenir. Sabit hex yazılmaz.
- Yeni boşluk değerleri ölçekten seçilir: 0.25/0.5/0.75/1/1.25/1.5/2/2.5/3/4 rem.
- Önce mevcut sınıfları kullan (`.btn`, `.card`, `.panel`, `.note`, `.status`, `.field`, `.tabs`, `.book`…).
- Her görünen metin **EN + TR** olarak string nesnelerine yazılır. JS'te dinamik veri sadece `textContent` ile basılır.
- Her ekran için durumlar ele alınır: yükleniyor, boş, hata, dolu, uzun içerik. Virgil'de ayrıca limit ve oturum süresi dolması.
- Bitirmeden önce `deno lint site` ve `deno test --allow-read --allow-write --allow-env site/` çalıştır, ekran görüntüsü alıp kendin incele (adımlar skill'de). Büyük değişiklikte `ui-reviewer` subagent'ından inceleme iste.
