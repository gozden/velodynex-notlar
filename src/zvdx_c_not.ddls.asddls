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
          targetQualifier: 'ZamanGrubu', label: 'Oluşturma Bilgisi', position: 20 },
      { id: 'Adimlar', purpose: #STANDARD, type: #LINEITEM_REFERENCE,
      label: 'Adımlar', position: 30, targetElement: '_Adimlar' }
      ]

      @UI.lineItem:       [{ position: 10, importance: #LOW }]
      @UI.identification: [{ position: 10 }]
      @EndUserText.label: 'Not No'
  key NotId,

      @UI.lineItem: [ { position: 20, importance: #HIGH },
                      { type: #FOR_ACTION, dataAction: 'tamamla', label: 'Tamamla' } ]
      @UI.identification: [ { position: 20 },
                            { type: #FOR_ACTION, dataAction: 'tamamla', label: 'Tamamla' } ]
      @Search.defaultSearchElement: true
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

      @UI.lineItem:       [{ position: 50, importance: #LOW }]
      @UI.fieldGroup:     [{ qualifier: 'ZamanGrubu', position: 30 }]
      @EndUserText.label: 'Oluşturan'
      CreatedBy,

      @UI.hidden: true
      Olusturma,

      @UI.hidden: true
      LastChangedAt,
      @UI.hidden: true
      LocalLastChangedAt,

      _Adimlar : redirected to composition child ZVDX_C_ADIM

}
