*&---------------------------------------------------------------------*
*& Report ZVDX_NOT_DOLDUR
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zvdx_not_doldur.

DATA: lt_notlar TYPE TABLE OF zvdx_notlar,
      ls_not    TYPE zvdx_notlar,
      lv_ts     TYPE timestampl.

GET TIME STAMP FIELD lv_ts.

" Kayıt 1
TRY.
    ls_not-not_id = cl_system_uuid=>create_uuid_c32_static( ).
  CATCH cx_uuid_error.
    ls_not-not_id = '0001'.
ENDTRY.
ls_not-baslik    = 'İlk notum - CRUD çalışması'.
ls_not-durum     = 'A'.
ls_not-olusturma = lv_ts.
APPEND ls_not TO lt_notlar.

" Kayıt 2
TRY.
    ls_not-not_id = cl_system_uuid=>create_uuid_c32_static( ).
  CATCH cx_uuid_error.
    ls_not-not_id = '0002'.
ENDTRY.
ls_not-baslik    = 'Launchpad tile listesini gözden geçir'.
ls_not-durum     = 'T'.
APPEND ls_not TO lt_notlar.

INSERT ZVDX_NOTLAR FROM TABLE @LT_NOTLAR.

IF sy-subrc = 0.
  COMMIT WORK.
  WRITE: / |{ lines( lt_notlar ) } kayıt eklendi.|.
ELSE.
  WRITE: / 'Ekleme başarısız (kayıtlar zaten var olabilir).'.
ENDIF.
