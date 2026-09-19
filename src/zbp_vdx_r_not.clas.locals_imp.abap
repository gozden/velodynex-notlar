CLASS lsc_zvdx_r_not DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zvdx_r_not IMPLEMENTATION.

  METHOD save_modified.
    DATA loglar TYPE TABLE OF zvdx_not_log.
    GET TIME STAMP FIELD DATA(simdi).

    " Yeni notlar
    LOOP AT create-notlar INTO DATA(c) .
      TRY.
          APPEND VALUE #( log_id    = cl_system_uuid=>create_uuid_c32_static( )
                          not_id    = c-notid
                          islem     = 'C'
                          baslik    = c-baslik
                          kullanici = sy-uname
                          zaman     = simdi ) TO loglar.
        CATCH cx_uuid_error.
          "handle exception
      ENDTRY.
    ENDLOOP.

    " Güncellenen notlar: Durum 'T'ye döndüyse T, aksi halde U
    LOOP AT update-notlar INTO DATA(u) .
      TRY.
          APPEND VALUE #( log_id    = cl_system_uuid=>create_uuid_c32_static( )
                          not_id    = u-notid
                          islem     = COND #( WHEN u-%control-durum = if_abap_behv=>mk-on
                                               AND u-durum = 'T'
                                              THEN 'T' ELSE 'U' )
                          baslik    = u-baslik
                          kullanici = sy-uname
                          zaman     = simdi ) TO loglar.
        CATCH cx_uuid_error.
          "handle exception
      ENDTRY.
    ENDLOOP.

    " Silinen notlar (yalnız anahtar gelir)
    LOOP AT delete-notlar INTO DATA(d) .
      TRY.
          APPEND VALUE #( log_id    = cl_system_uuid=>create_uuid_c32_static( )
                          not_id    = d-notid
                          islem     = 'D'
                          kullanici = sy-uname
                          zaman     = simdi ) TO loglar.
        CATCH cx_uuid_error.
          "handle exception
      ENDTRY.
    ENDLOOP.

    IF loglar IS NOT INITIAL.
      INSERT zvdx_not_log FROM TABLE @loglar.
    ENDIF.
    " COMMIT yok — LUW framework'ün
  ENDMETHOD.

ENDCLASS.

CLASS lhc_notlar DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Notlar.

    METHODS setDurumVarsayilan FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Notlar~setDurumVarsayilan.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Notlar RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Notlar RESULT result.

    METHODS tamamla FOR MODIFY
      IMPORTING keys FOR ACTION Notlar~tamamla RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Notlar RESULT result.

    METHODS validateBaslik FOR VALIDATE ON SAVE
      IMPORTING keys FOR Notlar~validateBaslik.

    METHODS earlynumbering_cba_Adimlar FOR NUMBERING
      IMPORTING entities FOR CREATE Notlar\_Adimlar.
ENDCLASS.

