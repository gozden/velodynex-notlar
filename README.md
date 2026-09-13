# Velodynex Notlarım — SAP Fiori / OData Öğrenme Projesi

Gözde Tümer · Velodynex · Eylül 2026
Ortam: SAP S/4HANA 2023 FPS01 Fully-Activated Appliance (SAP CAL), istemci 100

Bu klasör, Claude ile yürütülen Fiori öğrenme müfredatının (Konu 8–11) sonunda
ortaya çıkan "Notlarım" uygulamasının kaynak kodunu içerir. Dosyalar konuşma
kayıtlarından derlenmiştir; **sistemden indirilen gerçek dosyalarla
karşılaştırılıp üzerine yazılmalıdır** (özellikle `abap/` altındaki
GET_ENTITY ve tablo tanımı yeniden kurgulanmıştır — bkz. dosya içi notlar).

## Mimari

```
Tarayıcı (Fiori Launchpad, GOZDE)
  └── UI5 uygulaması  vdx.notlar  (BSP: ZVDX_NOT_UI)
        └── OData v2 servisi  ZVDX_NOT_SRV  (SEGW projesi ZVDX_NOT)
              └── DPC_EXT sınıfı  ZCL_ZVDX_NOT_DPC_EXT
                    └── Tablo  ZVDX_NOTLAR
```

## Launchpad nesneleri (elle yeniden kurulur)
- Catalog / Group: Velodynex (Launchpad Designer, /UI2/FLPD_CUST)
- Semantic Object: ZVDXNot · Action: display
- Target Mapping tipi: SAPUI5 Fiori App, URL `/sap/bc/bsp/sap/zvdx_not_ui`, Component `vdx.notlar`
- Test kullanıcısı: GOZDE (rol ile katalog + grup atanmış)

## Öğrenilen kurallar (kanıtlı)
1. Gateway Client'ta CSRF token pencerenin güvenlik oturumuna bağlıdır; göreli URI
   dahili oturumdan, tam URL harici oturumdan gider. Fetch ve yazma isteği aynı
   biçimden, aynı pencerede, aralıksız yapılır.
2. v2 ODataModel yazma isteklerini `$batch` zarfıyla taşır.
3. UI5'in varsayılan fallbackLocale'i `en`; varsayılan dil dosyası İngilizce değilse
   hem modelde hem `sap.app.i18n`'de `fallbackLocale: ""` açıkça verilir.
4. Manifest'ten tanımlanan OData modelinde `defaultBindingMode: "TwoWay"` açıkça yazılır.
5. Filtre/sıralama istemcide gizleme değil, `$filter`/`$orderby` ile sunucuya gider;
   backend `get_osql_where_clause()` / `get_orderby()` ile dinamik SQL kurar.
6. Dil ≠ format yereli: tarih formatı SU3 / `sap-ui-formatLocale`'den gelir.

## Klasörler
- `ui5/` — BSP ZVDX_NOT_UI içeriği (kökte, i18n alt klasörü ile)
- `abap/` — DPC_EXT metotları ve tablo tanımı

## Depo yapısı
- `src/` + `.abapgit.xml` — abapGit ile sistemden dışa aktarılan **gerçek** nesneler
  (tablo, sınıflar, BSP, SEGW projesi). Kaynak doğru budur.
- `ui5/`, `abap/` — aynı kodun elle derlenmiş, okunması kolay kopyası.
  Tutarsızlık olursa `src/` geçerlidir.
- Yeniden kurulum: abapGit → New Online/Offline → bu repo → Pull.
- 
## OData V4 / Fiori Elements V4 (Konu 15)

- Service Binding `ZVDX_SB_NOT_O4` (OData V4 – UI), aynı service definition `ZVDX_SD_NOT` üzerinde.
  abapGit pull sonrası V2 binding gibi ADT'den **elle Publish** edilmeli.
  Servis adresi: `/sap/opu/odata4/sap/zvdx_sb_not_o4/srvd/sap/zvdx_sd_not/0001/`
- V4 service group yetkisi S_SERVICE değil **S_START** (`R3TR` / `G4BA` / `ZVDX_SB_NOT_O4`).
  Rol menüsüne *Authorization Default* ile eklenir, sonra profil generate edilir.
- BSP `ZVDX_NOT_FE4`: `index.htm` BSP *sayfası* (MIME değil); `Component.js` ve `manifest.json` MIME.
  Launchpad target mapping `ZVDXNotFE4-display` → URL `/sap/bc/bsp/sap/zvdx_not_fe4/index.htm`.
- FE V4 tek başına çalışırken container'a %100 yükseklik gerekir (`data-height="100%"`,
  html/body height) — yoksa ekran boş kalır. `initialLoad: "Enabled"` listeyi Go'suz yükler.
- GOZDE ile doğrulanan davranış farkı: instance seviyesindeki feature/authorization kontrolleri
  butonu *devre dışı* gösterir; global create yetkisi (ACTVT 01) yoksa V4 Create butonunu hiç
  çizmez, V2 ise butonu gösterip backend'de reddeder.
- Kısıtlı kullanıcı için Launchpad runtime: `SAP_FLP_USER` Z role kopyalanıp generate edilmeli —
  SAP template rolleri profil taşımaz.

## Konu 16 — Draft (RAP managed, FE V4)

BO draft'a çevrildi: `with draft`, draft tablosu `ZVDX_NOTLAR_D`,
`lock master total etag LastChangedAt`, `etag master LocalLastChangedAt`,
beş standart draft action (Edit/Activate/Discard/Resume/Prepare),
projection BDEF'te `use draft`.

