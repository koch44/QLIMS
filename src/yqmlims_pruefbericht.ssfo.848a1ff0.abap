  CLEAR gs_qamv.

*    Prüfmerkmalsvorgaben
  READ TABLE gt_qamv into gs_qamv
    WITH KEY prueflos  = is_qals-prueflos
             verwmerkm = gs_MATN_MK_T-merkmal.
  IF sy-subrc <> 0.
    CLEAR gs_qamv.
  ENDIF.











