"&---------------------------------------------------------------------"
"& Report YQM_KUNDE_EXCEL
"&---------------------------------------------------------------------"
"&
"&---------------------------------------------------------------------"

REPORT yqm_kunde_excel.

"&---------------------------------------------------------------------"

INCLUDE yqm_kunde_excel_top.
INCLUDE yqm_kunde_excel_sel.
INCLUDE yqm_kunde_excel_forms.
INCLUDE yqm_kunde_excel_alv.

"&---------------------------------------------------------------------"

START-OF-SELECTION.
  PERFORM main.

END-OF-SELECTION.
  PERFORM output_summary.
