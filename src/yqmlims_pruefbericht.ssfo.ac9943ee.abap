
IF gv_merknr_01 = '99999999'.
  CLEAR gs_qamv.
  CLEAR gs_t006a.
ELSE.
  READ TABLE it_qamv INTO gs_qamv
    WITH KEY verwmerkm = gv_merknr_01.
  IF sy-subrc <> 0.
    CLEAR gs_qamv.
  ENDIF.

  IF NOT gs_qamv-masseinhsw IS INITIAL.
    READ TABLE gt_t006a INTO gs_t006a
      WITH KEY spras    = sy-langu
               msehi    = gs_qamv-masseinhsw.
    IF sy-subrc <> 0.
      CLEAR gs_t006a.
    ENDIF.
  ELSE.
    CLEAR gs_t006a.
  ENDIF.
ENDIF.

IF NOT gs_qamv-pmethode IS INITIAL.
  READ TABLE gt_qmtt INTO gs_qmtt
    WITH KEY werks   = gs_qamv-qmtb_werks
             pmtnr   = gs_qamv-pmethode
             version = gs_qamv-pmtversion
             sprache = sy-langu.
  IF sy-subrc = 0.
    gs_qamv_qmtt-qamv_verwmerkm = gs_qamv-verwmerkm.
    gs_qamv_qmtt-qamv_pmethode  = gs_qamv-pmethode.
    gs_qamv_qmtt-qamv_kurztext  = gs_qamv-kurztext.
    MOVE-CORRESPONDING gs_qmtt TO gs_qamv_qmtt.
    READ TABLE gt_qamv_qmtt TRANSPORTING NO FIELDS
      WITH KEY qamv_verwmerkm = gs_qamv-verwmerkm
               qamv_pmethode  = gs_qamv-pmethode.
    IF sy-subrc <> 0.
      APPEND gs_qamv_qmtt TO gt_qamv_qmtt.
    ENDIF.
    gv_meth_tab = 'X'.
  ENDIF.
ENDIF.
