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

ENDCLASS.

CLASS lhc_notlar IMPLEMENTATION.

  METHOD earlynumbering_create.
    LOOP AT entities INTO DATA(ls_entity).
      IF ls_entity-NotId IS NOT INITIAL.
        APPEND CORRESPONDING #( ls_entity ) TO mapped-notlar.
        CONTINUE.
      ENDIF.

      TRY.
          DATA(lv_uuid) = cl_system_uuid=>create_uuid_c32_static( ).
        CATCH cx_uuid_error.
          APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-notlar.
          APPEND VALUE #( %cid = ls_entity-%cid
                          %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = 'UUID üretilemedi' ) )
                 TO reported-notlar.
          CONTINUE.
      ENDTRY.

      APPEND VALUE #( %cid  = ls_entity-%cid
                      %key  = ls_entity-%key
                      NotId = lv_uuid ) TO mapped-notlar.
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
        FIELDS ( Durum ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_notlar).

    result = VALUE #( FOR ls_not IN lt_notlar
                      ( %tky            = ls_not-%tky
                        %action-tamamla = COND #( WHEN ls_not-Durum = 'T'
                                                  THEN if_abap_behv=>fc-o-disabled
                                                  ELSE if_abap_behv=>fc-o-enabled )
                        %delete         = COND #( WHEN ls_not-Durum = 'T'
                                                  THEN if_abap_behv=>fc-o-disabled
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
ENDCLASS.
