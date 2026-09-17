# velodynex-notlar — SAP Fiori / RAP Çalışma Günlüğü

Kişisel SAP Fiori öğrenme projesi. Aynı iş nesnesi ("Not") önce klasik SEGW + UI5 ile,
sonra Fiori Elements V2, RAP managed, OData V4 / FE V4, draft ve composition ile uçtan
uca yeniden kuruldu. Her konu bir önceki üzerine inşa edilir; kod bu repoda, gerekçeler
bu dosyada.

**Ortam:** SAP S/4HANA 2025 Fully-Activated Appliance (SAP CAL, deneme, 1–26 Eylül 2026).
Geliştirme: ADT (Eclipse), kullanıcı **BPINST**. Son kullanıcı testi: **GOZDE**.
Paket: `ZVELODYNEX` (software component HOME). Adlandırma: `ZVDX_*`;
`_R_` root, `_C_` projection/consumption, `_I_` interface, `_VH` value help.
Sürüm yönetimi: abapGit standalone (offline zip) → bu repo.

---

## Özet — ne yaptım, ne öğrendim

Bu repo, klasik ABAP'tan gelen bir geliştiricinin aynı iş nesnesini üç kuşak SAP UI
teknolojisiyle uçtan uca kurmasının kaydı: SEGW + UI5 (Konu 5–11), Fiori Elements V2
üzerinde CDS (Konu 12), RAP managed + OData V4 / FE V4 (Konu 13–19). Her katman bir
öncekinin üstüne kondu; hiçbir konu kitaptan aktarılmadı, hepsi S/4HANA 2025 appliance'ında
çalıştırılıp doğrulandı.

Teknik omurga: Z tablo → SEGW servisi → UI5 uygulaması → CDS + Service Binding →
RAP BO (managed, early numbering, determination, validation, action, instance/global
authorization, feature control, field control) → draft (Prepare, etag/total etag, kilit)
→ composition (CBA, dependent lock/auth, cascade) → Metadata Extension, criticality,
value help → EML determination → ABAP Unit + test double. Güvenlik tarafı: S_SERVICE,
S_START/G4BA, CSRF, SU21 nesnesi, PFCG rolleri, SAP_ALL'ın kapsamadığı Z nesneler.

En değerli dersler kod değil, mekanizma oldu:
- RAP'ta akışın çoğu framework'te; senin kodun çağrılan noktalardır. Bir dump'ı çözmek
  "hangi metot, hangi sözleşme" sorusunu sormaktır (`%is_draft`, idempotent numbering,
  `mapped` yalnız key taşır).
- Yetki dört katman: global / instance / instance features / field control. V2 ile V4 aynı
  backend cevabını farklı çizer (gizli vs gri, görünür vs yok).
- Draft bir ara kalıcılık katmanıdır: türetilmiş alanlar orada hesaplanmaz, kopyalanır;
  draft'lar oturumla ölmez; total etag Activate'te, etag her değişiklikte.
- Composition sahipliktir: child parent'ın kilidini, yetkisini, draft'ını ve ölümünü paylaşır.
- Test edilebilirlik: `cl_osql_test_environment` + EML ile BO'nun tüm kuralları
  Fiori'siz, saniyeler içinde doğrulanır.

Çalışma yöntemi: her konu teori → hands-on → iki kullanıcıyla (geliştirici / son kullanıcı)
doğrulama → notlara bakmadan self-test → cevapları neden-sonuç zinciri olarak yeniden yazma.
Zincir tekniği, "ne oldu"dan "neden oldu"ya geçişi sağlayan asıl araç oldu.