CLASS lhc_notlar IMPLEMENTATION.

  METHOD earlynumbering_create.
    " Anahtarı zaten dolu gelenler (Activate yolu): olduğu gibi geri ver
    LOOP AT entities INTO DATA(entity) WHERE NotId IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-notlar.
    ENDLOOP.

    " Anahtarsız gelenler (yeni draft / doğrudan create): üret
    LOOP AT entities INTO entity WHERE NotId IS INITIAL.
      TRY.
          DATA(uuid) = cl_system_uuid=>create_uuid_c32_static( ).
        CATCH cx_uuid_error.
          APPEND VALUE #( %cid      = entity-%cid
                          %is_draft = entity-%is_draft ) TO failed-notlar.
          CONTINUE.
      ENDTRY.

      APPEND VALUE #( %cid      = entity-%cid
                      %is_draft = entity-%is_draft
                      NotId     = uuid ) TO mapped-notlar.
    ENDLOOP.
  ENDMETHOD.

  METHOD setDurumVarsayilan.
    READ ENTITIES OF zvdx_r_not IN LOCAL MODE
      ENTITY Notlar
        FIELDS ( Durum ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_notlar).

    DELETE lt_notlar WHERE Durum IS NOT INITIAL.
    CHECK lt_notlar IS NOT INITIAL.

    MODIFY ENTITIES OF zvdx_r_not IN LOCAL MODE
      ENTITY Notlar
        UPDATE FIELDS ( Durum )
        WITH VALUE #( FOR ls_notlar IN lt_notlar
                      ( %tky  = ls_notlar-%tky
                        Durum = 'A' ) ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
    DATA lv_update_ok TYPE abap_bool.
    DATA lv_delete_ok TYPE abap_bool.

    AUTHORITY-CHECK OBJECT 'ZVDX_NOT' ID 'ACTVT' FIELD '02'.
    lv_update_ok = xsdbool( sy-subrc = 0 ).

    AUTHORITY-CHECK OBJECT 'ZVDX_NOT' ID 'ACTVT' FIELD '06'.
    lv_delete_ok = xsdbool( sy-subrc = 0 ).

    " Kural: tamamlanmış (Durum='T') not silinemez, yetki olsa bile
    READ ENTITIES OF zvdx_r_not IN LOCAL MODE
      ENTITY Notlar
        FIELDS ( Durum CreatedBy ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_notlar).

    result = VALUE #( FOR ls_not IN lt_notlar
      ( %tky            = ls_not-%tky
        %update         = COND #( WHEN lv_update_ok = abap_true
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
        %action-tamamla = COND #( WHEN lv_update_ok = abap_true
                                  THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized )
        %delete = COND #( WHEN lv_delete_ok = abap_true AND ls_not-CreatedBy = sy-uname
                     THEN if_abap_behv=>auth-allowed
                     ELSE if_abap_behv=>auth-unauthorized ) ) ).
  ENDMETHOD.

  METHOD tamamla.
    " 1. Durum = 'T' yap
    MODIFY ENTITIES OF zvdx_r_not IN LOCAL MODE
      ENTITY Notlar
        UPDATE FIELDS ( Durum )
        WITH VALUE #( FOR key IN keys
                      ( %tky  = key-%tky
                        Durum = 'T' ) )
      FAILED   failed
      REPORTED reported.

    " 2. Güncel halini oku ve result olarak döndür ($self)
    READ ENTITIES OF zvdx_r_not IN LOCAL MODE
      ENTITY Notlar
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_notlar).

    result = VALUE #( FOR ls_not IN lt_notlar
                      ( %tky   = ls_not-%tky
                        %param = ls_not ) ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zvdx_r_not IN LOCAL MODE
      ENTITY Notlar
        FIELDS ( Durum CreatedBy ) WITH CORRESPONDING #( keys )
      RESULT DATA(notlar).

    result = VALUE #( FOR satir IN notlar
      ( %tky = satir-%tky

        " Draft'ta action kapalı: önce Save, sonra Tamamla
        %action-tamamla = COND #(
          WHEN satir-%is_draft = if_abap_behv=>mk-on THEN if_abap_behv=>fc-o-disabled
          WHEN satir-Durum = 'T'                     THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled )

        " Draft'ta Delete = Discard, serbest; aktifte eski kural
        %delete = COND #(
          WHEN satir-%is_draft = if_abap_behv=>mk-on THEN if_abap_behv=>fc-o-enabled
          WHEN satir-Durum = 'T'                     THEN if_abap_behv=>fc-o-disabled
          WHEN satir-CreatedBy <> sy-uname           THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled ) ) ).
  ENDMETHOD.

  METHOD get_global_authorizations.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'ZVDX_NOT' ID 'ACTVT' FIELD '01'.
      result-%create = COND #( WHEN sy-subrc = 0
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
  ENDMETHOD.

  METHOD validateBaslik.
    READ ENTITIES OF zvdx_r_not IN LOCAL MODE
      ENTITY Notlar
        FIELDS ( Baslik ) WITH CORRESPONDING #( keys )
      RESULT DATA(notlar).

    LOOP AT notlar INTO DATA(satir).
      IF satir-Baslik IS INITIAL.
        APPEND VALUE #( %tky = satir-%tky ) TO failed-notlar.
        APPEND VALUE #( %tky        = satir-%tky
                        %state_area = 'VALIDATE_BASLIK'
                        %msg = new_message(
                                 id       = 'ZVDX_NOT'
                                 number   = '001'
                                 severity = if_abap_behv_message=>severity-error )
                        %element-baslik = if_abap_behv=>mk-on ) TO reported-notlar.
      ELSE.
        APPEND VALUE #( %tky        = satir-%tky
                        %state_area = 'VALIDATE_BASLIK' ) TO reported-notlar.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Adimlar.
    LOOP AT entities INTO DATA(entity).
      LOOP AT entity-%target INTO DATA(adim).

        " Anahtarı dolu gelenler (Activate yolu): aynen geri ver
        IF adim-AdimId IS NOT INITIAL.
          APPEND CORRESPONDING #( adim ) TO mapped-adimlar.
          CONTINUE.
        ENDIF.

        TRY.
            DATA(uuid) = cl_system_uuid=>create_uuid_c32_static( ).
          CATCH cx_uuid_error.
            APPEND VALUE #( %cid      = adim-%cid
                            %is_draft = adim-%is_draft ) TO failed-adimlar.
            CONTINUE.
        ENDTRY.

        APPEND VALUE #( %cid      = adim-%cid
                        %is_draft = adim-%is_draft
                        AdimId    = uuid ) TO mapped-adimlar.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_adimlar DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setSira FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Adimlar~setSira.
