# velodynex-notlar — SAP Fiori / RAP Çalışma Günlüğü

Kişisel SAP Fiori öğrenme projesi. Aynı iş nesnesi ("Not") önce klasik SEGW + UI5 ile,
sonra Fiori Elements V2, RAP managed, OData V4 / FE V4 ve draft ile uçtan uca yeniden
kuruldu. Her konu bir önceki üzerine inşa edilir; kod bu repoda, gerekçeler bu dosyada.

**Ortam:** SAP S/4HANA 2025 Fully-Activated Appliance (SAP CAL, deneme).
Geliştirme: ADT (Eclipse), kullanıcı **BPINST**. Son kullanıcı testi: **GOZDE**.
Paket: `ZVELODYNEX` (software component HOME). Adlandırma: `ZVDX_*`.
Sürüm yönetimi: abapGit standalone (offline zip) → bu repo.

---

## Repo yapısı

```
src/          abapGit export (nesnelerin XML/ABAP kaynakları)
.abapgit.xml
ui5/          UI5 uygulamalarının okunur kopyaları (BSP MIME'ları)
abap/         Handler/DPC sınıflarının okunur kopyaları
README.md     bu dosya
```

---

## Konu listesi

### Konu 1–4 — Temeller (kitap tabanlı)
Fiori mimarisi ve uygulama tipleri (transactional / analytical / fact sheet), SEGW ile
OData servis üretimi (MPC/DPC, `_EXT` sınıfları), UI5 MVC (Component, manifest, view,
controller, model), Fiori extension yaklaşımları. Kaynaklar: Tutorials Point, S. Guerrero
*Custom Fiori Applications in SAP HANA*, S. Guo *SAP Fiori Launchpad Development and
Extensibility*. Konu 5'ten itibaren appliance üzerinde hands-on.