**Kalite:** ABAP Unit 4/4 yeşil. ATC (`ZABAP_CLOUD_DEVELOPMENT` variant'ı): DPC_EXT'in
Open SQL'i yeni sözdizimine çevrildikten sonra 3 hata, 12 info. Hatalar yalnız
`ZVDX_NOT_DOLDUR` (test verisi raporu; `REPORT`/`WRITE` ABAP Cloud'da yok, bilinçli klasik).
Info'lar: koda gömülü mesaj metinleri (üretimde T100 message class), test sınıfındaki
`COMMIT ENTITIES` için yanlış pozitif sy-subrc uyarısı. RAP katmanı hatasız. Exemption
istenmedi — sandbox'ta onaylayıcı yok.

---

## Repo yapısı

```
src/          abapGit export (nesnelerin XML/ABAP kaynakları)
.abapgit.xml
ui5/          UI5 uygulamalarının okunur kopyaları (BSP MIME'ları)
abap/         Handler/DPC sınıflarının okunur kopyaları
docs/         abapGit'e girmeyen artefaktlar: PFCG rol indirmeleri (.SAP), SU21 nesnesi,
              Launchpad Designer katalog/space görüntüleri, SICF düğümleri, servis publish
              ekranları, altı tile'lı son Launchpad görüntüsü
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
Not: uygulama ve MIME'ları (WAPA + SMIM, ayrı TADIR kayıtları) final oturumunda `$TMP`'den
`ZVELODYNEX`'e taşınıp repoya alındı.

### Konu 8 — Not uygulaması: CRUD (klasik yol)
Z tablo `ZVDX_NOTLAR` (MANDT, NOT_ID SYSUUID_C32, BASLIK CHAR80, DURUM CHAR1,
OLUSTURMA TIMESTAMPL; sonradan CREATED_BY, LAST_CHANGED_AT, LOCAL_LAST_CHANGED_AT).
SEGW servisi `ZVDX_NOT_SRV`: create / read / update / delete + negatif 404 testi.
UI5 uygulaması `ZVDX_NOT_UI` (ODataModel ile ekle/sil/güncelle). Dördüncü tile
"Notlarım" `ZVDXNot-display` (SAPUI5 target mapping). Test verisi raporu `ZVDX_NOT_DOLDUR`.

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
`get_instance_features`: `%is_draft = mk-on` → `tamamla` kapalı (önce Save, sonra
Tamamla). `Durum` `field ( readonly )` listesine alındı (draft'ta düzenlenebilir
görünüyordu).

Doğrulananlar (V4 tile + V2 tile, GOZDE): kaydetmeden çıkış → Keep/Discard diyaloğu,
`_D`'de satır / aktifte eski değer, listede draft göstergesi, Resume, başka kullanıcıda
kilit ("… tarafından düzenleniyor"), Prepare üzerinden validation (boş başlık), draft'ta
Tamamla gri, Save sonrası aktif.

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
  yazılır; Save'siz çıkınca kaybolur.
- **Field control:** `field ( readonly )` hem `$metadata`'ya iner hem backend'de
  zorlanır. Dördüncü katman: global auth / instance auth / instance features / **field
  control**.
- **Yetki eşlemesi:** aktif karşılığı olmayan draft'ın `update`'i **create (01)** yetkisiyle
  denetlenir. Preview her zaman BPINST'tir; SAP_ALL sonradan yaratılan `ZVDX_NOT`'u
  kapsamadığından BPINST ilk kez 01'e takıldı (SU53). Çözüm: `Z_VDX_DEV` rolü
  (ACTVT 01/02/06) → BPINST. GOZDE bilerek 01'siz.
- FE V4'te alan değeri backend'e alanın `change` olayında (Tab/blur, "Taslak kaydedildi")
  gider; yazıp doğrudan geri gidince draft'a düşmez.
- Managed RAP `createdBy` ve `createdAt`'ı **draft anında** doldurur; draft'ta boş görünen,
  türetilmiş (CASE/fonksiyon) alanlardır — draft satırında yeniden hesaplanmazlar
  (Konu 18'de netleşti).
- Tablodaki timestamp UTC; FE yalnızca gerçek timestamp alanlarını yerel saate çevirir —
  CDS'te türetilmiş saat alanı UTC kalır (Konu 18'de düzeltildi).
- FE V4 draft modunda Delete yerine "Discard Draft" gösterir; `%delete` draft için
  sorulmaz.
- Gateway V2 RAP draft'ı olduğu gibi taşır (`/IWFND/CACHE_CLEANUP` sonrası).
- Draft'lar oturumla ölmez: Preview'ı kapatmak Discard değildir; kilitli draft'lar
  başkalarının listesinde "Locked by …" görünür. Gerçek sistemde `SAP_DRAFT_CLEANUP`.
- Validation geriye dönük çalışmaz; kural eklenmeden önceki boş başlıklı kayıt elle silindi.

| | FE V2 | FE V4 |
|---|---|---|
| Kaydetmeden çıkış diyaloğu | Save / Keep Draft / Discard | Keep Draft / Discard |
| Draft'ta silme | Delete | Discard Draft (alt çubuk) |
| Aktif/draft karşılaştırma | "Display Saved Version" | — |
| Global yetki yoksa Create | görünür, backend reddeder | hiç yok |
| Instance feature kapalı | gizli | gri |

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
  `authorization dependent`, `with draft`; cascade için ek bir şey yok. Draft'ta da
  geçerli: parent draft'ı Discard edilince child draft'ı gider.
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
- LUW = Logical Unit of Work; RAP save sequence tek LUW'dur, handler'da `COMMIT WORK`
  yazılmaz.

### Konu 18 — Annotation cilası (MDE, criticality, value help, timestamp)
- **Metadata Extension** `ZVDX_C_NOT` ve `ZVDX_C_ADIM` (`@Metadata.layer: #CUSTOMER`):
  tüm `@UI.*` projection'lardan MDE'ye taşındı; projection'da yalnız `@EndUserText`,
  `@Search`, `@Consumption` kaldı. Kanıt: MDE'de Başlık position 5 → form sırası değişti,
  projection'a dokunulmadı. Standart uygulama uyarlamasının RAP yolu. Child'a
  `@UI.headerInfo` eklendi (alt sayfa başlığı ve kırıntı düzeldi).
- **Criticality:** `ZVDX_R_NOT`'a `DurumKritiklik` (CASE: T→3 yeşil, A→2 sarı, 0 nötr);
  MDE'de `criticality:` ile Durum, DurumText ve headerInfo description renkli.
  Root'a alan eklemek draft tablosunun **recreate**'ini gerektirdi.
- **Value help:** `@Consumption.valueHelpDefinition` → `ZVDX_I_DURUM_VH`. Domain
  `ZVDX_DURUM` (A/T) yaratıldı ama `DDCDS_CUSTOMER_DOMAIN_VALUE_T` bu appliance'ta boş
  döndü; VH `select distinct from ZVDX_R_NOT` ile kuruldu (yalnız kullanımda olan
  değerler — bir durumda hiç kayıt kalmazsa o değer listeden düşer). Filtre çubuğunda
  çoklu seçimli dropdown ("A (Açık)", `#TEXT_LAST`, `#XS`).
- **Timestamp:** `OlusturmaSaati` (türetilmiş, UTC) gizlendi; `Olusturma` timestamp'i ve
  `LastChangedAt` field group'a alındı → FE yerel saate çevirdi (05:07 UTC → 08:07).
- **Boolean:** `abap_boolean` görüntüleme modunda Yes/No, düzenlemede checkbox — düzeltme
  gerekmedi.

Öğrenilenler:
- **Draft'ta türetilmiş alan hesaplanmaz, kopyalanır.** Root'a eklenen `DurumKritiklik`
  mevcut draft'larda 0 kaldı → sahibi listede ikonsuz gördü; F8 aktifi gösterdiği için 3
  görünüyordu. Draft'lar temizlenince ikon geldi. Aynı mekanizma Konu 16'daki
  "createdAt boş" yanılgısını da açıkladı.
- **Recreate draft table** mevcut satırları silmez, dönüştürür; yeni alan initial kalır.
  Root view'a alan eklemeden önce açık draft bırakma.
- `_D`'den SE16 ile satır silmek sandbox işi; gerçek sistemde draft admin verisi yetim
  kalır — Discard ya da `SAP_DRAFT_CLEANUP`.
- Root view'daki her alan değişikliği: draft tablosu recreate + binding republish +
  `/IWFND/CACHE_CLEANUP` + tarayıcıda hard refresh.

### Konu 19 — Determination + EML, ABAP Unit
- **`setSira`** (child, `on modify { create; }`, ayrı local class `lhc_adimlar`):
  tetiklenen adımlardan Sira'sı boş olanları oku → `Notlar BY \_Adimlar` ile notun mevcut
  adımlarını oku (`keys` yalnız yeni adımları taşır; max için notun tümü gerekir) → not
  bazında max → her yeni adıma max+1 (aynı istekte ardışık) →
  `MODIFY ENTITIES … IN LOCAL MODE UPDATE FIELDS ( Sira )`. COMMIT yok, LUW framework'ün.
  Sira düzenlenebilir bırakıldı; determination yalnız boşsa doldurur. Doğrulandı: 1, 2.
- **ABAP Unit** (`ZBP_VDX_R_NOT` Test Classes, `ltc_not`, 4 test, ~2 sn):
  `create_durum_a_olur` (Konu 13 determination), `tamamla_durum_t_yapar` (Konu 14 action,
  feature + yetki katmanından geçerek), `bos_baslik_kaydedilmez` (Konu 16 validation —
  `on save` olduğu için ancak `COMMIT ENTITIES RESPONSE OF … FAILED` ile görülür),
  `adimlar_sira_alir` (Konu 17 CBA + Konu 19). `cl_osql_test_environment` dört tabloyu
  (aktif + draft) double'lar; gerçek tablolara satır yazılmaz. `ROLLBACK ENTITIES` her
  testte buffer'ı sıfırlar.
- Test dışarıdan EML: `IN LOCAL MODE` yok → yetki/feature kontrolleri çalışır; test
  kullanıcısının (BPINST, `Z_VDX_DEV`) yetkisi test sonucunun parçasıdır.
- Kanıt: beklenen değeri bilerek bozunca kırmızı + Failure Trace ("Expected B, Actual A").

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
| Tablo | `ZVDX_NOTLAR`, `ZVDX_NOTLAR_D`, `ZVDX_ADIMLAR`, `ZVDX_ADIMLAR_D` |
| Domain | `ZVDX_DURUM` |
| CDS | `ZVDX_R_NOT`, `ZVDX_R_ADIM` (root), `ZVDX_C_NOT`, `ZVDX_C_ADIM` (projection), `ZVDX_I_DURUM_VH` |
| MDE | `ZVDX_C_NOT`, `ZVDX_C_ADIM` |
| BDEF | `ZVDX_R_NOT` (managed, draft, 2 entity), `ZVDX_C_NOT` (projection) |
| Sınıf | `ZBP_VDX_R_NOT` (handler + `ltc_not` test sınıfı), `ZCL_ZVDX_NOT_SRV_DPC_EXT` / `_MPC_EXT`, `ZCL_ZVDX_SAYAC_SRV_*` |
| Program | `ZVDX_NOT_DOLDUR` (test verisi) |
| Servis | `ZVDX_SAYAC_SRV`, `ZVDX_NOT_SRV` (SEGW); `ZVDX_SD_NOT` → `ZVDX_SB_NOT_O2` (V2), `ZVDX_SB_NOT_O4` (V4) |
| BSP | `ZVDX_SAYAC_UI`, `ZVDX_NOT_UI`, `ZVDX_NOT_FE`, `ZVDX_NOT_FE4` |
| Yetki | SU21 `ZVDX_NOT` (ACTVT 01/02/06); roller: GOZDE'nin uygulama rolü, `Z_FLP_USER`, `Z_VDX_DEV` (BPINST) — `docs/` altında |

## Yetki özeti

| Kim | `ZVDX_NOT` ACTVT | Sonuç |
|---|---|---|
| GOZDE | 02, 06 (01 yok) | Create V2'de görünür/reddedilir, V4'te yok; kendi açık notunu siler |
| BPINST | 01, 02, 06 (`Z_VDX_DEV`) | Geliştirme + Preview |

## Durum

Müfredat tamamlandı (17 Eylül 2026). Son abapGit export ve `docs/` artefaktları bu commit'te.
Olası devam konuları: T100 message class, unmanaged/additional save senaryosu, Fiori
Elements V4 flexible programming model (custom section/action), CAP ile aynı BO.
