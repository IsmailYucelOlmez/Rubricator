# Rubricator (bookapp)

## Repo haritası
- `lib/`, `android/`, `ios/` … — Flutter mobil uygulama (tema: `lib/core/theme/`)
- `site/` — web sitesi (rubricator.site), Deno ile üretilen statik site. Kendi kuralları `site/CLAUDE.md` içinde.
- `supabase/` — migration'lar ve edge function'lar
- `xdocs/` — özellik dokümanları (`xdocs/design.md` eski paleti içerir; güncel web tasarımı için `design/DESIGN.md`)

## Tasarım
- Web UI işlerinde (`site/`) önce `design/DESIGN.md` oku, `rubricator-web` skill'ini kullan.
- Mobil tasarım bu kurulumun kapsamı dışında. Mobil UI için mevcut `lib/core/theme/` ve `lib/core/widgets/` desenlerine uy.