### Konu 5 — Fiori Launchpad
Spaces & Pages, tile tipleri, intent tabanlı navigasyon (`SemanticObject-action`),
cache temizleme. Hands-on zincir: katalog `ZVDX_TC_CALISMA` (Launchpad Designer
`/UI2/FLPD_CUST`, klasik katalog — FLPAM'da görünmez) → target mapping
`ZVDXKullanici-display` → statik tile → PFCG rolü + profil → kullanıcı GOZDE →
space/page/section `ZVDX`. **Dinamik tile:** kendi OData servisi `ZVDX_SAYAC_SRV`
(SEGW, `GET_ENTITYSET` + `GET_ENTITY`) canlı sayaç besliyor; role `S_SERVICE` eklendi.

### Konu 6 — Güvenlik
SICF hands-on (servis aktif/pasif, Logon Data, anonim servisler). Teori: SAML, Kerberos,
**CSRF** (token alma: ilk istek `X-CSRF-Token: Fetch`, sonra `$batch`), CORS, `S_SERVICE`.

### Konu 7 — OData test ve debug
Gateway Client (`/IWFND/GW_CLIENT`), `/IWFND/ERROR_LOG` + Replay, DPC'de **external
breakpoint** ile tile yenilemesinden debugger'a düşme.

### Konu 7b — İlk UI5 uygulaması
`ZVDX_SAYAC_UI` BSP (dosyalar MIME olarak, kendi ICF düğümü), `ZVDX_SAYAC_SRV` tüketiyor;
son sürüm Component + ODataModel element binding. Üçüncü tile `ZVDXPanel-display`
(URL target mapping). Appliance notları: manuel MIME'lı BSP'ler
`/sap/bc/bsp/sap/<app>/` altından servis edilir (`/sap/bc/ui5_ui5/` değil); UI5 bootstrap
yolu `/sap/public/bc/ui5_ui5/1/resources/sap-ui-core.js` (`/1/` şart).

### Konu 8 — Not uygulaması: CRUD (klasik yol)
Z tablo `ZVDX_NOTLAR` (MANDT, NOT_ID SYSUUID_C32, BASLIK CHAR80, DURUM CHAR1,
OLUSTURMA TIMESTAMPL; sonradan CREATED_BY, LAST_CHANGED_AT, LOCAL_LAST_CHANGED_AT).
SEGW servisi `ZVDX_NOT_SRV`: create / read / update / delete + negatif 404 testi.
UI5 uygulaması `ZVDX_NOT_UI` (ODataModel ile ekle/sil/güncelle). Dördüncü tile
"Notlarım" `ZVDXNot-display` (SAPUI5 target mapping).

### Konu 9 — i18n
TR/EN `i18n.properties`, `fallbackLocale` düzeltmesi.

### Konu 10 — Routing
Liste/Detay view'ları, deep link, `submitChanges`, TwoWay binding. SU3 tarih formatı
etkisi not edildi.

### Konu 11 — Arama / filtre / sıralama + yedekleme
UI: `SearchField`, `IconTabBar` + `$count` sekmeleri, `Sorter`. Backend: `$filter` /
`$orderby` → `get_osql_where_clause` / `get_orderby`. Nesneler `$TMP`'den `ZVELODYNEX`'e
taşındı, abapGit (1.121.0, offline zip) ile bu repoya alındı; `DPC_EXT` SEGW şablon
yorumlarından temizlendi.

### Konu 12 — Fiori Elements V2
CDS view entity `ZVDX_C_NOT` (UI annotation'ları) → Service Definition `ZVDX_SD_NOT`
(entity set `Notlar`) → Service Binding `ZVDX_SB_NOT_O2` (OData V2 – UI, Publish).
BSP `ZVDX_NOT_FE` (manuel MIME, `sap.app.id = zvdx.notfe`, List Report + Object Page
manifest'i). Beşinci tile "Notlarım (FE)" `ZVDXNotFE-display`
(URL `/sap/bc/bsp/sap/zvdx_not_fe`).
**Ders:** CDS tabanlı V2 serviste UI annotation'ları ayrı annotation modelinden gelir
(`ZVDX_SB_NOT_O2_VAN`, `CATALOGSERVICE;v=2`) ve manifest `sap.app.dataSources` altında
bildirilmelidir.

### Konu 13 — RAP managed
Root view `ZVDX_R_NOT` (türetilmiş `DurumText`, `OlusturmaTarihi`, `OlusturmaSaati`;
`@Semantics.systemDateTime.createdAt`), `ZVDX_C_NOT` **projection** olarak yeniden yazıldı
(`provider contract transactional_query`). Managed BDEF `ZVDX_R_NOT`: alias `Notlar`
(`Not` rezerve kelime), `strict(2)`, `early numbering` (`cl_system_uuid` C32),
`lock master`, `authorization master`, determination `setDurum` (create → `Durum='A'`),
`mapping for zvdx_notlar`. Handler `ZBP_VDX_R_NOT`. Projection BDEF `ZVDX_C_NOT`
(`use create/update/delete` — beyaz liste). Manifest'e dokunmadan Create/Edit/Delete
hem Preview'da hem GOZDE'nin tile'ında çalıştı.

### Konu 14 — RAP action + yetki
- **Instance action `tamamla`** (`Durum='T'`, `result [1] $self`, `features: instance` →
  `get_instance_features`; projection'da `use action`; `@UI ... #FOR_ACTION`).
- **Instance authorization:** SU21 nesnesi `ZVDX_NOT` (alan ACTVT).
  `get_instance_authorizations`: ACTVT 02 → update/tamamla, 06 → delete.
- **Konu 14 Ek:** veri kuralı (Durum='T' → delete kapalı) `get_instance_features`'a taşındı
  (`delete ( features : instance )` gerekti); `authorization master ( global, instance )` +
  `get_global_authorizations` (ACTVT 01 → create); `CreatedBy`
  (`@Semantics.user.createdBy`, "Oluşturan") ile sahiplik kuralı — yalnızca kendi açık
  notunu silebilirsin.
- **Üç katman:** global auth (kullanıcı, işlem bazlı) / instance auth (kullanıcı, kayıt
  bazlı) / instance features (veri bazlı). Kullanıcı ve veri kuralları birbirinden
  bağımsız çalışır. V2 sınırı: global yetki yoksa Create butonu görünür, backend reddeder.
- `IN LOCAL MODE`: handler içi `READ ENTITIES`'de yetki/feature kontrolünü atlayarak
  sonsuz döngüyü önler.

### Konu 15 — OData V4 + Fiori Elements V4
Aynı service definition'a ikinci binding `ZVDX_SB_NOT_O4` (OData V4 – UI; **manuel
Publish** gerekir). BSP `ZVDX_NOT_FE4`: `index.htm` BSP sayfası (MIME değil) +
`Component.js` / `manifest.json` MIME. Altıncı tile "Notlarım (FE V4)"
`ZVDXNotFE4-display` (URL `/sap/bc/bsp/sap/zvdx_not_fe4/index.htm`).
- Beyaz ekran: component container `data-height="100%"` + html/body `height:100%`;
  `"initialLoad": "Enabled"` ile veri Go'suz yüklenir.
- **Yetki:** on-prem V4 servis grupları `S_SERVICE` ile değil **`S_START`
  (R3TR / G4BA / ZVDX_SB_NOT_O4)** ile korunur. Roldeki `S_SERVICE` wildcard'ı
  (`SRV_NAME *`) kaldırıldı, açık IWSG hash'leri eklendi (`ZINTEROP_0001`,
  `/UI2/FDM_PAGE_RUNTIME_SRV_0001`, `ZVDX_SAYAC_SRV_0001`, O2 girdileri).
  Launchpad runtime: `SAP_FLP_USER` şablon rolü **profil taşımaz** → `Z_FLP_USER`'a
  kopyala → generate → ata.
- **V2 vs V4 davranışı:** global yetki yoksa V4 Create butonunu **hiç göstermez**
  (V2 gösterir, backend reddeder); instance feature/auth sonuçları V4'te **gri**, V2'de
  **gizli**. V4'te annotation'lar `$metadata` ile taşınır (VAN modeli yok).
- İki List Report'u ayırt etmenin güvenilir yolu adres çubuğu (`#ZVDXNotFE-display` = V2,
  `/zvdx_not_fe4/` = V4).
- CSRF canlı: ilk `$batch` token'sız → 403 + token, ikinci → 200.

### Konu 16 — Draft
BO draft'a çevrildi: `with draft`, draft tablosu `ZVDX_NOTLAR_D` (`%admin` include),
`lock master total etag LastChangedAt`, `etag master LocalLastChangedAt`, beş standart
draft action (`Edit / Activate optimized / Discard / Resume / Prepare`), projection BDEF
`use draft` + `use action` satırları. Validation `validateBaslik on save { create; field
Baslik; }`, Prepare içinde çalışır (`%state_area`, `%element-baslik`).

Doğrulananlar (V4 tile + V2 tile, GOZDE): kaydetmeden çıkış → Keep/Discard diyaloğu,
`_D`'de satır / aktifte eski değer, listede draft göstergesi, Resume, başka kullanıcıda
kilit ("… tarafından düzenleniyor"), Prepare üzerinden validation (boş başlık), draft'ta
Tamamla kapalı, Save sonrası aktif.

Öğrenilenler:
- **`%is_draft`:** draft açılınca `mapped` / `failed` / `reported` satırlarına
  `%is_draft` eklenmeli; yoksa `CX_CSP_ACT_RESPONSE` (`EVALUATE_DIRECT_CREATE`).
- **Early numbering idempotent olmalı:** Activate, create'i anahtar dolu olarak yeniden
  çağırır; anahtarlı gelenler `mapped`'e aynen geri yazılır, yalnız anahtarsızlar üretilir.
- **Prepare:** FE Save'de tek `$batch`'te `Prepare` + `Activate` yollar. Prepare
  validation'ları draft üzerinde koşturup sonucu **state message** olarak draft'a iliştirir;
  hata varsa Activate çalışmaz. Prepare olmasa da `on save` validation Activate içinde
  koşar ve kaydı engeller — fark, mesajın alana bağlı ve kalıcı olması. Başarı dalında
  aynı `%state_area`'ya boş kayıt atılmazsa mesaj draft'a yapışık kalır.
- **Draft'ta instance action:** action draft'ta çalışırsa değişiklik yalnızca draft'a
  yazılır; kullanıcı Save'e basmadan çıkarsa kaybolur. `get_instance_features`'ta
  `%is_draft = mk-on` → `tamamla` kapalı. Kural: önce Save, sonra Tamamla.
- **Field control:** `Durum` draft'ta düzenlenebilir görünüyordu → BDEF
  `field ( readonly )`. Hem `$metadata`'ya iner hem backend'de zorlanır. Dördüncü katman:
  global auth / instance auth / instance features / **field control**.
- **Yetki eşlemesi:** aktif karşılığı olmayan draft'ın `update`'i **create (01)** yetkisiyle
  denetlenir. Preview her zaman BPINST'tir; SAP_ALL sonradan yaratılan `ZVDX_NOT`'u
  kapsamadığından BPINST ilk kez 01'e takıldı (SU53). Çözüm: `Z_VDX_DEV` rolü
  (ACTVT 01/02/06) → BPINST. GOZDE bilerek 01'siz.
- FE V4'te alan değeri backend'e alanın `change` olayında (Tab/blur, "Taslak kaydedildi")
  gider; yazıp doğrudan geri gidince draft'a düşmez.
- Managed RAP `createdBy`'ı draft anında, `createdAt`'ı **aktivasyonda** doldurur.
- Tablodaki timestamp UTC; FE yalnızca gerçek timestamp alanlarını yerel saate çevirir —
  CDS'te türetilmiş saat alanı UTC kalır (Konu 18'de düzeltilecek).
