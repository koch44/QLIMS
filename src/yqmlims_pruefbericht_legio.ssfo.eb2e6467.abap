PERFORM get_sample_result
  TABLES   it_qamv
           it_qasr
           gt_qmtt
           gt_t006a
           gt_cert_attr
  USING    gs_qapp
           gv_merknr_03
  CHANGING gv_messwert
           gv_grenzwert
           gv_verfahren.
