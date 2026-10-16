FUNCTION y_qmlims_service_uhrzeit_f4.
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

  DATA: lv_uzeit LIKE sy-uzeit.
  DATA: ls_value TYPE rctvalues.

  CLEAR ls_value.
  CLEAR values.

  CALL FUNCTION 'F4_CLOCK'
    IMPORTING
      selected_time = lv_uzeit.

  WRITE lv_uzeit TO ls_value-val_descr.
  WRITE lv_uzeit TO ls_value-value.
  ls_value-status = 'H'.

  APPEND ls_value TO values.

ENDFUNCTION.
