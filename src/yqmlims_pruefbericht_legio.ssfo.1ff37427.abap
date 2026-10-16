
IF gv_merknr_01 = '99999999'.
  CLEAR gs_qasr.
  CLEAR gs_t006a.
  CLEAR gv_messwert.
ELSE.

  PERFORM get_sample_result
    TABLES   it_qamv
             it_qasr
             gt_qmtt
             gt_t006a
             gt_cert_attr
    USING    gs_qapp
             gv_merknr_01
    CHANGING gv_messwert
             gv_grenzwert
             gv_verfahren.

ENDIF.
