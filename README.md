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
