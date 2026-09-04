@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Notlar - Root (RAP BO)'
define root view entity ZVDX_R_NOT
  as select from zvdx_notlar
{
  key not_id    as NotId,
      baslik    as Baslik,
      durum     as Durum,

      case durum
        when 'T' then 'Tamamlandı'
        else 'Açık'
      end       as DurumText,

      tstmp_to_dats( olusturma,
                     abap_system_timezone( $session.client, 'NULL' ),
                     $session.client, 'NULL' ) as OlusturmaTarihi,

      tstmp_to_tims( olusturma,
                     abap_system_timezone( $session.client, 'NULL' ),
                     $session.client, 'NULL' ) as OlusturmaSaati,

      @Semantics.systemDateTime.createdAt: true
      olusturma as Olusturma
}
