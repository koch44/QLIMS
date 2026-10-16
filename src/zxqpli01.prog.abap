*----------------------------------------------------------------------*
***INCLUDE ZXQPLI01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  GET_PROBENEHMER  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_probenehmer INPUT.

  SELECT SINGLE lname FROM yqm_pruefer_t INTO gs_qals-yqm_probenehmer40
     WHERE kname = gs_qals-yqm_probenehmer03.
  IF sy-subrc <> 0.
    CLEAR gs_qals-yqm_probenehmer40.
  ENDIF.

ENDMODULE.                 " GET_PROBENEHMER  INPUT
*&---------------------------------------------------------------------*
MODULE get_probenahmeverfahren INPUT.

  SELECT SINGLE vnlpvkt FROM yqm_vnltpv_t INTO gs_qals-yqm_vnlpvkt
     WHERE vnlpv = gs_qals-yqm_vnlpv.
  IF sy-subrc <> 0.
    CLEAR gs_qals-yqm_vnlpvkt.
  ENDIF.
ENDMODULE.                 " get_probenahmeverfahren  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_DATUM  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_datum INPUT.

  IF gs_qals-yqm_probeeingang LT gs_qals-yqm_probedatum.
    MESSAGE e614(yqmlims).
*   Das eingegebene Probeneingangsdatum ist kleiner als das Probenahmedatum.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  GET_PRGGSTD  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_prggstd INPUT.

  SELECT SINGLE  prggstd bez FROM yqm_prggstd_t
         INTO yqm_prggstd_t
         WHERE prggstd = gs_qals-yqm_prggstd.
  IF sy-subrc <> 0.
    MESSAGE e620(yqmlims) WITH gs_qals-yqm_prggstd.
    CLEAR gs_qals-yqm_prggstd.
  ENDIF.


ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0109  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0109 INPUT.

  DATA: lv_aufnr      TYPE caufvd-aufnr.

  CASE sy-ucomm.

    WHEN 'DISPLAY_SERVICE'.
      CLEAR: lv_aufnr.
      lv_aufnr = gs_qals-yqm_service_doc_id.
      cl_eam_util_mcso_integration=>service_order_navigation(
        EXPORTING
          iv_aufnr       = lv_aufnr
        EXCEPTIONS
          frontend_error = 1                     " Front end error
          OTHERS         = 2 ).
      IF sy-subrc <> 0.
        MESSAGE e161(iw) WITH lv_aufnr.
      ENDIF.
  ENDCASE.

  CLEAR: sy-ucomm.

ENDMODULE.
