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
define view entity ZVDX_C_NOT
  as select from zvdx_notlar
{
      @UI.facet: [
        { id: 'GenelBilgiler',
          type: #IDENTIFICATION_REFERENCE,
          label: 'Genel Bilgiler',
          position: 10 },
        { id: 'Zaman',
          type: #FIELDGROUP_REFERENCE,
          targetQualifier: 'ZamanGrubu',
          label: 'Oluşturma Bilgisi',
          position: 20 }
      ]

      @UI.lineItem:       [{ position: 10, importance: #LOW }]
      @UI.identification: [{ position: 10 }]
      @EndUserText.label: 'Not No'
  key not_id    as NotId,

      @UI.lineItem:       [{ position: 20, importance: #HIGH }]
      @UI.identification: [{ position: 20 }]
      @UI.selectionField: [{ position: 10 }]
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Başlık'
      baslik    as Baslik,

      @UI.lineItem:       [{ position: 30, importance: #HIGH }]
      @UI.identification: [{ position: 30 }]
      @UI.selectionField: [{ position: 20 }]
      @EndUserText.label: 'Durum'
      durum     as Durum,

      @UI.lineItem: [{ position: 35 }]
      @EndUserText.label: 'Durum Açıklaması'
            case durum
        when 'T' then 'Tamamlandı'
        else 'Açık'
      end as DurumText,
      
      @UI.lineItem:       [{ position: 40, importance: #MEDIUM }]
      @UI.selectionField: [{ position: 30 }]
      @UI.fieldGroup:     [{ qualifier: 'ZamanGrubu', position: 10 }]
      @EndUserText.label: 'Oluşturma Tarihi'
      tstmp_to_dats( olusturma,
                     abap_system_timezone( $session.client, 'NULL' ),
                     $session.client,
                     'NULL' ) as OlusturmaTarihi,

      @UI.fieldGroup:     [{ qualifier: 'ZamanGrubu', position: 20 }]
      @EndUserText.label: 'Oluşturma Saati'
      tstmp_to_tims( olusturma,
                     abap_system_timezone( $session.client, 'NULL' ),
                     $session.client,
                     'NULL' ) as OlusturmaSaati,

      @UI.hidden: true
      @Semantics.systemDateTime.createdAt: true
      olusturma as Olusturma
}
