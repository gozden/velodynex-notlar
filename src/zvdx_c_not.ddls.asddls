@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Notlar - Fiori Elements Consumption'
@Metadata.allowExtensions: true
@Search.searchable: true
@UI.headerInfo: {
  typeName: 'Not',
  typeNamePlural: 'Notlar',
  title: { type: #STANDARD, value: 'Baslik' },
  description: { type: #STANDARD, value: 'DurumText' }
}
define root view entity ZVDX_C_NOT
  provider contract transactional_query
  as projection on ZVDX_R_NOT
{
      @UI.facet: [
        { id: 'GenelBilgiler', type: #IDENTIFICATION_REFERENCE,
          label: 'Genel Bilgiler', position: 10 },
        { id: 'Zaman', type: #FIELDGROUP_REFERENCE,
          targetQualifier: 'ZamanGrubu', label: 'Oluşturma Bilgisi', position: 20 }
      ]

      @UI.lineItem:       [{ position: 10, importance: #LOW }]
      @UI.identification: [{ position: 10 }]
      @EndUserText.label: 'Not No'
  key NotId,

      @UI.lineItem:       [{ position: 20, importance: #HIGH }]
      @UI.identification: [{ position: 20 }]
      @UI.selectionField: [{ position: 10 }]
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Başlık'
      Baslik,

      @UI.lineItem:       [{ position: 30, importance: #HIGH }]
      @UI.identification: [{ position: 30 }]
      @UI.selectionField: [{ position: 20 }]
      @EndUserText.label: 'Durum'
      Durum,

      @UI.lineItem:       [{ position: 35 }]
      @UI.identification: [{ position: 35 }]
      @EndUserText.label: 'Durum Açıklaması'
      DurumText,

      @UI.lineItem:       [{ position: 40, importance: #MEDIUM }]
      @UI.selectionField: [{ position: 30 }]
      @UI.fieldGroup:     [{ qualifier: 'ZamanGrubu', position: 10 }]
      @EndUserText.label: 'Oluşturma Tarihi'
      OlusturmaTarihi,

      @UI.fieldGroup:     [{ qualifier: 'ZamanGrubu', position: 20 }]
      @EndUserText.label: 'Oluşturma Saati'
      OlusturmaSaati,

      @UI.hidden: true
      Olusturma
}