- FE V4 draft modunda Delete yerine "Discard Draft" gösterir; `%delete` draft için
  sorulmaz. Draft'ta silme = `Discard`.
- Gateway V2 RAP draft'ı olduğu gibi taşır (`/IWFND/CACHE_CLEANUP` sonrası).
- Draft'lar oturumla ölmez: Preview'ı kapatmak Discard değildir; kilitli draft'lar
  başkalarının listesinde "Locked by …" görünür. Gerçek sistemde `SAP_DRAFT_CLEANUP`.
- Validation geriye dönük çalışmaz; kural eklenmeden önceki boş başlıklı kayıt elle silindi.

### Konu 17 — Composition (parent-child: Not → Adımlar)

Tablo `ZVDX_ADIMLAR` (key `adim_id`; `not_id`, `sira`, `aciklama`, `tamam`, etag alanları)
+ draft tablosu `ZVDX_ADIMLAR_D`. Child root view `ZVDX_R_ADIM` (`association to parent
ZVDX_R_NOT as _Not`), parent'ta `composition [0..*] of ZVDX_R_ADIM as _Adimlar`.
Projection `ZVDX_C_ADIM` (`_Not : redirected to parent`), `ZVDX_C_NOT`'ta `_Adimlar :
redirected to composition child` + `#LINEITEM_REFERENCE` facet "Adımlar".
BDEF: child bloğu `lock dependent by _Not`, `authorization dependent by _Not`,
`etag master LocalLastChangedAt`, `early numbering`; child'da `create` **yok** —
parent'ta `association _Adimlar { create; with draft; }`, child'da
`association _Not { with draft; }`. Anahtar `earlynumbering_cba_Adimlar` (parent
handler'ında). Service definition `expose ZVDX_C_ADIM as Adimlar`; iki binding yeniden
publish.

Doğrulananlar: Object Page'de Adımlar tablosu, satır ekle/sil/Save, satırın `>` ile açılan
alt Object Page'i, child draft (Keep → `_D`'de satır / Discard → temiz), **parent silinince
adımlar da silindi** (sıfır child silme kodu), tek Save'de tüm ağaç aynı LUW
(adımların `LAST_CHANGED_AT` değerleri eşit).

