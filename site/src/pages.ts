/**
 * Page definitions and copy for the static site (English + Turkish).
 *
 * Only claims the app really supports are made here (see lib/features and the
 * privacy policy). The app is only on Google Play so far.
 */
import { CONTACT_EMAIL, type Lang, type PageRef } from "./layout.ts";
import { VIRGIL_SCRIPTS, virgilBody } from "./virgil.ts";
import { CONFIRMED_SCRIPTS, confirmedBody } from "./confirmed.ts";

// Filled in by build.ts (reads content/privacy-policy.<lang>.html).
export const privacyFragment: Record<Lang, string> = { en: "", tr: "" };

const mail = `<a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>`;

export const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.rubricator";

// ---------------------------------------------------------------------------
// Home (landing)
// ---------------------------------------------------------------------------
const home = (lang: Lang): string => {
  const t = lang === "en"
    ? {
      eyebrow: "Books, tracked and discovered",
      h1: "Find your next book. Remember every one you read.",
      lead:
        "Rubricator helps you discover books, keep track of your reading and get recommendations from Virgil, an AI reading guide.",
      getApp: "Get the Android app",
      tryVirgil: "Try Virgil",
      about: "About Rubricator",
      // Hero illustration: a glimpse of the app (sample data, aria-hidden).
      art: {
        reading: "Reading",
        bookTitle: "Foggy Harbour",
        bookAuthor: "E. Kaya",
        pages: "Page 142 of 220 · 35 min today",
        streak: "Reading streak",
        streakDays: "days",
        streakWeek: "5 of 7 days this week",
        list: "List",
        listName: "Summer reads",
        listMeta: "8 books · 3 followers",
        listCover: "Shore",
      },
      virgilTitle: "Meet Virgil, your reading guide",
      virgilBody:
        "Describe the book you're in the mood for, in your own words, and Virgil suggests what to read next. Try it right here in your browser with your Rubricator account.",
      steps: [
        [
          "1. Describe it",
          "A mood, a plot, a topic or a book you loved: write it the way you'd tell a friend.",
        ],
        [
          "2. Get recommendations",
          "Virgil searches by meaning, not just keywords, and answers with books that fit.",
        ],
        [
          "3. Keep reading",
          "Add what you like to your lists and shelves in the Rubricator mobile app.",
        ],
      ],
      featuresTitle: "What Rubricator does",
      features: [
        [
          "Discover",
          "Search a global catalog and a Turkish catalog, browse genre shelves and find books by describing them.",
        ],
        [
          "Track your reading",
          "Mark books as to-read, reading or finished, log minutes and pages and keep your reading streak.",
        ],
        [
          "Write it down",
          "Rate and review books, save quotes and keep private or public notes.",
        ],
        [
          "Share lists",
          "Build reading lists, share them and follow lists made by other readers.",
        ],
      ],
      appTitle: "Built for the phone in your pocket",
      appBody:
        "The full Rubricator experience, with shelves, reading logs, notes, lists and questions about your own PDF or EPUB, lives in the mobile app. This website introduces the project and lets you try Virgil's recommendations in your browser.",
    }
    : {
      eyebrow: "Kitaplar, takip edilir ve keşfedilir",
      h1: "Bir sonraki kitabını bul. Okuduğun her kitabı hatırla.",
      lead:
        "Rubricator; kitap keşfetmene, okumanı takip etmene ve yapay zekâ destekli okuma rehberi Virgil'den öneri almana yardımcı olur.",
      getApp: "Android uygulamasını indir",
      tryVirgil: "Virgil'i dene",
      about: "Rubricator hakkında",
      art: {
        reading: "Okuyorum",
        bookTitle: "Sisli Liman",
        bookAuthor: "E. Kaya",
        pages: "Sayfa 142 / 220 · bugün 35 dk",
        streak: "Okuma serisi",
        streakDays: "gün",
        streakWeek: "Bu hafta 5 / 7 gün",
        list: "Liste",
        listName: "Yaz listesi",
        listMeta: "8 kitap · 3 takipçi",
        listCover: "Kıyı",
      },
      virgilTitle: "Okuma rehberin Virgil ile tanış",
      virgilBody:
        "Canın hangi kitabı istiyorsa kendi cümlelerinle anlat, Virgil sıradaki okumanı önersin. Rubricator hesabınla doğrudan tarayıcında dene.",
      steps: [
        [
          "1. Anlat",
          "Bir ruh hali, bir konu, bir olay örgüsü ya da sevdiğin bir kitap: bir arkadaşına anlatır gibi yaz.",
        ],
        [
          "2. Öneri al",
          "Virgil yalnızca anahtar kelimelere değil, anlama göre arar ve sana uyan kitaplarla yanıt verir.",
        ],
        [
          "3. Okumaya devam et",
          "Beğendiklerini Rubricator mobil uygulamasında listelerine ve raflarına ekle.",
        ],
      ],
      featuresTitle: "Rubricator neler yapar?",
      features: [
        [
          "Keşfet",
          "Global ve Türkçe kataloglarda ara, tür raflarına göz at, kitapları tarif ederek bul.",
        ],
        [
          "Okumanı takip et",
          "Kitapları okunacak, okunuyor ya da bitti olarak işaretle; dakika ve sayfa kaydet, okuma serini koru.",
        ],
        [
          "Not al",
          "Kitapları puanla ve yorumla, alıntı kaydet, özel ya da herkese açık notlar tut.",
        ],
        [
          "Listeleri paylaş",
          "Okuma listeleri oluştur, paylaş ve diğer okurların listelerini takip et.",
        ],
      ],
      appTitle: "Cebindeki telefon için tasarlandı",
      appBody:
        "Rubricator'ın tam deneyimi (raflar, okuma kayıtları, notlar, listeler ve kendi PDF ya da EPUB dosyan hakkında soru sorma) mobil uygulamada. Bu web sitesi projeyi tanıtır ve Virgil'in önerilerini tarayıcında denemeni sağlar.",
    };
  return `    <section class="hero">
      <div class="container">
        <div>
          <p class="eyebrow">${t.eyebrow}</p>
          <h1>${t.h1}</h1>
          <p class="lead">${t.lead}</p>
          <div class="actions">
            <a class="btn store" href="${PLAY_STORE_URL}" rel="noopener"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3v12M7 10l5 5 5-5M5 21h14"/></svg>${t.getApp}</a>
            <a class="btn secondary" href="{{link:virgil}}">${t.tryVirgil}</a>
          </div>
        </div>
        <div class="hero-art" aria-hidden="true">
          <div class="tile tile-reading">
            <p class="tile-label">${t.art.reading}</p>
            <div class="reading">
              <div class="tcover tc-ink">${t.art.bookTitle}<small>${t.art.bookAuthor}</small></div>
              <div>
                <p class="reading-title">${t.art.bookTitle}</p>
                <p class="reading-author">${t.art.bookAuthor}</p>
                <div class="progress"><span></span></div>
                <p class="reading-pages">${t.art.pages}</p>
              </div>
            </div>
          </div>
          <div class="tile">
            <p class="tile-label">${t.art.streak}</p>
            <p class="streak">12 <small>${t.art.streakDays}</small></p>
            <div class="week"><span class="on"></span><span class="on"></span><span class="on"></span><span class="on"></span><span class="on"></span><span></span><span></span></div>
            <p class="tile-note">${t.art.streakWeek}</p>
          </div>
          <div class="tile">
            <p class="tile-label">${t.art.list}</p>
            <p class="list-name">${t.art.listName}</p>
            <p class="tile-note">${t.art.listMeta}</p>
            <div class="fan"><div class="tcover tc-red"></div><div class="tcover tc-soft"></div><div class="tcover tc-ink">${t.art.listCover}</div></div>
          </div>
        </div>
      </div>
    </section>
    <section class="section alt">
      <div class="container">
        <h2>${t.virgilTitle}</h2>
        <p class="lead">${t.virgilBody}</p>
        <div class="cards">
${
    t.steps.map(([h, p]) =>
      `          <div class="card"><h3>${h}</h3><p>${p}</p></div>`
    ).join("\n")
  }
        </div>
        <p><a class="btn" href="{{link:virgil}}">${t.tryVirgil}</a></p>
      </div>
    </section>
    <section class="section">
      <div class="container">
        <h2>${t.featuresTitle}</h2>
        <div class="cards">
${
    t.features.map(([h, p]) =>
      `          <div class="card"><h3>${h}</h3><p>${p}</p></div>`
    ).join("\n")
  }
        </div>
        <div class="note"><p><strong>${t.appTitle}.</strong> ${t.appBody}</p></div>
      </div>
    </section>`;
};

