@EndUserText.label: 'Not adımı'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity ZVDX_C_ADIM
  as projection on ZVDX_R_ADIM
{

  key AdimId,
     NotId,
      @EndUserText.label: 'Sıra'
      Sira,
    @EndUserText.label: 'Açıklama'
      Aciklama,
     @EndUserText.label: 'Tamam'
      Tamam,
      LastChangedAt,
    LocalLastChangedAt,
      _Not : redirected to parent ZVDX_C_NOT
}
