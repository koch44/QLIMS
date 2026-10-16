"&---------------------------------------------------------------------"
"& Include YQM_KUNDE_EXCEL_TOP   - Report YQM_KUNDE_EXCEL
"&---------------------------------------------------------------------"

"---------------------------------------------------------------------"
" Globale Deklarationen
"---------------------------------------------------------------------"

TABLES: qals, qave.

DATA: gt_sel          TYPE STANDARD TABLE OF yqm_sel_kunde_ex,
      gt_sel_filtered TYPE STANDARD TABLE OF yqm_sel_kunde_ex.

FIELD-SYMBOLS: <gs_sel> TYPE yqm_sel_kunde_ex.

"---------------------------------------------------------------------"
" Statuskonstanten
"---------------------------------------------------------------------"
CONSTANTS:
  gc_status_ve   TYPE j_status VALUE 'I0002',
  gc_status_sper TYPE j_status VALUE 'I0046',
  gc_status_gesp TYPE j_status VALUE 'E0001'.

"---------------------------------------------------------------------"
" Output-Struktur
"---------------------------------------------------------------------"
TYPES: BEGIN OF gty_exc,
         yqm_kunnrzl      TYPE qals-yqm_kunnrzl,
         pltxt            TYPE iflotx-pltxt,
         ktext            TYPE plko-ktext,
         ktextlos         TYPE qals-ktextlos,
         yqm_wasserwirtnr TYPE iflot-yqm_wasserwirtnr,
         prueflos         TYPE qals-prueflos,
         yqm_probedatum   TYPE qals-yqm_probedatum,
         kurztext         TYPE qamv-kurztext,
         char             TYPE qasr-attribut,
         mittelwert       TYPE string,
         code             TYPE string,
         masseinhsw       TYPE t006a-mseht,
         pmethode         TYPE string,
         merknr           TYPE qamv-verwmerkm,
         messid           TYPE iflot-yqm_messid,
         tolob            TYPE string,
         tolun            TYPE string,
         paramid          TYPE yqm_paramid,
         vedatum          TYPE qvedatum,
         vezeit           TYPE qvezeiterf,
         timestamp        TYPE timestamp,
       END OF gty_exc.

DATA: gt_exc TYPE STANDARD TABLE OF gty_exc,
      gs_exc TYPE gty_exc.


"---------------------------------------------------------------------"
" Customizing
"---------------------------------------------------------------------"
DATA: gt_param     TYPE STANDARD TABLE OF yqm_param_t,
      gt_cert_attr TYPE STANDARD TABLE OF yqm_cert_attr_t.

"---------------------------------------------------------------------"
" ALV
"---------------------------------------------------------------------"
DATA: go_alv     TYPE REF TO cl_gui_alv_grid,
      gs_variant TYPE disvariant,
      gs_layout  TYPE lvc_s_layo.

"---------------------------------------------------------------------"
" ALV-Strukturen
"---------------------------------------------------------------------"
TYPES gty_it  TYPE yqm_k_e.
TYPES gty_it2 TYPE yqm_k_e2.
TYPES gty_it3 TYPE yqm_k_e3.


DATA: gt_it  TYPE STANDARD TABLE OF gty_it  WITH EMPTY KEY,
      gt_it2 TYPE STANDARD TABLE OF gty_it2 WITH EMPTY KEY,
      gt_it3 TYPE STANDARD TABLE OF gty_it3 WITH EMPTY KEY.

DATA: gs_it  TYPE gty_it,
      gs_it2 TYPE gty_it2,
      gs_it3 TYPE gty_it3.
