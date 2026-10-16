FUNCTION y_qmlims_service_qpvk_f4.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(charact_no) TYPE cabn-atinn OPTIONAL
*"     VALUE(charact) TYPE cabn-atnam OPTIONAL
*"     VALUE(display) TYPE xfeld OPTIONAL
*"     VALUE(additional_values) TYPE cabn-atson OPTIONAL
*"     VALUE(multiple_values) TYPE rctmv-atlis OPTIONAL
*"     VALUE(language) TYPE sylangu OPTIONAL
*"     VALUE(display_with_language) TYPE xfeld OPTIONAL
*"  TABLES
*"      values STRUCTURE rctvalues
*"  EXCEPTIONS
*"      not_found
*"----------------------------------------------------------------------

  TYPES:
    BEGIN OF lty_qprvkt,
      prziehverf TYPE qprziehver,
      kurztext   TYPE qkurztext,
    END OF lty_qprvkt.

  DATA lt_return_tab TYPE STANDARD TABLE OF ddshretval WITH EMPTY KEY.
  DATA lt_qprvkt     TYPE STANDARD TABLE OF lty_qprvkt WITH EMPTY KEY.
  DATA lv_language   TYPE sylangu.

  CLEAR values[].

  lv_language = COND #( WHEN language IS NOT INITIAL
                        THEN language
                        ELSE sy-langu ).

  SELECT prziehverf,
         kurztext
    FROM qprvkt
    WHERE sprache = @lv_language
    INTO TABLE @lt_qprvkt.
  IF sy-subrc <> 0.
    CLEAR lt_qprvkt.
  ENDIF.

  IF lt_qprvkt IS INITIAL.
    RAISE not_found.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'PRZIEHVERF'
      value_org       = 'S'
    TABLES
      value_tab       = lt_qprvkt
      return_tab      = lt_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0 OR lt_return_tab IS INITIAL.
    RAISE not_found.
  ENDIF.

  LOOP AT lt_return_tab INTO DATA(ls_return_tab).
    APPEND VALUE #( value  = ls_return_tab-fieldval
                    status = 'I' ) TO values.
  ENDLOOP.

ENDFUNCTION.
