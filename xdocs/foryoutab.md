# Liste Öneri Sistemi (For You sekmesi)

## Amaç

Lists sayfasındaki **For You** sekmesi, kullanıcının okuma ve liste etkileşim geçmişine göre kişiselleştirilmiş **liste** önerileri sunar. ML yok; PostgreSQL + hibrit puanlama + gece batch.

## Veri modeli

### `list_recommendations`

| Alan | Açıklama |
|------|----------|
| user_id | Hedef kullanıcı |
| list_id | Önerilen liste |
| score | 0–100 hibrit skor |
| generated_at | Hesaplama zamanı |

### `user_list_recommendation_state`

| Alan | Açıklama |
|------|----------|
| recommendation_dirty | Yeniden hesaplama gerekli mi |
| last_computed_at | Son batch zamanı |

## Hibrit puanlama

```
ListRecommendationScore =
  (ContentScore × 0.50)
+ (SimilarUserScore × 0.30)
+ (PopularityScore × 0.20)
```

- **Content:** Tamamlanan / favori / puan≥8 kitaplar ile `list_items` eşleşmesi + yazar eşleşmesi
- **Similar user:** Ortak beğenilen/kaydedilen listeler + ortak okunan kitaplar
- **Popularity:** like + save + comment (normalize)

## Dirty flag tetikleyicileri

- `user_books`: status / is_favorite değişimi
- `ratings`: insert / update / delete
- `list_likes`, `saved_lists`: insert / delete

## Batch

- Fonksiyon: `process_dirty_list_recommendations_batch()`
- Cron: her gece 02:00 UTC (`process-dirty-list-recommendations`)
- Kapsam: son 24 saatte dirty olan kullanıcılar (max 500/run)

## Flutter

- `get_list_recommendations` RPC → `SupabaseListsRepository.getRecommendedLists`
- `forYouListsProvider`: önceden hesaplanmış sonuçlar; boşsa `getPopularLists` fallback
- Tüm skorlama backend'de; mobil yalnızca görüntüler

## Migration dosyaları

1. `20260625000000_list_recommendations_schema.sql` — tablolar, RLS, dirty trigger'lar
2. `20260625000001_list_recommendations_compute_cron.sql` — compute RPC + cron

## Manuel test (Supabase SQL)

```sql
-- Tek kullanıcı için hesapla
select public.compute_list_recommendations_for_user('<user-uuid>');

-- Batch
select public.process_dirty_list_recommendations_batch();
```