Öğrenilenler:
- **Composition = sahiplik.** Child parent'sız yaratılamaz; parent'ın kilidi, yetkisi ve
  draft'ı child'a iner; parent silinince child silinir. BDEF karşılıkları: `lock dependent`,
  `authorization dependent`, `with draft`; cascade için ek bir şey yok.
- **Create-by-association (CBA):** child'ın yaratma isteği parent üzerinden gelir;
  numbering metodu parent handler'ında (`entities` = parent satırları, child'lar
  `%target` içinde). Child'da doğrudan `create` olsaydı parent'sız adım yaratılabilirdi.
- **`mapped` yalnızca key alanlarını taşır:** `mapped-adimlar`'da `AdimId` var, `NotId`
  yok ("No component exists with the name NOTID"). Parent anahtarını CBA'da framework
  doldurur.
- **Dependent authorization:** adım silmek/eklemek = notu değiştirmek → parent'ın
  `get_instance_authorizations`'ında **`%update` (ACTVT 02)** sorulur; child için ayrı
  SU21 nesnesi gerekmez.
- Child Delete draft'ta işaretlenir, aktif satır Save'e kadar durur (draft izolasyonu
  child'da da geçerli).
- `LastChangedAt` (total etag) yalnız Activate'te, `LocalLastChangedAt` (etag) her draft
  değişikliğinde yazılır — draft satırında ilki 0, ikincisi dolu.
- BDEF'te her `define behavior` kendi `{ }` çiftine sahiptir, iç içe olmaz.
- SE16 sonuç ekranı anlık görüntüdür; her kontrolden önce F8.
- `abap_boolean` FE'de Yes/No metin olarak çizilir (checkbox → Konu 18).

| | FE V2 | FE V4 |
|---|---|---|
| Kaydetmeden çıkış diyaloğu | Save / Keep Draft / Discard | Keep Draft / Discard |
| Draft'ta silme | Delete | Discard Draft (alt çubuk) |
| Aktif/draft karşılaştırma | "Display Saved Version" | — |
| Global yetki yoksa Create | görünür, backend reddeder | hiç yok |
| Instance feature kapalı | gizli | gri |

---

## Launchpad tile zinciri (katalog `ZVDX_TC_CALISMA`, sayfa `ZVDX`)

| # | Tile | Intent | Hedef |
|---|---|---|---|
| 1 | Statik tile | `ZVDXKullanici-display` | Konu 5 |
| 2 | Dinamik sayaç | — | `ZVDX_SAYAC_SRV` |
| 3 | Panel | `ZVDXPanel-display` | `ZVDX_SAYAC_UI` (URL) |
| 4 | Notlarım | `ZVDXNot-display` | `ZVDX_NOT_UI` (SAPUI5) |
| 5 | Notlarım (FE) | `ZVDXNotFE-display` | `/sap/bc/bsp/sap/zvdx_not_fe` (FE V2) |
| 6 | Notlarım (FE V4) | `ZVDXNotFE4-display` | `/sap/bc/bsp/sap/zvdx_not_fe4/index.htm` (FE V4) |

## Nesne envanteri

| Tür | Nesne |
|---|---|
| Tablo | `ZVDX_NOTLAR`, `ZVDX_NOTLAR_D` (draft) |
| CDS | `ZVDX_R_NOT` (root), `ZVDX_C_NOT` (projection) |
| BDEF | `ZVDX_R_NOT` (managed, draft), `ZVDX_C_NOT` (projection) |
| Sınıf | `ZBP_VDX_R_NOT` (handler), `ZCL_ZVDX_NOT_SRV_DPC_EXT` / `_MPC_EXT`, `ZCL_ZVDX_SAYAC_SRV_*` |
| Servis | `ZVDX_SAYAC_SRV`, `ZVDX_NOT_SRV` (SEGW); `ZVDX_SD_NOT` → `ZVDX_SB_NOT_O2` (V2), `ZVDX_SB_NOT_O4` (V4) |
| BSP | `ZVDX_SAYAC_UI`, `ZVDX_NOT_UI`, `ZVDX_NOT_FE`, `ZVDX_NOT_FE4` |
| Yetki | SU21 `ZVDX_NOT` (ACTVT 01/02/06); roller: GOZDE'nin uygulama rolü, `Z_FLP_USER`, `Z_VDX_DEV` (BPINST) |

## Yetki özeti

| Kim | `ZVDX_NOT` ACTVT | Sonuç |
|---|---|---|
| GOZDE | 02, 06 (01 yok) | Create V2'de görünür/reddedilir, V4'te yok; kendi açık notunu siler |
| BPINST | 01, 02, 06 (`Z_VDX_DEV`) | Geliştirme + Preview |

## Plan

- **Konu 18** — Annotation cilası: value help, criticality (Durum renkli), `@Search`,
  Metadata Extension, timestamp/saat düzeltmesi.
- **Konu 19** — ABAP Unit + EML ile RAP testi (zaman kalırsa).
- **Final (23–24 Eyl)** — son abapGit export, README/portföy özeti. CAL erişimi 26 Eyl'de biter.
