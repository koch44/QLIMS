FUNCTION y_qmlims_service_datum_f4.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(CHARACT_NO) TYPE  CABN-ATINN OPTIONAL
*"     VALUE(CHARACT) TYPE  CABN-ATNAM OPTIONAL
*"     VALUE(DISPLAY) TYPE  XFELD OPTIONAL
*"     VALUE(ADDITIONAL_VALUES) TYPE  CABN-ATSON OPTIONAL
*"     VALUE(MULTIPLE_VALUES) TYPE  RCTMV-ATLIS OPTIONAL
*"     VALUE(LANGUAGE) TYPE  SYLANGU OPTIONAL
*"     VALUE(DISPLAY_WITH_LANGUAGE) TYPE  XFELD OPTIONAL
*"  TABLES
*"      VALUES STRUCTURE  RCTVALUES
*"  EXCEPTIONS
*"      NOT_FOUND
*"----------------------------------------------------------------------

  DATA: lv_datum LIKE sy-datum.
  DATA: ls_value TYPE rctvalues.

  CLEAR ls_value.

  CALL FUNCTION 'F4_DATE_CONTROL'
    IMPORTING
      select_date                  = lv_datum
    EXCEPTIONS
      calendar_buffer_not_loadable = 1
      date_after_range             = 2
      date_before_range            = 3
      date_invalid                 = 4
      factory_calendar_not_found   = 5
      holiday_calendar_not_found   = 6
      parameter_conflict           = 7
      OTHERS                       = 8.
  IF sy-subrc <> 0.
    CLEAR values.
  ELSE.
    WRITE lv_datum TO ls_value-val_descr.
    WRITE lv_datum TO ls_value-value.
    ls_value-status = 'H'.

    APPEND ls_value TO values.
  ENDIF.


ENDFUNCTION.