// ---------------------------------------------------------------------------
// About
// ---------------------------------------------------------------------------
const about = (lang: Lang): string =>
  lang === "en"
    ? `    <div class="page container">
      <article class="prose">
        <h1>About Rubricator</h1>
        <p class="lead">Rubricator is a reading companion: a place to discover books, keep track of what you read and talk about it.</p>

        <h2>What you can do</h2>
        <ul>
          <li><strong>Discover books</strong> in a global catalog and in a Turkish catalog, and add a Turkish book that is missing.</li>
          <li><strong>Track your reading</strong>: to-read, reading and finished shelves, reading logs and streaks.</li>
          <li><strong>Rate, review and take notes</strong>, including spoiler-safe reviews and saved quotes.</li>
          <li><strong>Make and share lists</strong> of books, and follow other readers' lists.</li>
          <li><strong>Ask Virgil</strong>, an AI reading guide: describe what you're in the mood for and get recommendations, in the app or <a href="{{link:virgil}}">right here on the website</a>. In the mobile app you can also ask questions about a PDF or EPUB you upload.</li>
        </ul>

        <h2>How we treat your data</h2>
        <p>We don't sell personal data. Your reading history and content belong to your account, and you can ask us to delete it at any time. Read the <a href="{{link:privacy}}">privacy policy</a> for the details, including which third-party services we use, and see how to <a href="{{link:deletion}}">delete your account</a>.</p>

        <h2>Who builds it</h2>
        <p>Rubricator is built and maintained by an independent developer, İsmail Yücel Ölmez. It's in active development, and feedback shapes what comes next.</p>

        <div class="note"><p>Questions, ideas or bug reports? Write to ${mail}.</p></div>
      </article>
    </div>`
    : `    <div class="page container">
      <article class="prose">
        <h1>Rubricator hakkında</h1>
        <p class="lead">Rubricator bir okuma arkadaşı: kitap keşfetmek, okuduklarını takip etmek ve onlar hakkında konuşmak için bir yer.</p>

        <h2>Neler yapabilirsin?</h2>
        <ul>
          <li>Global ve Türkçe kataloglarda <strong>kitap keşfet</strong>; katalogda olmayan bir Türkçe kitabı kendin ekle.</li>
          <li><strong>Okumanı takip et</strong>: okunacak, okunuyor ve bitti rafları, okuma kayıtları ve seriler.</li>
          <li><strong>Puanla, yorumla ve not al</strong>; spoiler içeren yorumları işaretle, alıntıları kaydet.</li>
          <li><strong>Kitap listeleri oluştur ve paylaş</strong>, diğer okurların listelerini takip et.</li>
          <li><strong>Virgil'e sor</strong>: yapay zekâ destekli okuma rehberine canının ne istediğini anlat, uygulamada ya da <a href="{{link:virgil}}">doğrudan bu web sitesinde</a> öneri al. Mobil uygulamada yüklediğin bir PDF ya da EPUB hakkında da soru sorabilirsin.</li>
        </ul>

        <h2>Verilerine nasıl davranıyoruz?</h2>
        <p>Kişisel verileri satmıyoruz. Okuma geçmişin ve içeriklerin hesabına aittir ve dilediğin zaman silinmesini isteyebilirsin. Kullandığımız üçüncü taraf hizmetler dahil ayrıntılar için <a href="{{link:privacy}}">gizlilik politikasına</a> bak; hesabını nasıl sileceğini <a href="{{link:deletion}}">Hesap silme</a> sayfasında bulabilirsin.</p>

        <h2>Kim geliştiriyor?</h2>
        <p>Rubricator, bağımsız geliştirici İsmail Yücel Ölmez tarafından geliştirilir ve sürdürülür. Proje aktif olarak geliştiriliyor ve geri bildirimler sıradaki adımları şekillendiriyor.</p>

        <div class="note"><p>Sorun, fikir ya da hata bildirimi için ${mail} adresine yazabilirsin.</p></div>
      </article>
    </div>`;

