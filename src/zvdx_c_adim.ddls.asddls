@EndUserText.label: 'Not adımı'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity ZVDX_C_ADIM
  as projection on ZVDX_R_ADIM
{
      @UI.facet: [{ id: 'Adim', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,
                    label: 'Adım', position: 10 }]
      @UI.hidden: true
  key AdimId,
      @UI.hidden: true
      NotId,
      @UI.lineItem: [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
      @EndUserText.label: 'Sıra'
      Sira,
      @UI.lineItem: [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
      @EndUserText.label: 'Açıklama'
      Aciklama,
      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 30 }]
      @EndUserText.label: 'Tamam'
      Tamam,
      @UI.hidden: true
      LastChangedAt,
      @UI.hidden: true
      LocalLastChangedAt,
      _Not : redirected to parent ZVDX_C_NOT
}
