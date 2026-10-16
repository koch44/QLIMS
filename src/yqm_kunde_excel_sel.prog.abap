"&---------------------------------------------------------------------"
"& Include          YQM_KUNDE_EXCEL_SEL
"&---------------------------------------------------------------------"

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.

  PARAMETERS p_kunnr TYPE qals-yqm_kunnrzl.

  SELECT-OPTIONS:
    so_tplnr FOR qals-yqm_tplnr,
    so_prlos FOR qals-prueflos,
    so_zeit  FOR qals-yqm_probedatum,
    so_vdat  FOR qave-vdatum.

  PARAMETERS:
    pa_tab1 RADIOBUTTON GROUP r1,
    pa_tab2 RADIOBUTTON GROUP r1,
    pa_tab3 RADIOBUTTON GROUP r1.

SELECTION-SCREEN END OF BLOCK b1.

AT SELECTION-SCREEN.
  IF so_zeit IS INITIAL.
    "MSG: Bitte Auswertungszeitraum angeben!
    MESSAGE e120(yqmlims).
  ENDIF.