// ---------------------------------------------------------------------------
// Contact
// ---------------------------------------------------------------------------
const contact = (lang: Lang): string =>
  lang === "en"
    ? `    <div class="page container">
      <article class="prose">
        <h1>Contact</h1>
        <p class="lead">The quickest way to reach us is email.</p>

        <div class="contact-box">
          <dl>
            <dt>Email</dt>
            <dd>${mail}</dd>
            <dt>Account deletion</dt>
            <dd>See <a href="{{link:deletion}}">how to request it</a>; use the subject <em>Account Deletion Request</em>.</dd>
            <dt>Privacy questions and requests</dt>
            <dd>Write to the same address, or read the <a href="{{link:privacy}}">privacy policy</a>.</dd>
          </dl>
        </div>

        <h2>Helpful details for bug reports</h2>
        <ul>
          <li>What you were doing and what you expected to happen.</li>
          <li>Your device model and operating system, and the app version (Profile screen).</li>
          <li>A screenshot, if it helps. Please don't send passwords.</li>
        </ul>
      </article>
    </div>`
    : `    <div class="page container">
      <article class="prose">
        <h1>İletişim</h1>
        <p class="lead">Bize ulaşmanın en hızlı yolu e-postadır.</p>

        <div class="contact-box">
          <dl>
            <dt>E-posta</dt>
            <dd>${mail}</dd>
            <dt>Hesap silme</dt>
            <dd><a href="{{link:deletion}}">Nasıl talep edileceğine</a> bak; konu satırına <em>Account Deletion Request</em> yaz.</dd>
            <dt>Gizlilik soruları ve talepleri</dt>
            <dd>Aynı adrese yazabilir ya da <a href="{{link:privacy}}">gizlilik politikasını</a> okuyabilirsin.</dd>
          </dl>
        </div>

        <h2>Hata bildirimi için faydalı bilgiler</h2>
        <ul>
          <li>Ne yapıyordun ve ne olmasını bekliyordun?</li>
          <li>Cihaz modelin, işletim sistemin ve uygulama sürümün (Profil ekranı).</li>
          <li>İşe yarayacaksa bir ekran görüntüsü. Lütfen şifre göndermeyin.</li>
        </ul>
      </article>
    </div>`;

