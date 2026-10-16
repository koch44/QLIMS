*----------------------------------------------------------------------*
***INCLUDE ZXQQMI01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0110  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0110 INPUT.

  DATA: lv_okcode TYPE sy-ucomm.
  DATA: lv_aufnr  TYPE caufvd-aufnr.

  PERFORM get_ok_code CHANGING lv_okcode.

  CASE lv_okcode.
    WHEN 'PUSH_PLOS'.
      SET PARAMETER ID 'QLS' FIELD viqmel-prueflos.

      CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
        EXPORTING
          tcode  = 'QA13'
        EXCEPTIONS
          ok     = 1
          not_ok = 2
          OTHERS = 3.
      IF sy-subrc = 1.
* Implement suitable error handling here
        CALL TRANSACTION 'QA13' AND SKIP FIRST SCREEN.
        PERFORM new_okcode.
      ENDIF.

    WHEN 'PUSH_TPL'.
      SET PARAMETER ID 'IFL' FIELD viqmel-tplnr.

      CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
        EXPORTING
          tcode  = 'IL03'
        EXCEPTIONS
          ok     = 1
          not_ok = 2
          OTHERS = 3.
      IF sy-subrc = 1.
* Implement suitable error handling here
        CALL TRANSACTION 'IL03' AND SKIP FIRST SCREEN.
        PERFORM new_okcode.
      ENDIF.

    WHEN 'DISPLAY_SERVICE'.
      CLEAR: lv_aufnr.
      lv_aufnr = viqmel-yqm_service_doc_id.
      cl_eam_util_mcso_integration=>service_order_navigation(
        EXPORTING
          iv_aufnr       = lv_aufnr
        EXCEPTIONS
          frontend_error = 1                     " Front end error
          OTHERS         = 2 ).
      IF sy-subrc <> 0.
        MESSAGE e161(iw) WITH lv_aufnr.
      ELSE.
        PERFORM new_okcode.
      ENDIF.
    WHEN OTHERS.
  ENDCASE.

ENDMODULE.
