*----------------------------------------------------------------------*
* ZCL_ZVDX_NOT_DPC_EXT — yeniden tanımlanan metotlar
* Konuşma kayıtlarından derlenmiştir; SE24'teki gerçek kodla karşılaştır.
* GET_ENTITY kayıtta tam görünmediği için aşağıdaki hali yeniden kurgulanmıştır.
*----------------------------------------------------------------------*

*======================================================================*
* NOTLARSET_GET_ENTITYSET — $filter / $orderby / $inlinecount destekli
*======================================================================*
METHOD notlarset_get_entityset.

  " 1) $filter → dinamik WHERE (Gateway OData ifadesini Open SQL'e çevirir)
  DATA(lv_where) = io_tech_request_context->get_osql_where_clause( ).

  " 2) $orderby → dinamik ORDER BY; yoksa varsayılan: yeni en üstte
  DATA(lv_orderby) = ``.
  LOOP AT io_tech_request_context->get_orderby( ) INTO DATA(ls_order).
    DATA(lv_dir) = COND string( WHEN ls_order-order = 'desc' THEN 'DESCENDING' ELSE 'ASCENDING' ).
    lv_orderby = |{ lv_orderby }{ COND #( WHEN lv_orderby IS INITIAL THEN `` ELSE `, ` ) }{ to_lower( ls_order-property ) } { lv_dir }|.
  ENDLOOP.
  IF lv_orderby IS INITIAL.
    lv_orderby = `olusturma DESCENDING`.
  ENDIF.

  " 3) Sorgu
  SELECT * FROM zvdx_notlar
    WHERE (lv_where)
    ORDER BY (lv_orderby)
    INTO CORRESPONDING FIELDS OF TABLE @et_entityset.

  " 4) $inlinecount=allpages → toplam sayı
  IF io_tech_request_context->has_inlinecount( ) = abap_true.
    es_response_context-inlinecount = lines( et_entityset ).
  ENDIF.

ENDMETHOD.

*======================================================================*
* NOTLARSET_GET_ENTITY — tek kayıt (yeniden kurgulandı)
*======================================================================*
METHOD notlarset_get_entity.

  DATA(lv_not_id) = VALUE #( it_key_tab[ name = 'NotId' ]-value OPTIONAL ).

  SELECT SINGLE * FROM zvdx_notlar
    INTO CORRESPONDING FIELDS OF @er_entity
    WHERE not_id = @lv_not_id.

  IF sy-subrc <> 0.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING textid = /iwbep/cx_mgw_busi_exception=>resource_not_found.
  ENDIF.

ENDMETHOD.

*======================================================================*
* NOTLARSET_CREATE_ENTITY — POST
*======================================================================*
METHOD notlarset_create_entity.

  DATA: ls_notlar TYPE zvdx_notlar.

  " Gelen payload'u al
  io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

  " Teknik alanları backend doldurur
  TRY.
      er_entity-not_id = cl_system_uuid=>create_uuid_c32_static( ).
    CATCH cx_uuid_error.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception.
  ENDTRY.

  GET TIME STAMP FIELD er_entity-olusturma.
  IF er_entity-durum IS INITIAL.
    er_entity-durum = 'A'.
  ENDIF.

  MOVE-CORRESPONDING er_entity TO ls_notlar.
  INSERT zvdx_notlar FROM ls_notlar.

  IF sy-subrc <> 0.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception.
  ENDIF.

ENDMETHOD.

*======================================================================*
* NOTLARSET_UPDATE_ENTITY — PUT / MERGE
*======================================================================*
METHOD notlarset_update_entity.

  DATA: ls_notlar TYPE zvdx_notlar.

  " 1) URL'deki key
  DATA(lv_not_id) = VALUE #( it_key_tab[ name = 'NotId' ]-value OPTIONAL ).

  " 2) Mevcut kaydı oku — yoksa 404
  SELECT SINGLE * FROM zvdx_notlar
    INTO @ls_notlar
    WHERE not_id = @lv_not_id.

  IF sy-subrc <> 0.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING textid = /iwbep/cx_mgw_busi_exception=>resource_not_found.
  ENDIF.

  " 3) Gelen gövde
  io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

  " 4) Sadece kullanıcının değiştirebileceği alanlar (MERGE: boş gelen = dokunma)
  IF er_entity-baslik IS NOT INITIAL.
    ls_notlar-baslik = er_entity-baslik.
  ENDIF.
  IF er_entity-durum IS NOT INITIAL.
    ls_notlar-durum = er_entity-durum.
  ENDIF.

  UPDATE zvdx_notlar FROM ls_notlar.

  IF sy-subrc <> 0.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception.
  ENDIF.

  " 5) Güncel hali geri döndür
  MOVE-CORRESPONDING ls_notlar TO er_entity.

ENDMETHOD.

*======================================================================*
* NOTLARSET_DELETE_ENTITY — DELETE
*======================================================================*
METHOD notlarset_delete_entity.

  DATA(lv_not_id) = VALUE #( it_key_tab[ name = 'NotId' ]-value OPTIONAL ).

  DELETE FROM zvdx_notlar WHERE not_id = @lv_not_id.

  IF sy-subrc <> 0.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING textid = /iwbep/cx_mgw_busi_exception=>resource_not_found.
  ENDIF.

ENDMETHOD.
