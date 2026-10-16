FUNCTION-POOL yqmlims_qfoa.  "MESSAGE-ID ..

CLASS lcl_application DEFINITION DEFERRED.
CLASS cl_gui_cfw      DEFINITION LOAD.

" --------------------------------------------------------------------
" Typen
" --------------------------------------------------------------------
TYPES: BEGIN OF gty_source,
         line TYPE tline-tdline,
       END OF gty_source.

TYPES: BEGIN OF gty_tq30,
         art   TYPE tq30-art,
         stsma TYPE tq30-stsma,
       END OF gty_tq30.

TYPES gty_source_table TYPE STANDARD TABLE OF gty_source WITH EMPTY KEY.

" --------------------------------------------------------------------
" OK-Code / Steuerung
" --------------------------------------------------------------------
DATA: gv_ok_code          TYPE sy-ucomm,
      gv_save_ok_code     TYPE sy-ucomm,
      gs_parameter_string TYPE string.

DATA: gv_mailversand TYPE qkz,
      gv_string      TYPE string,
      gv_display_log TYPE flag,
      gv_dummy       TYPE c.

DATA: gv_no_editor TYPE qkz,
      gv_aktyp     TYPE t365-aktyp,
      gv_subrc     TYPE sy-subrc.

" --------------------------------------------------------------------
" Applikationslog (BAL)
" --------------------------------------------------------------------
DATA: gs_msg               TYPE bal_s_msg,
      gs_log               TYPE bal_s_log,
      gs_log_handle        TYPE balloghndl,
      gt_log_handle        TYPE bal_t_logh,
      gs_s_display_profile TYPE bal_s_prof.

" --------------------------------------------------------------------
" OLE2 (Word)
" --------------------------------------------------------------------
DATA: gv_word     TYPE ole2_object,
      gv_options  TYPE ole2_object,
      gv_document TYPE ole2_object,
      gv_file     TYPE ole2_object,
      gv_field    TYPE ole2_object.

" --------------------------------------------------------------------
" QM / Datenhaltung global
" --------------------------------------------------------------------
DATA: gs_qals TYPE qals,
      gs_qapp TYPE qapp,
      gt_qapp TYPE STANDARD TABLE OF qapp WITH EMPTY KEY,
      gs_qamv TYPE qamv,
      gt_qamv TYPE STANDARD TABLE OF qamv WITH EMPTY KEY,
      gs_qasr TYPE qasr,
      gt_qasr TYPE STANDARD TABLE OF qasr WITH EMPTY KEY,
      gs_tq30 TYPE gty_tq30.

DATA: gs_matn_mk TYPE yqm_matn_mk_t,
      gt_matn_mk TYPE STANDARD TABLE OF yqm_matn_mk_t WITH EMPTY KEY.

DATA  gr_merkmal TYPE RANGE OF yqm_matn_mk_t-merkmal.

" --------------------------------------------------------------------
" Ergebnisanzeige / ALV / Text
" --------------------------------------------------------------------
DATA gs_headltx TYPE thead.

DATA: gs_results TYPE yqm_results_display,
      gt_results TYPE STANDARD TABLE OF yqm_results_display WITH EMPTY KEY.

DATA: gs_layout  TYPE lvc_s_layo,
      gs_variant TYPE disvariant.

DATA: gt_lines TYPE STANDARD TABLE OF tline WITH EMPTY KEY.

DATA: gs_ltxt TYPE tline,
      gt_ltxt TYPE tlinetab.

DATA: gt_selected_text      TYPE gty_source_table.

" --------------------------------------------------------------------
" Plausibilitätsgrenzen / Excludes
" --------------------------------------------------------------------
DATA: gs_tpln_exclude TYPE yqm_tpln_excl_t,
      gt_tpln_exclude TYPE STANDARD TABLE OF yqm_tpln_excl_t WITH EMPTY KEY.

DATA: gt_plty_limits_u TYPE STANDARD TABLE OF yqm_plty_limit_t WITH EMPTY KEY,
      gt_plty_limits_i TYPE STANDARD TABLE OF yqm_plty_limit_t WITH EMPTY KEY.

" --------------------------------------------------------------------
" Kostenübertragung / Costing
" --------------------------------------------------------------------
DATA: gs_cost_header TYPE yqm_cost_transfer_header.

DATA: gt_lst_arten TYPE STANDARD TABLE OF yqm_cost_transfer_lst_arten WITH EMPTY KEY,
      gs_lst_arten TYPE yqm_cost_transfer_lst_arten.

DATA: gs_kosten4 TYPE yqm_kosten4_t,
      gt_kosten4 TYPE STANDARD TABLE OF yqm_kosten4_t WITH EMPTY KEY.

DATA: gs_cssl TYPE cssl,
      gt_cssl TYPE STANDARD TABLE OF cssl WITH EMPTY KEY,
      gs_cost TYPE cost,
      gt_cost TYPE STANDARD TABLE OF cost WITH EMPTY KEY.

DATA: gs_btci_table TYPE bdcdata,
      gt_btci_table TYPE STANDARD TABLE OF bdcdata WITH EMPTY KEY.

" Customizing-Tabelle
DATA: gt_vnltilv TYPE STANDARD TABLE OF yqm_vnltilv_t WITH EMPTY KEY,
      gs_vnltilv TYPE yqm_vnltilv_t.

" Defaults (werden über Customizing überschrieben)
DATA: gv_kokrs TYPE tka01-kokrs VALUE '1100',
      gv_kostl TYPE csks-kostl  VALUE 'Q09510    '.

" --------------------------------------------------------------------
" GUI Controls / DragDrop
" --------------------------------------------------------------------
DATA: gv_application         TYPE REF TO lcl_application,
      gv_docking_container_1 TYPE REF TO cl_gui_docking_container,
      gv_docking_container_2 TYPE REF TO cl_gui_docking_container,
      gv_alv                 TYPE REF TO cl_gui_alv_grid,
      gv_edit                TYPE REF TO cl_gui_textedit,
      gv_behaviour_edit      TYPE REF TO cl_dragdrop,
      gv_behaviour_alv       TYPE REF TO cl_dragdrop,
      gv_repid               TYPE sy-repid.

DATA:
  gv_splitter         TYPE REF TO cl_gui_splitter_container,
  gv_container_top    TYPE REF TO cl_gui_container,
  gv_container_bottom TYPE REF TO cl_gui_container.

" --------------------------------------------------------------------
" Status / Konstanten
" --------------------------------------------------------------------
CONSTANTS:
  gc_kstu     TYPE c LENGTH 4 VALUE 'KSTÜ',     "Kosten übertragen
  gc_okst     TYPE c LENGTH 4 VALUE 'OKST',     "ohne Kosten
  gc_beur     TYPE c LENGTH 4 VALUE 'BEUR',     "Beurteilung erforderlich
  gc_pruefart TYPE c LENGTH 8 VALUE 'YQM_TP',
  gc_false    TYPE i VALUE 0,
  gc_true     TYPE i VALUE 1.

DATA: gv_stat_kstu TYPE jest-stat,
      gv_stat_okst TYPE jest-stat.

" OLE2 Include
INCLUDE ole2incl.
