  CLEAR gs_qamv.

*    Prüfmerkmalsvorgaben
  READ TABLE gt_qamv INTO gs_qamv
    WITH KEY prueflos  = is_qals-prueflos
             verwmerkm = gs_MATN_MK_T-merkmal.
  IF sy-subrc <> 0.
    CLEAR gs_qamv.
  ENDIF.


  PERFORM get_sample_result
    TABLES   it_qamv
             it_qasr
             gt_qmtt
             gt_t006a
             gt_cert_attr
    USING    gs_qapp
             gs_qamv-verwmerkm
    CHANGING gv_messwert
             gv_grenzwert
             gv_verfahren
             gv_uom_text
             gv_rejected.
