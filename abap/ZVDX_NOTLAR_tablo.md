# Tablo ZVDX_NOTLAR (SE11, transparent table)

> NOT: Alan tipleri/uzunlukları konuşma kayıtlarından yeniden kurgulanmıştır.
> SE11'den gerçek tanımı kopyalayıp bu dosyayı düzelt.

| Alan       | Key | Tip          | Açıklama                    |
|------------|-----|--------------|-----------------------------|
| MANDT      | X   | MANDT        | İstemci                     |
| NOT_ID     | X   | SYSUUID_C32  | UUID (backend üretir)       |
| BASLIK     |     | CHAR 120 (?) | Not başlığı                 |
| DURUM      |     | CHAR 1       | A = Açık, T = Tamamlandı    |
| OLUSTURMA  |     | TIMESTAMPL   | Oluşturma zaman damgası     |

Delivery/Maintenance: A, Data class: APPL1, Technical settings: size 0.

# SEGW projesi ZVDX_NOT → servis ZVDX_NOT_SRV
- Entity Type: Notlar (ABAP structure ZVDX_NOTLAR'dan import)
- Entity Set: NotlarSet
- Key: NotId  · Properties: NotId, Baslik, Durum, Olusturma
- Servis kaydı: /IWFND/MAINT_SERVICE, system alias LOCAL
- Runtime sınıfları: ZCL_ZVDX_NOT_MPC / MPC_EXT, ZCL_ZVDX_NOT_DPC / DPC_EXT
