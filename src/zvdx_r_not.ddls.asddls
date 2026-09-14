@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Notlar - Root (RAP BO)'
define root view entity ZVDX_R_NOT
  as select from zvdx_notlar 
    composition [0..*] of ZVDX_R_ADIM as _Adimlar
{
  key not_id    as NotId,
      baslik    as Baslik,
      durum     as Durum,
            _Adimlar,

      case durum
        when 'T' then 'Tamamlandı'
        else 'Açık'
      end       as DurumText,
      
      case durum
        when 'T' then 3
        when 'A' then 2
        else 0
      end                   as DurumKritiklik,      

      tstmp_to_dats( olusturma,
                     abap_system_timezone( $session.client, 'NULL' ),
                     $session.client, 'NULL' ) as OlusturmaTarihi,

      tstmp_to_tims( olusturma,
                     abap_system_timezone( $session.client, 'NULL' ),
                     $session.client, 'NULL' ) as OlusturmaSaati,

      @Semantics.systemDateTime.createdAt: true
      olusturma as Olusturma,
      
      @Semantics.user.createdBy: true
      created_by as CreatedBy,
      
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt
         
}
