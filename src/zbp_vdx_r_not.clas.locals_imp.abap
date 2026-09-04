CLASS lhc_notlar DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Notlar.

    METHODS setDurumVarsayilan FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Notlar~setDurumVarsayilan.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Notlar RESULT result.
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
    " Şimdilik yetki kontrolü yok; herkes her şeyi yapabilir.
  ENDMETHOD.
ENDCLASS.
