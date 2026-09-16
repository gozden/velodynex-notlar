CLASS ltc_not DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA sql_env TYPE REF TO if_osql_test_environment.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.

    METHODS create_durum_a_olur      FOR TESTING.
    METHODS tamamla_durum_t_yapar    FOR TESTING.
    METHODS bos_baslik_kaydedilmez   FOR TESTING.
    METHODS adimlar_sira_alir        FOR TESTING.
ENDCLASS.


CLASS ltc_not IMPLEMENTATION.

  METHOD class_setup.
    sql_env = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZVDX_NOTLAR' ) ( 'ZVDX_NOTLAR_D' )
                                   ( 'ZVDX_ADIMLAR' ) ( 'ZVDX_ADIMLAR_D' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_env->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_env->clear_doubles( ).
    ROLLBACK ENTITIES.
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
  ENDMETHOD.

  " Konu 13: determination setDurum → yeni not 'A'
  METHOD create_durum_a_olur.
    MODIFY ENTITIES OF zvdx_r_not
      ENTITY Notlar
        CREATE FIELDS ( Baslik ) WITH VALUE #( ( %cid = 'N1' Baslik = 'Unit test notu' ) )
      MAPPED DATA(mapped) FAILED DATA(failed) REPORTED DATA(reported).

    cl_abap_unit_assert=>assert_initial( act = failed-notlar msg = 'Create başarısız' ).

    READ ENTITIES OF zvdx_r_not
      ENTITY Notlar
        FIELDS ( Durum ) WITH VALUE #( ( %tky = mapped-notlar[ 1 ]-%tky ) )
      RESULT DATA(notlar).

    cl_abap_unit_assert=>assert_equals( act = notlar[ 1 ]-Durum exp = 'A' ).
  ENDMETHOD.

  " Konu 14: action tamamla → 'T'
  METHOD tamamla_durum_t_yapar.
    MODIFY ENTITIES OF zvdx_r_not
      ENTITY Notlar
        CREATE FIELDS ( Baslik ) WITH VALUE #( ( %cid = 'N1' Baslik = 'Tamamlanacak' ) )
      MAPPED DATA(mapped).

    MODIFY ENTITIES OF zvdx_r_not
      ENTITY Notlar
        EXECUTE tamamla FROM VALUE #( ( %tky = mapped-notlar[ 1 ]-%tky ) )
      RESULT DATA(sonuc) FAILED DATA(failed).

    cl_abap_unit_assert=>assert_initial( act = failed-notlar msg = 'Action başarısız' ).
    cl_abap_unit_assert=>assert_equals( act = sonuc[ 1 ]-%param-Durum exp = 'T' ).
  ENDMETHOD.

  " Konu 16: validation validateBaslik → boş başlık kaydedilmez
  METHOD bos_baslik_kaydedilmez.
    MODIFY ENTITIES OF zvdx_r_not
      ENTITY Notlar
        CREATE FIELDS ( Baslik ) WITH VALUE #( ( %cid = 'N1' Baslik = '' ) )
      MAPPED DATA(mapped).

    COMMIT ENTITIES RESPONSE OF zvdx_r_not
      FAILED DATA(commit_failed)
      REPORTED DATA(commit_reported).

    cl_abap_unit_assert=>assert_not_initial( act = commit_failed-notlar
                                             msg = 'Boş başlık kaydedildi' ).
  ENDMETHOD.

  " Konu 17 + 19: CBA + determination setSira → 1, 2
  METHOD adimlar_sira_alir.
    MODIFY ENTITIES OF zvdx_r_not
      ENTITY Notlar
        CREATE FIELDS ( Baslik ) WITH VALUE #( ( %cid = 'N1' Baslik = 'Adımlı not' ) )
        CREATE BY \_Adimlar
          FIELDS ( Aciklama ) WITH VALUE #( ( %cid_ref = 'N1'
                                             %target  = VALUE #( ( %cid = 'A1' Aciklama = 'ilk' )
                                                                 ( %cid = 'A2' Aciklama = 'ikinci' ) ) ) )
      MAPPED DATA(mapped) FAILED DATA(failed).

    cl_abap_unit_assert=>assert_initial( act = failed msg = 'CBA başarısız' ).

    READ ENTITIES OF zvdx_r_not
      ENTITY Adimlar
        FIELDS ( Sira ) WITH CORRESPONDING #( mapped-adimlar )
      RESULT DATA(adimlar).

    SORT adimlar BY Sira.
    cl_abap_unit_assert=>assert_equals( act = lines( adimlar ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = adimlar[ 1 ]-Sira exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = adimlar[ 2 ]-Sira exp = 2 ).
  ENDMETHOD.

ENDCLASS.