ENDCLASS.

CLASS lhc_adimlar IMPLEMENTATION.

  METHOD setSira.
    " 1) Tetiklenen adımlardan Sira'sı boş olanlar
    READ ENTITIES OF zvdx_r_not IN LOCAL MODE
      ENTITY Adimlar
        FIELDS ( Sira NotId ) WITH CORRESPONDING #( keys )
      RESULT DATA(yeni_adimlar).

    DELETE yeni_adimlar WHERE Sira IS NOT INITIAL.
    CHECK yeni_adimlar IS NOT INITIAL.

    " 2) İlgili notların mevcut tüm adımları (parent → child okuma)
    READ ENTITIES OF zvdx_r_not IN LOCAL MODE
      ENTITY Notlar BY \_Adimlar
        FIELDS ( Sira NotId )
        WITH VALUE #( FOR a IN yeni_adimlar
                      ( %tky-NotId     = a-NotId
                        %tky-%is_draft = a-%is_draft ) )
      RESULT DATA(mevcut_adimlar).

    " 3) Not bazında max Sira
    TYPES: BEGIN OF ty_max,
             notid TYPE sysuuid_c32,
             sira  TYPE int2,
           END OF ty_max.
    DATA maxlar TYPE HASHED TABLE OF ty_max WITH UNIQUE KEY notid.

    LOOP AT mevcut_adimlar INTO DATA(m).
      READ TABLE maxlar ASSIGNING FIELD-SYMBOL(<mx>) WITH TABLE KEY notid = m-NotId.
      IF sy-subrc <> 0.
        INSERT VALUE #( notid = m-NotId sira = m-Sira ) INTO TABLE maxlar ASSIGNING <mx>.
      ELSEIF m-Sira > <mx>-sira.
        <mx>-sira = m-Sira.
      ENDIF.
    ENDLOOP.

    " 4) Her yeni adıma max+1, aynı notta ardışık
    DATA guncelle TYPE TABLE FOR UPDATE zvdx_r_not\\Adimlar.

    LOOP AT yeni_adimlar INTO DATA(y).
      READ TABLE maxlar ASSIGNING <mx> WITH TABLE KEY notid = y-NotId.
      IF sy-subrc <> 0.
        INSERT VALUE #( notid = y-NotId sira = 0 ) INTO TABLE maxlar ASSIGNING <mx>.
      ENDIF.
      <mx>-sira += 1.
      APPEND VALUE #( %tky = y-%tky
                      Sira = <mx>-sira ) TO guncelle.
    ENDLOOP.

    " 5) Yaz — COMMIT yok, LUW framework'ün
    MODIFY ENTITIES OF zvdx_r_not IN LOCAL MODE
      ENTITY Adimlar
        UPDATE FIELDS ( Sira ) WITH guncelle
      REPORTED DATA(guncelle_reported).

    reported = CORRESPONDING #( DEEP guncelle_reported ).
  ENDMETHOD.

ENDCLASS.
