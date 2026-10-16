IF NOT gs_qprv_tplnr-lfdnr IS INITIAL.
  gv_lfdnr = gs_qprv_tplnr-lfdnr.
  SHIFT gv_lfdnr LEFT DELETING LEADING '0'.
ELSE.
  CLEAR gv_lfdnr.
ENDIF.






















