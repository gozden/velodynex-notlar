@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Notlar - Fiori Elements Consumption'
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZVDX_C_NOT
  provider contract transactional_query
  as projection on ZVDX_R_NOT
{
      @EndUserText.label: 'Not No'
  key NotId,

      @Search.defaultSearchElement: true
      @EndUserText.label: 'Başlık'
      Baslik,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVDX_I_DURUM_VH', element: 'Durum' },
                                           useForValidation: true }]
      @EndUserText.label: 'Durum'
      Durum,

      @EndUserText.label: 'Durum Açıklaması'
      DurumText,

      DurumKritiklik,

      @EndUserText.label: 'Oluşturma Tarihi'
      OlusturmaTarihi,

      @EndUserText.label: 'Oluşturma Saati'
      OlusturmaSaati,

      @EndUserText.label: 'Oluşturma Zamanı'
      Olusturma,

      @EndUserText.label: 'Oluşturan'
      CreatedBy,

      @EndUserText.label: 'Son Değişiklik'
      LastChangedAt,

      LocalLastChangedAt,

      _Adimlar : redirected to composition child ZVDX_C_ADIM,
      
      _Loglar
}
