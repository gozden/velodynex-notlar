@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Not adımı'
define view entity ZVDX_R_ADIM
  as select from zvdx_adimlar
  association to parent ZVDX_R_NOT as _Not
    on $projection.NotId = _Not.NotId
{
  key adim_id               as AdimId,
      not_id                as NotId,
      sira                  as Sira,
      aciklama              as Aciklama,
      tamam                 as Tamam,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      _Not
}
