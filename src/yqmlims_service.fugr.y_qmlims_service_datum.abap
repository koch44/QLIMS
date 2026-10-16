FUNCTION y_qmlims_service_datum.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(CHARACT_NO) TYPE  CABN-ATINN
*"     REFERENCE(CHARACT) TYPE  CABN-ATNAM
*"     REFERENCE(VALUE) TYPE  CAWN-ATWRT
*"  EXPORTING
*"     REFERENCE(VALUE_EX) TYPE  CAWN-ATWRT
*"  EXCEPTIONS
*"      NOT_FOUND
*"----------------------------------------------------------------------

* Befüülen des Klassenmerkmals TECHNISCHER_PLATZ
  DATA: ls_cuco              TYPE cuco.
  DATA: lv_name_cuco(32)     TYPE c VALUE '(SAPLCEI0)CUCO'.
  DATA: lv_name_instance(32) TYPE c VALUE '(SAPLCEI0)G_CUOBJ'.

*  DATA: ls_values  TYPE ibco2_value_rec.
  DATA: lt_values  TYPE ibco2_value_tab.
  DATA: ls_imp_val TYPE api_vali.
  DATA: lt_imp_val TYPE TABLE OF api_vali.

  FIELD-SYMBOLS <ls_cuco>     TYPE any.
  FIELD-SYMBOLS <lv_instance> TYPE any.

  value_ex = value.

  ASSIGN (lv_name_instance) TO <lv_instance>.
  IF sy-subrc <> 0.
    EXIT.
  ENDIF.

  ASSIGN (lv_name_cuco) TO <ls_cuco>.
  IF sy-subrc = 0.
    ls_cuco = <ls_cuco>.
  ENDIF.

  SELECT SINGLE atinn, atnam, dokar, doknr,
                doktl, dokvr, knobj
   FROM cabn INTO @DATA(ls_cabn)
         WHERE atnam = 'TECHNISCHER_PLATZ             '.
  IF sy-subrc <> 0.
    EXIT.
  ELSE.
    SORT lt_values BY atinn.
  ENDIF.

  CALL FUNCTION 'CEI0_I_HAS_VALUES'
    EXPORTING
      instance         = <lv_instance>
      profile          = ls_cuco
      date             = sy-datlo
    TABLES
      values           = lt_values
    EXCEPTIONS
      invalid_instance = 1
      OTHERS           = 2.
  IF sy-subrc <> 0.
    CLEAR lt_values.
  ENDIF.

  READ TABLE lt_values
    TRANSPORTING no fields "INTO ls_values
    WITH KEY atinn = ls_cabn-atinn.
  IF sy-subrc = 0.
*  Probenanzahl existiert schon --> nichts machen.
    EXIT.
  ELSE.
    MOVE-CORRESPONDING ls_cabn TO ls_imp_val.
    ls_imp_val-atwrt = iflo-tplnr.
    ls_imp_val-atwtb = iflo-tplnr.
    APPEND ls_imp_val TO lt_imp_val.

    CALL FUNCTION 'CEI0_DDB_SET_VALUE_INTERNAL'
      TABLES
        imp_values                    = lt_imp_val
      EXCEPTIONS
        currency_check                = 1
        date_check                    = 2
        format_check                  = 3
        illegal_internal_baseunit     = 4
        interval_check                = 5
        pattern_check                 = 6
        time_check                    = 7
        unit_check                    = 8
        value_not_found               = 9
        no_valid_dimension            = 10
        interval_not_allowed          = 11
        display_mode                  = 12
        characteristic_not_found      = 13
        value_not_possible            = 14
        characteristic_enqueue        = 15
        objectcharacteristic          = 16
        only_one_value_allowed        = 17
        characteristic_not_selectable = 18
        input_to_long                 = 19
        OTHERS                        = 20.
    IF sy-subrc <> 0.
* Implement suitable error handling here
      CLEAR lt_imp_val.
    ENDIF.
  ENDIF.


ENDFUNCTION.
