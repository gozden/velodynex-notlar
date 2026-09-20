@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Not değişiklik logu'
@UI.headerInfo: { typeName: 'Log', typeNamePlural: 'Log kayıtları' }
define view entity ZVDX_I_LOG
  as select from zvdx_not_log
{
      @UI.hidden: true
  key log_id    as LogId,

      @UI.hidden: true
      not_id    as NotId,

      @UI.hidden: true
      islem     as Islem,

      @UI.lineItem: [{ position: 10 }]
      @EndUserText.label: 'İşlem'
      case islem
        when 'C' then 'Oluşturuldu'
        when 'U' then 'Güncellendi'
        when 'T' then 'Tamamlandı'
        when 'D' then 'Silindi'
        else islem
      end       as IslemText,

      @UI.lineItem: [{ position: 20 }]
      @EndUserText.label: 'Başlık'
      baslik    as Baslik,

      @UI.lineItem: [{ position: 30 }]
      @EndUserText.label: 'Kullanıcı'
      kullanici as Kullanici,

      @UI.lineItem: [{ position: 40 }]
      @EndUserText.label: 'Zaman'
      zaman     as Zaman
}
