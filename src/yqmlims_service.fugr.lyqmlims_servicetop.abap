FUNCTION-POOL yqmlims_service.              "MESSAGE-ID ..

TABLES: iflo.

TYPES: BEGIN OF gty_csla,
         lsttext TYPE c LENGTH 63,
       END OF gty_csla.

CONSTANTS gc_min  TYPE f VALUE '1.0E+100'.
CONSTANTS gc_max  TYPE f VALUE '-1.0E+100'.
CONSTANTS gc_half TYPE f VALUE '0.5'.

CONSTANTS:
*  gc_fcode_ok         LIKE sy-tcode           VALUE 'OK  ',
  gc_fcode_enter            LIKE sy-tcode           VALUE 'ENT1',
  gc_fcode_cancel           LIKE sy-tcode           VALUE 'CANC',
  gc_fcode_accept           LIKE sy-tcode           VALUE 'ACCEPT',
  gc_fcode_accept_kmv       LIKE sy-tcode           VALUE 'ACCEPT_KMV',
  gc_fcode_reject           LIKE sy-tcode           VALUE 'REJECT',

  gc_elem_evt_name          TYPE swc_elem     VALUE '_EVT_NAME',
  gc_elem_evt_creation_date TYPE swc_elem     VALUE '_EVT_CREATION_DATE',
  gc_elem_evt_creation_time TYPE swc_elem     VALUE '_EVT_CREATION_TIME',
  gc_elem_evt_creator       TYPE swc_elem     VALUE '_EVT_CREATORE',
  gc_elem_evt_objkey        TYPE swc_elem     VALUE '_EVT_OBJKEY',
  gc_event_created          TYPE swc_value    VALUE 'CREATED'.


DATA: gt_csla TYPE TABLE OF gty_csla.
DATA: gs_csla TYPE gty_csla.

* Daten für Auswahl Leistungsart aus Liste
*DATA: gv_cursorfield(40),                 "Name des Cursorfeldes
DATA: gv_field_value(40),                 "Inhalt des Cursorfeldes
      gv_sel_lstar TYPE csla-lstar.       "Selektierte Leistungsart

* Daten der Kostenrechnung
DATA: gv_kokrs TYPE tka02-kokrs,        "Kostenrechnungskreis
      gv_kostl TYPE csks-kostl,         "Kostenstelle
      gv_waers TYPE csks-waers.         "Waehrung

* Hilfsvariable
DATA: gv_ok_code(4).

DATA: gv_fcode            LIKE sy-tcode.
DATA: gs_mara             TYPE mara.
DATA: gv_approve          TYPE flag.
DATA: gv_accept           TYPE flag.
DATA: gv_accept_kmv       TYPE flag.
DATA: gv_reject           TYPE flag.

* html/pdf control
DATA: gv_pdf_html_control TYPE REF TO cl_gui_html_viewer,
      gv_pdf_my_container TYPE REF TO cl_gui_custom_container,
      gv_pdf_alignment    TYPE i,
      gv_pdf_data         TYPE xstring,
      gv_pdf_size         TYPE i.
