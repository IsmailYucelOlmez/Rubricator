/**
 * Page definitions and copy for the static site (English + Turkish).
 *
 * Only claims the app really supports are made here (see lib/features and the
 * privacy policy). The app is only on Google Play so far.
 */
import {
  type BuildContext,
  CONTACT_EMAIL,
  type Lang,
  type PageRef,
} from "./layout.ts";
import { QUILL_ICON, VIRGIL_SCRIPTS, virgilBody } from "./virgil.ts";
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
      virgilTagline: "Virgil will guide your reading journey.",
      // The phone shows Virgil's recommendation screen (sample data, aria-hidden).
      phone: {
        query: "a slow mystery in a seaside town",
        books: [
          ["The Lighthouse Murder", "M. Aras"],
          ["Foggy Harbour", "E. Kaya"],
          ["The Last Ferry", "D. Tan"],
          ["House on the Shore", "S. Ay"],
        ],
      },
      virgilBody:
        "Describe the book you're in the mood for, in your own words, and Virgil suggests what to read next. Try it right here in your browser with your Rubricator account.",
      steps: [
        [
          "Describe it",
          "A mood, a plot, a topic or a book you loved: write it the way you'd tell a friend.",
        ],
        [
          "Get recommendations",
          "Virgil searches by meaning, not just keywords, and answers with books that fit.",
        ],
        [
          "Keep reading",
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
      virgilTagline: "Virgil okuma yolculuğuna rehberlik eder.",
      phone: {
        query: "sahil kasabasında yavaş bir polisiye",
        books: [
          ["Deniz Feneri Cinayeti", "M. Aras"],
          ["Sisli Liman", "E. Kaya"],
          ["Son Vapur", "D. Tan"],
          ["Kıyıdaki Ev", "S. Ay"],
        ],
      },
      virgilBody:
        "Canın hangi kitabı istiyorsa kendi cümlelerinle anlat, Virgil sıradaki okumanı önersin. Rubricator hesabınla doğrudan tarayıcında dene.",
      steps: [
        [
          "Anlat",
          "Bir ruh hali, bir konu, bir olay örgüsü ya da sevdiğin bir kitap: bir arkadaşına anlatır gibi yaz.",
        ],
        [
          "Öneri al",
          "Virgil yalnızca anahtar kelimelere değil, anlama göre arar ve sana uyan kitaplarla yanıt verir.",
        ],
        [
          "Okumaya devam et",
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
    <section class="section v-showcase">
      <div class="container">
        <div>
          <h2 class="v-brand"><span class="sr-only">${t.virgilTitle}</span><span class="v-word" aria-hidden="true">Virgil</span> <span class="v-badge" aria-hidden="true">BETA</span></h2>
          <p class="v-tagline">${t.virgilTagline}</p>
          <p class="v-lead">${t.virgilBody}</p>
          <ol class="v-steps">
${
    t.steps.map(([h, p]) =>
      `            <li><div><h3>${h}</h3><p>${p}</p></div></li>`
    ).join("\n")
  }
          </ol>
          <a class="btn" href="{{link:virgil}}">${t.tryVirgil}</a>
        </div>
        <div class="v-phone" aria-hidden="true">
          <p class="v-phone-brand"><span class="v-word">Virgil</span> <span class="v-badge">BETA</span></p>
          <div class="v-phone-body">
            <p class="v-query">${t.phone.query}</p>
            <ul class="v-grid">
${
    t.phone.books.map(([title, author], i) =>
      `              <li><div class="tcover ${
        ["tc-ink", "tc-red", "tc-soft", "tc-ink"][i]
      }">${title}<small>${author}</small></div><span class="v-card-title">${title}</span><span class="v-card-author">${author}</span></li>`
    ).join("\n")
  }
            </ul>
          </div>
          <div class="v-bar"><span class="v-fake-input">${t.phone.query}</span><span class="v-round v-submit">${QUILL_ICON}</span></div>
        </div>
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

        <div class="note"><p>Sorun, fikir ya da hata bildirimi için ${mail} adresine yazabilirsin.</p></div>
      </article>
    </div>`;

// ---------------------------------------------------------------------------
// Contact
// ---------------------------------------------------------------------------
const CONTACT_STRINGS = {
  en: {
    h1: "Contact",
    lead: "Write to us with the form below, or by email.",
    formTitle: "Send a message",
    name: "Name (optional)",
    email: "Your email",
    emailHint: "We'll reply to this address.",
    message: "Message",
    send: "Send message",
    privacy:
      "Your message and email address are emailed to us (through our email provider, Resend) and used only to reply. See the",
    privacyLink: "privacy policy",
    noscript: "The form needs JavaScript. You can also email us at",
    unavailable: "The form isn't available right now. Please email us at",
    otherTitle: "Other ways to reach us",
    bugsTitle: "Helpful details for bug reports",
    // Messages (contact.js)
    sending: "Sending…",
    sent: "Thanks! Your message was sent. We'll reply by email.",
    errNameLong: "Keep the name under 100 characters.",
    errEmailRequired: "Email is required.",
    errEmailInvalid: "Enter a valid email address.",
    errMessageRequired: "Write a message.",
    errMessageShort: "Write at least 10 characters.",
    errMessageLong: "Keep it under 5000 characters.",
    errRateLimit:
      "You've sent several messages recently. Please try again in an hour.",
    errNetwork: "Couldn't reach the server. Check your connection and try again.",
    errServer:
      "Your message couldn't be sent. Please try again later or email us directly.",
  },
  tr: {
    h1: "İletişim",
    lead: "Aşağıdaki formla ya da e-postayla bize yazabilirsin.",
    formTitle: "Mesaj gönder",
    name: "Adın (isteğe bağlı)",
    email: "E-posta adresin",
    emailHint: "Yanıtı bu adrese göndereceğiz.",
    message: "Mesajın",
    send: "Mesajı gönder",
    privacy:
      "Mesajın ve e-posta adresin bize e-postayla (e-posta sağlayıcımız Resend üzerinden) iletilir ve yalnızca yanıt vermek için kullanılır. Ayrıntılar için",
    privacyLink: "gizlilik politikası",
    noscript: "Form için JavaScript gerekiyor. Bize e-postayla da yazabilirsin:",
    unavailable: "Form şu an kullanılamıyor. Lütfen e-postayla yaz:",
    otherTitle: "Bize ulaşmanın diğer yolları",
    bugsTitle: "Hata bildirimi için faydalı bilgiler",
    sending: "Gönderiliyor…",
    sent: "Teşekkürler! Mesajın gönderildi. E-postayla yanıt vereceğiz.",
    errNameLong: "Ad 100 karakteri geçmesin.",
    errEmailRequired: "E-posta gerekli.",
    errEmailInvalid: "Geçerli bir e-posta gir.",
    errMessageRequired: "Bir mesaj yaz.",
    errMessageShort: "En az 10 karakter yaz.",
    errMessageLong: "5000 karakterin altında tut.",
    errRateLimit:
      "Kısa sürede birkaç mesaj gönderdin. Lütfen bir saat sonra tekrar dene.",
    errNetwork: "Sunucuya ulaşılamadı. Bağlantını kontrol edip tekrar dene.",
    errServer:
      "Mesajın gönderilemedi. Lütfen daha sonra tekrar dene ya da doğrudan e-posta gönder.",
  },
} as const;

const escAttr = (v: string) =>
  v.replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;");

/** JSON that is safe inside a <script type="application/json"> block. */
const jsonIsland = (value: unknown) =>
  JSON.stringify(value).replaceAll("<", "\\u003c");

const contact = (lang: Lang, ctx: BuildContext): string => {
  const t = CONTACT_STRINGS[lang];
  const configured = Boolean(ctx.supabaseUrl && ctx.supabaseAnonKey);
  const config = configured
    ? ` data-supabase-url="${escAttr(ctx.supabaseUrl!)}" data-anon-key="${
      escAttr(ctx.supabaseAnonKey!)
    }"`
    : "";
  const info = lang === "en"
    ? `<dl>
            <dt>Email</dt>
            <dd>${mail}</dd>
            <dt>Account deletion</dt>
            <dd>See <a href="{{link:deletion}}">how to request it</a>; use the subject <em>Account Deletion Request</em>.</dd>
            <dt>Privacy questions and requests</dt>
            <dd>Write to the same address, or read the <a href="{{link:privacy}}">privacy policy</a>.</dd>
          </dl>`
    : `<dl>
            <dt>E-posta</dt>
            <dd>${mail}</dd>
            <dt>Hesap silme</dt>
            <dd><a href="{{link:deletion}}">Nasıl talep edileceğine</a> bak; konu satırına <em>Account Deletion Request</em> yaz.</dd>
            <dt>Gizlilik soruları ve talepleri</dt>
            <dd>Aynı adrese yazabilir ya da <a href="{{link:privacy}}">gizlilik politikasını</a> okuyabilirsin.</dd>
          </dl>`;
  const bugs = lang === "en"
    ? `<li>What you were doing and what you expected to happen.</li>
          <li>Your device model and operating system, and the app version (Profile screen).</li>
          <li>A screenshot, if it helps (send it by email). Please don't send passwords.</li>`
    : `<li>Ne yapıyordun ve ne olmasını bekliyordun?</li>
          <li>Cihaz modelin, işletim sistemin ve uygulama sürümün (Profil ekranı).</li>
          <li>İşe yarayacaksa bir ekran görüntüsü (e-postayla gönder). Lütfen şifre göndermeyin.</li>`;
  return `    <div class="page container" id="contact" data-lang="${lang}"${config}>
      <article class="prose">
        <h1>${t.h1}</h1>
        <p class="lead">${t.lead}</p>

        <section class="contact-form" aria-labelledby="contact-form-title">
          <h2 id="contact-form-title">${t.formTitle}</h2>
          <noscript><div class="note"><p>${t.noscript} ${mail}.</p></div></noscript>
          <div class="note"${configured ? " hidden" : ""}><p>${t.unavailable} ${mail}.</p></div>
          <p class="status" id="status" role="status" aria-live="polite" hidden></p>
          <form class="panel" id="form-contact" method="post" action="#" novalidate hidden>
            <div class="field"><label for="contact-name">${t.name}</label>
              <input id="contact-name" name="name" type="text" autocomplete="name" maxlength="100"></div>
            <div class="field"><label for="contact-email">${t.email}</label>
              <input id="contact-email" name="email" type="email" autocomplete="email" maxlength="254" aria-describedby="contact-email-hint" required>
              <p class="hint" id="contact-email-hint">${t.emailHint}</p></div>
            <div class="field"><label for="contact-message">${t.message}</label>
              <textarea id="contact-message" name="message" rows="6" maxlength="5000" required></textarea></div>
            <div class="field hp" aria-hidden="true"><label for="contact-website">Website</label>
              <input id="contact-website" name="website" type="text" tabindex="-1" autocomplete="off"></div>
            <p class="hint">${t.privacy} <a href="{{link:privacy}}">${t.privacyLink}</a>.</p>
            <div class="actions"><button class="btn" type="submit">${t.send}</button></div>
          </form>
        </section>

        <h2>${t.otherTitle}</h2>
        <div class="contact-box">
          ${info}
        </div>

        <h2>${t.bugsTitle}</h2>
        <ul>
          ${bugs}
        </ul>
      </article>
      <script type="application/json" id="i18n">${jsonIsland(t)}</script>
    </div>`;
};

// ---------------------------------------------------------------------------
// Account deletion (Play Console requires a public URL for this)
// ---------------------------------------------------------------------------
const deletion = (lang: Lang): string =>
  lang === "en"
    ? `    <div class="page container">
      <article class="prose">
        <h1>Rubricator Account Deletion Request</h1>
        <p>If you use the <strong>Rubricator</strong> app and want to delete your account, you can do it yourself in the app, or submit a request by email.</p>

        <h2>Delete it in the app</h2>
        <ol>
          <li>Open the <strong>Profile</strong> tab while signed in.</li>
          <li>Tap <strong>Delete account</strong> at the bottom of the page.</li>
          <li>Enter the verification code we email to you and confirm.</li>
        </ol>
        <p>Your account and all data associated with it are deleted immediately and permanently.</p>

        <h2>Or request it by email</h2>

        <div class="note">
          <p><strong>Email:</strong> ${mail}<br>
          <strong>Subject:</strong> "Account Deletion Request"</p>
        </div>

        <h3>How to send the request</h3>
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
        <p><strong>Rubricator</strong> uygulamasını kullanıyor ve hesabını silmek istiyorsan, bunu uygulamanın içinden kendin yapabilir ya da talebini e-posta ile iletebilirsin.</p>

        <h2>Uygulamadan sil</h2>
        <ol>
          <li>Giriş yapmışken <strong>Profil</strong> sekmesini aç.</li>
          <li>Sayfanın en altındaki <strong>Hesabı sil</strong> düğmesine dokun.</li>
          <li>E-posta adresine gönderdiğimiz doğrulama kodunu gir ve onayla.</li>
        </ol>
        <p>Hesabın ve ona bağlı tüm veriler anında ve kalıcı olarak silinir.</p>

        <h2>Ya da e-posta ile talep et</h2>

        <div class="note">
          <p><strong>E-posta:</strong> ${mail}<br>
          <strong>Konu:</strong> "Account Deletion Request"</p>
        </div>

        <h3>Talep nasıl gönderilir?</h3>
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
      en: "Get in touch with the Rubricator team: send a message or email us.",
      tr: "Rubricator ekibiyle iletişime geç: mesaj gönder ya da e-posta yaz.",
    },
    body: contact,
    scripts: ["assets/js/contact.js"],
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
