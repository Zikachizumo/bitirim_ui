# bitirim_ui

Bitirim sunucusu için **giriş / karakter oluşturma ekranı** (FiveM NUI resource).

4 adımlı akış:

1. **Cinsiyet** — erkek / kadın seçimi
2. **Kimlik** — ad & soyad
3. **Görünüm** — heritage (anne/baba karışımı), yüz özellikleri, detaylar (yaş, ten, ben/çil); canlı ped önizleme + döndürme + yüz/vücut kamerası
4. **Onay** — özet

## Kullanım (test)

```
/karakterolustur   # ekranı aç
/karakterkapat     # ekranı kapat
```

Export'lar:

```lua
exports['bitirim_ui']:OpenCharacterCreator()
exports['bitirim_ui']:CloseCharacterCreator()
exports['bitirim_ui']:GetCreationState()
```

## Yapı

| Dosya | Açıklama |
|-------|----------|
| `client.lua` | NUI callback'leri, ped önizleme, kamera, appearance uygulaması |
| `web/index.html` | UI iskeleti |
| `web/style.css` | Tasarım |
| `web/app.js` | Adım yönetimi, NUI iletişimi, klavye/mouse |

## Durum / Yapılacaklar

- [ ] İlk girişte otomatik açılma (qbx_core entegrasyonu)
- [ ] Adım 4 finalize: karakteri Qbox'a kaydet + spawn
- [x] Standalone karakter oluşturucu UI

## Bağımlılıklar

- Qbox tabanlı FiveM sunucusu (`Qbox_57FBFD.base`)