Doğrulananlar: kaydetmeden çıkma → Keep/Discard diyaloğu, draft tablosunda
satır / aktif tabloda eski değer, Resume, başka kullanıcıda kilit
("… tarafından düzenleniyor"), Prepare üzerinden validation (boş başlık).

Öğrenilenler:
- **%is_draft**: draft açılınca `mapped`/`failed`/`reported` satırlarına
  `%is_draft` eklenmeli; yoksa `CX_CSP_ACT_RESPONSE` (EVALUATE_DIRECT_CREATE).
- **Early numbering idempotent olmalı**: Activate create'i anahtar dolu olarak
  yeniden çağırır; anahtarlı gelenler `mapped`'e aynen geri yazılır,
  sadece anahtarsızlar üretilir.
- FE V4'te alan değeri backend'e alanın `change` olayında (Tab/blur) gider;
  yazıp doğrudan geri gidince draft'a düşmez ("Taslak kaydedildi" beklenir).
- Managed RAP `createdBy`'ı draft anında, `createdAt`'ı aktivasyonda doldurur.
- Tablodaki timestamp UTC; FE yalnızca gerçek timestamp alanlarını yerel saate
  çevirir — CDS'te türetilmiş saat alanı UTC kalır (Konu 18'de düzeltilecek).
- Preview BPINST ile çalışır; SAP_ALL sonradan yaratılan `ZVDX_NOT`'u
  kapsamıyordu (SU53). Çözüm: `Z_VDX_DEV` rolü (ACTVT 01/02/06) → BPINST.
  GOZDE bilerek 01'siz kaldı.
- Validation'da `%state_area` kullan; başarı dalında aynı alana boş kayıt
  atılmazsa mesaj draft'a yapışık kalır.

### Konu 16 — ikinci oturum (13 Eyl)

**Draft'ta instance action'lar (`%is_draft`)**
`get_instance_features` artık `%is_draft = mk-on` olan instance'larda `tamamla`'yı
kapatıyor. Sebep: action draft üzerinde çalışırsa `Durum='T'` yalnızca draft'a yazılır,
aktif kayıt 'A' kalır; kullanıcı Save'e basmadan çıkarsa değişiklik yok olur.
Kural: önce Save, sonra Tamamla. Doğrulandı: aktif → Tamamla açık, Edit → gri,
Save → yeniden açık.

**Field control**
`Durum` draft'ta düzenlenebilir görünüyordu → BDEF `field ( readonly )` listesine eklendi.
`field ( readonly )` hem `$metadata`'ya iner (FE alanı salt okunur çizer) hem backend'de
zorlanır. Durum'u yalnızca `setDurum` determination'ı ve `tamamla` action'ı değiştirir.
Konu 14'teki katmanlara dördüncüsü: global auth / instance auth / instance features /
**field control**.

**Prepare**
FE Save'de tek `$batch` içinde `Prepare` + `Activate` yollar. Prepare, BDEF'te listelenen
validation'ları draft üzerinde koşturur; `reported`'daki `%state_area`'lı mesajlar draft'a
**state message** olarak iliştirilir, hata varsa Activate çalışmaz. Prepare olmasa da
`on save` validation Activate içinde yine koşar ve kaydı engeller — fark, mesajın alana
bağlı ve kalıcı olması.

**Delete vs Discard**
FE V4 draft modunda Delete butonu göstermez, alt çubukta "Discard Draft" sunar;
`%delete` draft instance için FE tarafından sorulmaz. Draft'ta silme = `Discard` action'ı.

**V2 ile draft**
Gateway V2, RAP draft'ı olduğu gibi taşıyor (`/IWFND/CACHE_CLEANUP` sonrası):
Editing Status filtresi, Keep Draft, kilit göstergesi ("Locked by …"), Save hepsi çalıştı.
Konu 15 davranışı korundu: 01 olmayan kullanıcıda Create görünür, backend reddeder;
draft'la tek fark, ret artık draft yaratılırken geliyor.

| | FE V2 | FE V4 |
|---|---|---|
| Kaydetmeden çıkış diyaloğu | Save / Keep Draft / Discard | Keep Draft / Discard |
| Draft'ta silme | Delete | Discard Draft (alt çubuk) |
| Aktif/draft karşılaştırma | "Display Saved Version" | — |
| Global yetki yoksa Create | görünür, backend reddeder | hiç yok |

**Draft'lar oturumla ölmez**
Preview'ı kapatmak Discard değildir; BPINST'in test draft'ları `ZVDX_NOTLAR_D`'de kilitli
kaldı ve GOZDE'nin listesinde "Locked by …" olarak göründü. Temizlik: Discard ya da
`_D`'den silme. Gerçek sistemde bunun için `SAP_DRAFT_CLEANUP` (draft garbage collector)
job'ı çalışır; kilit süresi dolan draft'lar temizlenir.

**Validation geriye dönük çalışmaz**
`validateBaslik` eklenmeden önce kaydedilmiş boş başlıklı kayıt ("Unnamed Object")
aktif tabloda kaldı; elle silindi. Kural sonradan eklenince mevcut veri denetlenmez.

**Self-test sonucu**
Mekanizma soruları (etag/total etag, iki dump'ın nedeni, Prepare'in katkısı, draft'ta
action) zayıf kaldı. Konu 17 öncesi ödev: her cevabı "→" zinciri olarak yeniden yazmak
(örn. Save → Prepare+Activate → create anahtar dolu → earlynumbering → mapped'de yoksa →
CX_CSP_ACT_RESPONSE) ve Edit'ten Activate'e Save akışını kağıda çizmek.  