// ---------------------------------------------------------------------------
// Account deletion (Play Console requires a public URL for this)
// ---------------------------------------------------------------------------
const deletion = (lang: Lang): string =>
  lang === "en"
    ? `    <div class="page container">
      <article class="prose">
        <h1>Rubricator Account Deletion Request</h1>
        <p>If you use the <strong>Rubricator</strong> mobile app and want to delete your account, you can submit a request by email.</p>

        <div class="note">
          <p><strong>Email:</strong> ${mail}<br>
          <strong>Subject:</strong> "Account Deletion Request"</p>
        </div>

        <h2>How to request deletion</h2>
        <ol>
          <li>Open your email app.</li>
          <li>Send an email to <strong>${CONTACT_EMAIL}</strong>.</li>
          <li>Use the subject line: <strong>"Account Deletion Request"</strong>.</li>
          <li>In the message body, include your <strong>registered email address</strong> used in Rubricator.</li>
          <li>(Optional) Add any additional details that help us identify your account.</li>
        </ol>

        <h2>What data will be deleted</h2>
        <ul>
          <li>Your Rubricator account profile and personal account information.</li>
          <li>Data associated with your account within the app.</li>
        </ul>

        <h2>Data retention policy</h2>
        <ul>
          <li>Account and personal data will be deleted within <strong>7 days</strong> of verifying your request.</li>
          <li>Some data may be retained for legal reasons for up to <strong>30 days</strong>.</li>
        </ul>

        <p class="meta">If you have any questions, contact us at ${mail}.</p>
      </article>
    </div>`
    : `    <div class="page container">
      <article class="prose">
        <h1>Rubricator Hesap Silme Talebi</h1>
        <p><strong>Rubricator</strong> mobil uygulamasını kullanıyor ve hesabını silmek istiyorsan, talebini e-posta ile iletebilirsin.</p>

        <div class="note">
          <p><strong>E-posta:</strong> ${mail}<br>
          <strong>Konu:</strong> "Account Deletion Request"</p>
        </div>

        <h2>Silme talebi nasıl yapılır?</h2>
        <ol>
          <li>E-posta uygulamanı aç.</li>
          <li><strong>${CONTACT_EMAIL}</strong> adresine e-posta gönder.</li>
          <li>Konu satırına şunu yaz: <strong>"Account Deletion Request"</strong>.</li>
          <li>Mesajın içine Rubricator'da kayıtlı olan <strong>e-posta adresini</strong> yaz.</li>
          <li>(İsteğe bağlı) Hesabını tanımamıza yardımcı olacak ek bilgi ekle.</li>
        </ol>

        <h2>Hangi veriler silinir?</h2>
        <ul>
          <li>Rubricator hesap profilin ve kişisel hesap bilgilerin.</li>
          <li>Uygulama içinde hesabınla ilişkili veriler.</li>
        </ul>

        <h2>Veri saklama süresi</h2>
        <ul>
          <li>Hesap ve kişisel veriler, talebin doğrulanmasından sonra <strong>7 gün</strong> içinde silinir.</li>
          <li>Bazı veriler yasal nedenlerle en fazla <strong>30 gün</strong> saklanabilir.</li>
        </ul>

        <p class="meta">Sorun olursa ${mail} adresinden bize ulaşabilirsin.</p>
      </article>
    </div>`;

