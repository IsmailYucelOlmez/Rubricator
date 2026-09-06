import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  parseDrListingPage,
  parseDrProductPage,
  parseKitapyurduListingPage as parseListingPage,
  parseKitapyurduProductPage as parseProductPage,
} from "./index.ts";

const fixturesDir = new URL("./fixtures/", import.meta.url);

function readFixture(name: string): Promise<string> {
  return Deno.readTextFile(new URL(name, fixturesDir));
}

Deno.test("parseListingPage extracts canonical, deduped product URLs", async () => {
  const html = await readFixture("search_results.html");
  const urls = parseListingPage(html);

  assertEquals(urls, [
    "https://www.kitapyurdu.com/kitap/sana-anlatacak-fantastik-seylerim-olacak/763865.html",
    "https://www.kitapyurdu.com/kitap/seker-portakali-ciltsiz/10139.html",
  ]);
});

Deno.test("parseProductPage extracts isbn, title, author, publisher, description, image, page count", async () => {
  const html = await readFixture("product_with_isbn.html");
  const book = parseProductPage(
    html,
    "https://www.kitapyurdu.com/kitap/sana-anlatacak-fantastik-seylerim-olacak/763865.html",
  );

  assert(book !== null);
  assertEquals(book.isbn, "9786255695277");
  assertEquals(book.title, "Sana Anlatacak Fantastik Şeylerim Olacak");
  assertEquals(book.author, "Ayşe Şasa");
  assertEquals(book.publisher, "KETEBE YAYINEVİ");
  assertEquals(book.pageCount, 208);
  assert(book.description?.includes("Türk sineması"));
  assertEquals(
    book.imageUrl,
    "https://img.kitapyurdu.com/v1/getImage/fn:12275654/wh:42fef87ca",
  );
  assertEquals(
    book.sourceUrl,
    "https://www.kitapyurdu.com/kitap/sana-anlatacak-fantastik-seylerim-olacak/763865.html",
  );
});

Deno.test("parseProductPage returns null when no ISBN is present", async () => {
  const html = await readFixture("product_without_isbn.html");
  const book = parseProductPage(
    html,
    "https://www.kitapyurdu.com/kitap/yayimlanacak-bir-kitap/1.html",
  );

  assertEquals(book, null);
});

Deno.test("parseDrListingPage extracts absolute, deduped product URLs", async () => {
  const html = await readFixture("dr_listing.html");
  const urls = parseDrListingPage(html);

  assertEquals(urls, [
    "https://www.dr.com.tr/kitap/evelyn-hardcastle%E2%80%99in-yedi-olumu/stuart-turton/edebiyat/roman/fantastik/urunno=0001877095001",
    "https://www.dr.com.tr/kitap/ben-kirke/madeline-miller/edebiyat/roman/fantastik/urunno=0001836978001",
  ]);
});

Deno.test("parseDrProductPage extracts isbn/title/author/publisher/description/image/page count from JSON-LD, tolerating unescaped newlines", async () => {
  const html = await readFixture("dr_product_with_isbn.html");
  const book = parseDrProductPage(
    html,
    "https://www.dr.com.tr/kitap/evelyn-hardcastlein-yedi-olumu/urunno=0001877095001",
  );

  assert(book !== null);
  assertEquals(book.isbn, "9786257913478");
  assertEquals(book.title, "Evelyn Hardcastleın Yedi Ölümü");
  assertEquals(book.author, "Stuart Turton");
  assertEquals(book.publisher, "İthaki Yayınları");
  assertEquals(book.pageCount, 456);
  assert(book.description?.includes("Blackheath Malikânesi"));
  assertEquals(
    book.imageUrl,
    "https://i.dr.com.tr/cache/600x600-0/originals/0001877095001-1.jpg",
  );
});

Deno.test("parseDrProductPage returns null when the Book JSON-LD has no gtin13", async () => {
  const html = await readFixture("dr_product_without_isbn.html");
  const book = parseDrProductPage(
    html,
    "https://www.dr.com.tr/kitap/yayimlanacak-bir-kitap",
  );

  assertEquals(book, null);
});
