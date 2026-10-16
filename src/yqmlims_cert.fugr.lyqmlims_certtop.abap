FUNCTION-POOL yqmlims_cert.                 "MESSAGE-ID ..

CONSTANTS:
  gc_on(1) TYPE c                   VALUE 'X',
  gc_off   TYPE c                   VALUE ' '.

DATA: gs_adrc    TYPE adrc,
      gs_iflo    TYPE iflo,
      gs_qals    TYPE qals,
      gs_qave    TYPE qave,
      gs_qapp    TYPE qapp,
*      gs_qapo    TYPE qapo,
*      gs_qamv    TYPE qamv,
*      gs_qasr    TYPE qasr,
      gs_qprs    TYPE qprs,
      gs_ihpa    TYPE ihpa,
      gs_matn_tx TYPE yqm_matn_tx_t,
      gt_qapp    TYPE TABLE OF qapp,
      gt_qapo    TYPE TABLE OF qapo,
      gt_qamv    TYPE TABLE OF qamv,
      gt_qasr    TYPE TABLE OF qasr,
      gt_qprs    TYPE TABLE OF qprs,
      gt_ihpa    TYPE TABLE OF ihpa.