// ---------------------------------------------------------------------------
// Privacy policy (English is the source of truth; the Turkish text is a translation)
// ---------------------------------------------------------------------------
const privacy = (lang: Lang): string =>
  `    <div class="page container">
      <article class="prose">
${privacyFragment[lang]}
      </article>
    </div>`;

// ---------------------------------------------------------------------------
// 404
// ---------------------------------------------------------------------------
const notFound = (lang: Lang): string =>
  lang === "en"
    ? `    <div class="page container">
      <article class="prose">
        <h1>Page not found</h1>
        <p class="lead">That page doesn't exist or has moved.</p>
        <p><a class="btn" href="{{link:home}}">Back to the home page</a></p>
      </article>
    </div>`
    : `    <div class="page container">
      <article class="prose">
        <h1>Sayfa bulunamadı</h1>
        <p class="lead">Bu sayfa yok ya da taşınmış.</p>
        <p><a class="btn" href="{{link:home}}">Ana sayfaya dön</a></p>
      </article>
    </div>`;

export const PAGES: PageRef[] = [
  {
    id: "home",
    dir: { en: "", tr: "" },
    nav: true,
    title: {
      en: "Rubricator: book discovery, reading tracking and AI recommendations",
      tr: "Rubricator: kitap keşfi, okuma takibi ve yapay zekâ önerileri",
    },
    description: {
      en:
        "Discover books, keep track of your reading and get recommendations from Virgil, an AI reading guide.",
      tr:
        "Kitap keşfet, okumanı takip et ve yapay zekâ destekli okuma rehberi Virgil'den öneri al.",
    },
    body: home,
  },
  {
    id: "virgil",
    dir: { en: "virgil", tr: "virgil" },
    nav: true,
    scripts: VIRGIL_SCRIPTS,
    title: {
      en: "Virgil: AI book recommendations | Rubricator",
      tr: "Virgil: yapay zekâ kitap önerileri | Rubricator",
    },
    description: {
      en:
        "Describe the book you're in the mood for and get recommendations from Virgil, Rubricator's AI reading guide.",
      tr:
        "Canının çektiği kitabı anlat, Rubricator'ın yapay zekâ okuma rehberi Virgil'den öneri al.",
    },
    body: virgilBody,
  },
  {
    id: "about",
    dir: { en: "about", tr: "hakkimizda" },
    nav: true,
    title: { en: "About | Rubricator", tr: "Hakkımızda | Rubricator" },
    description: {
      en: "What Rubricator is, what it does and how it treats your data.",
      tr: "Rubricator nedir, neler yapar ve verilerine nasıl davranır.",
    },
    body: about,
  },
  {
    id: "contact",
    dir: { en: "contact", tr: "iletisim" },
    nav: true,
    title: { en: "Contact | Rubricator", tr: "İletişim | Rubricator" },
    description: {
      en: "Get in touch with the Rubricator team by email.",
      tr: "Rubricator ekibiyle e-posta yoluyla iletişime geç.",
    },
    body: contact,
  },
  {
    // Existing public URL /privacy-policy.html must keep working (Play Console).
    id: "privacy",
    dir: { en: "privacy-policy", tr: "gizlilik-politikasi" },
    file: { en: "privacy-policy.html" },
    title: {
      en: "Privacy Policy | Rubricator",
      tr: "Gizlilik Politikası | Rubricator",
    },
    description: {
      en: "How Rubricator collects, uses, shares and protects your data.",
      tr: "Rubricator verilerini nasıl toplar, kullanır, paylaşır ve korur.",
    },
    body: privacy,
  },
  {
    id: "deletion",
    dir: { en: "account-deletion", tr: "hesap-silme" },
    title: {
      en: "Account Deletion Request | Rubricator",
      tr: "Hesap Silme Talebi | Rubricator",
    },
    description: {
      en: "How to request deletion of your Rubricator account and data.",
      tr: "Rubricator hesabının ve verilerinin silinmesi nasıl talep edilir.",
    },
    body: deletion,
  },
  {
    // Where Supabase sends the visitor after they click the signup
    // confirmation link (see auth.site_url / additional_redirect_urls in
    // supabase/config.toml). Not in the nav; kept out of the sitemap since it
    // only makes sense arrived at from that email.
    id: "confirmed",
    dir: { en: "auth/confirmed", tr: "auth/onay" },
    noindex: true,
    scripts: CONFIRMED_SCRIPTS,
    title: {
      en: "You're confirmed | Rubricator",
      tr: "Onaylandı | Rubricator",
    },
    description: {
      en: "Your Rubricator email address is confirmed.",
      tr: "Rubricator e-posta adresin onaylandı.",
    },
    body: confirmedBody,
  },
  {
    id: "notfound",
    dir: {},
    file: { en: "404.html" },
    noindex: true,
    title: {
      en: "Page not found | Rubricator",
      tr: "Sayfa bulunamadı | Rubricator",
    },
    description: { en: "Page not found.", tr: "Sayfa bulunamadı." },
    body: notFound,
  },
];
