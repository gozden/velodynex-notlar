@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Durum değer yardımı'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZVDX_I_DURUM_VH
  as select distinct from ZVDX_R_NOT
{
      @ObjectModel.text.element: ['Aciklama']
      @UI.textArrangement: #TEXT_LAST
      @EndUserText.label: 'Durum'
  key Durum,
      @Semantics.text: true
      @EndUserText.label: 'Açıklama'
      DurumText as Aciklama
}
