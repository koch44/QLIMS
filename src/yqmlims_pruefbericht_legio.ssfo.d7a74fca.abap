
READ TABLE it_qprs INTO gs_qprs
  WITH KEY phynr = gs_qapp-phynr.
IF sy-subrc <> 0.
  CLEAR gs_qprs.
ENDIF.




















