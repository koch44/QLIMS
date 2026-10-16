*&---------------------------------------------------------------------*
*& Report YQMLIMS_MAINTAIN_PRUEFER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Erstellt: Christian Fischer - CFCConsulting GmbH
*& Datum: 12/2023
*&---------------------------------------------------------------------*
*& Beschreibung: Report zur Pflege (Änderung) von Prüfern incl
*& der Dokumentation von Schulungen
*&---------------------------------------------------------------------*
*
*&---------------------------------------------------------------------*
*& Transaktion: ZQ03_PRUEFER
*&---------------------------------------------------------------------*
REPORT yqmlims_maintain_pruefer.

TABLES:
  yqm_pruefer_t,
  yqm_alv_pruefer,
  yqm_alv_prueferschulung.


TYPES: BEGIN OF gty_alv_pruefer.
         INCLUDE STRUCTURE yqm_alv_pruefer.
TYPES:   selected TYPE flag,
*         lights,
       END OF gty_alv_pruefer.

TYPES: BEGIN OF gty_alv_schulung.
         INCLUDE STRUCTURE yqm_alv_prueferschulung.
TYPES:   selected TYPE flag,
*         lights   type flag,
       END OF gty_alv_schulung.

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* Typen- und Datendefinition
* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DATA:
  gv_struc   TYPE fieldname        "Name der Ausgabestruktur
              VALUE 'YQM_ALV_PRUEFER',

  gv_int_tab TYPE slis_tabname     "int. Tabelle mit ALV-Daten
              VALUE 'GT_ALV_PRUEFER'.

* ----------------------------------------------------------------------
* Konstanten
* ----------------------------------------------------------------------
CONSTANTS:
  gc_struc_pruefer  TYPE fieldname        "Name der Ausgabestruktur
              VALUE 'YQM_ALV_PRUEFER',

  gc_struc_schulung TYPE fieldname        "Name der Ausgabestruktur
              VALUE 'YQM_ALV_PRUEFERSCHULUNG',

  gc_int_pruefer    TYPE slis_tabname     "int. Tabelle mit ALV-Daten
              VALUE 'GT_ALV_PRUEFER',

  gc_int_schulung   TYPE slis_tabname     "int. Tabelle mit ALV-Daten
              VALUE 'IT_ALV_SCHULUNG',

  gc_formstat       TYPE slis_formname    "Routine zum Status setzen "#EC NEEDED
              VALUE 'STATUS_SET',                           "#EC NEEDED

  gc_formname       TYPE slis_formname    "Form für ext. User Kommandos
              VALUE 'HANDLE_EXTERNAL_USER_COMMAND'.

* ----------------------------------------------------------------------
* Felder und interne Tabellen
* ----------------------------------------------------------------------
DATA: gs_schulung     TYPE yqm_schulung_t.
DATA: gt_schulung     TYPE STANDARD TABLE OF yqm_schulung_t.
DATA: gs_alv_pruefer  TYPE gty_alv_pruefer.
DATA: gt_alv_pruefer  TYPE TABLE OF gty_alv_pruefer.
DATA: gs_alv_schulung TYPE gty_alv_schulung.
DATA: gt_alv_schulung TYPE TABLE OF gty_alv_schulung.

DATA:
  gv_ok_code         TYPE sy-ucomm,
  gv_aktyp           TYPE aktyp,
  gv_alv_liste       TYPE char10,
  gs_pruefer         TYPE yqm_pruefer_t,
  gs_prueferschulung TYPE yqm_pruefers_t,
  gt_prueferschulung TYPE TABLE OF yqm_pruefers_t,
  gt_fieldcat        TYPE slis_t_fieldcat_alv,   "Feldkatalog
  gv_repid           TYPE syst-repid,            "Hilfsfeld
  gv_exit_alv        TYPE char1,
  gv_grid_title      TYPE lvc_title,
  gs_alv_variant_p   TYPE disvariant,                  "ALV-Layout-Variante
  gs_alv_variant_s   TYPE disvariant,                  "ALV-Layout-Variante
  gs_alv_layout      TYPE slis_layout_alv,
  gs_alv_layout_p    TYPE slis_layout_alv.

SELECTION-SCREEN FUNCTION KEY 1.
*-----------------------------------------------------------------------

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* Eingaben
* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SELECTION-SCREEN BEGIN OF BLOCK pruefer WITH FRAME TITLE TEXT-s01.
  SELECT-OPTIONS:
    so_kname  FOR yqm_pruefer_t-kname,
    so_fname  FOR yqm_pruefer_t-yvxfan,
    so_pn_v   FOR yqm_pruefer_t-pn_vertrag,
    so_aktiv  FOR yqm_pruefer_t-aktiv,
    so_list   FOR yqm_alv_pruefer-in_listung_flag.
SELECTION-SCREEN END OF BLOCK pruefer.

SELECTION-SCREEN BEGIN OF BLOCK datum WITH FRAME TITLE TEXT-s02.
  SELECT-OPTIONS:
    so_dv_b   FOR yqm_alv_pruefer-dvgw_basic,
    so_dv_r   FOR yqm_alv_pruefer-dvgw_re,
    so_aud_e  FOR yqm_alv_pruefer-aud_ext,
    so_aud_i  FOR yqm_alv_pruefer-aud_int,
    so_in     FOR yqm_pruefer_t-in_listung,
    so_aus    FOR yqm_pruefer_t-aus_listung.
SELECTION-SCREEN END OF BLOCK datum.

SELECTION-SCREEN BEGIN OF BLOCK pnd WITH FRAME TITLE TEXT-s03.
  SELECT-OPTIONS:
    so_pnd_b   FOR yqm_alv_pruefer-pn_bueb_datum,
    so_pnd_s   FOR yqm_alv_pruefer-pn_senso_datum,
    so_pnd_c   FOR yqm_alv_pruefer-pn_chemie_datum,
    so_pnd_m   FOR yqm_alv_pruefer-pn_mikro_datum,
    so_pnd_l   FOR yqm_alv_pruefer-pn_legio_datum.
SELECTION-SCREEN END OF BLOCK pnd.

SELECTION-SCREEN BEGIN OF BLOCK pnb WITH FRAME TITLE TEXT-s04.
  SELECT-OPTIONS:
    so_pn_b   FOR yqm_alv_pruefer-pn_bueb,
    so_pn_s   FOR yqm_alv_pruefer-pn_senso,
    so_pn_c   FOR yqm_alv_pruefer-pn_chemie,
    so_pn_m   FOR yqm_alv_pruefer-pn_mikro,
    so_pn_l   FOR yqm_alv_pruefer-pn_legio.
SELECTION-SCREEN END OF BLOCK pnb.

SELECTION-SCREEN BEGIN OF BLOCK liste WITH FRAME TITLE TEXT-p00.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_pruef RADIOBUTTON GROUP list.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p01 FOR FIELD p_pruef.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_schul RADIOBUTTON GROUP list.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p02 FOR FIELD p_schul.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK liste.

SELECTION-SCREEN BEGIN OF BLOCK ausgabe WITH FRAME TITLE TEXT-s05.
  PARAMETERS:
    pa_var_p TYPE disvariant-variant,
    pa_var_s TYPE disvariant-variant.
SELECTION-SCREEN END OF BLOCK ausgabe.

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* SELECTION-SCREEN OUTPUT.
* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
AT SELECTION-SCREEN OUTPUT.            " Vorbelegung Selektionsscreen vor Anzeige


* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* Initialisierung
* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
INITIALIZATION.

* Standardlayout suchen

  IF pa_var_p IS INITIAL.
    CLEAR gs_alv_variant_p.
    gs_alv_variant_p-report = sy-repid.
    gs_alv_variant_p-handle = 'P'.
    CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
      EXPORTING
        i_save        = 'A'
      CHANGING
        cs_variant    = gs_alv_variant_p
      EXCEPTIONS
        wrong_input   = 1
        not_found     = 2
        program_error = 3
        OTHERS        = 4.
    IF sy-subrc = 0.
      pa_var_p = gs_alv_variant_p-variant.
    ENDIF.
  ENDIF.

  IF pa_var_s IS INITIAL.
    CLEAR gs_alv_variant_s.
    gs_alv_variant_s-report = sy-repid.
    gs_alv_variant_s-handle = 'S'.
    CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
      EXPORTING
        i_save        = 'A'
      CHANGING
        cs_variant    = gs_alv_variant_s
      EXCEPTIONS
        wrong_input   = 1
        not_found     = 2
        program_error = 3
        OTHERS        = 4.
    IF sy-subrc = 0.
      pa_var_s = gs_alv_variant_s-variant.
    ENDIF.
  ENDIF.
*  MOVE TEXT-001 TO sscrfields-functxt_01.


* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*   Event AT SELECTION-SCREEN ON
* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* ausgewähltes Layout prüfen
AT SELECTION-SCREEN ON pa_var_p.
  IF pa_var_p <> gs_alv_variant_p-variant.
    CLEAR gs_alv_variant_p.
    gs_alv_variant_p-report = sy-repid.
    gs_alv_variant_p-handle = 'P'.
  ENDIF.
  CHECK NOT pa_var_p IS INITIAL.

  gs_alv_variant_p-variant = pa_var_p.
  CALL FUNCTION 'REUSE_ALV_VARIANT_EXISTENCE'
    EXPORTING
      i_save     = 'A'
    CHANGING
      cs_variant = gs_alv_variant_p
    EXCEPTIONS
      OTHERS     = 1.
  IF sy-subrc <> 0.
    MESSAGE e321(m7) WITH pa_var_p gs_alv_variant_p-report.
  ENDIF.

AT SELECTION-SCREEN ON pa_var_s.
  IF pa_var_s <> gs_alv_variant_s-variant.
    CLEAR gs_alv_variant_s.
    gs_alv_variant_s-report = sy-repid.
    gs_alv_variant_s-handle = 'S'.
  ENDIF.
  CHECK NOT pa_var_p IS INITIAL.

  gs_alv_variant_s-variant = pa_var_s.
  CALL FUNCTION 'REUSE_ALV_VARIANT_EXISTENCE'
    EXPORTING
      i_save     = 'A'
    CHANGING
      cs_variant = gs_alv_variant_s
    EXCEPTIONS
      OTHERS     = 1.
  IF sy-subrc <> 0.
    MESSAGE e321(m7) WITH pa_var_s gs_alv_variant_s-report.
  ENDIF.

* Hilfe für Layout

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_var_p.
  CLEAR gs_alv_variant_p.
  gs_alv_variant_p-report  = sy-repid.
  gs_alv_variant_p-handle  = 'P'.
  gs_alv_variant_p-variant = pa_var_p.
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      is_variant         = gs_alv_variant_p
      i_save             = 'A'
      i_display_via_grid = 'X'                              "#EC NOTEXT
    IMPORTING
      es_variant         = gs_alv_variant_p
    EXCEPTIONS
      not_found          = 1
      program_error      = 2
      OTHERS             = 3.

  IF sy-subrc = 0.
    pa_var_p = gs_alv_variant_p-variant.
  ELSE.
    SET CURSOR FIELD 'PA_VAR_P'.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_var_s.
  CLEAR gs_alv_variant_s.
  gs_alv_variant_s-report  = sy-repid.
  gs_alv_variant_s-handle  = 'S'.
  gs_alv_variant_s-variant = pa_var_s.
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      is_variant         = gs_alv_variant_s
      i_save             = 'A'
      i_display_via_grid = 'X'                              "#EC NOTEXT
    IMPORTING
      es_variant         = gs_alv_variant_s
    EXCEPTIONS
      not_found          = 1
      program_error      = 2
      OTHERS             = 3.

  IF sy-subrc = 0.
    pa_var_s = gs_alv_variant_s-variant.
  ELSE.
    SET CURSOR FIELD 'PA_VAR_S'.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* Verarbeitung
* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
START-OF-SELECTION.
* Initialisierung ------------------------------------------------------

  IF     p_pruef = 'X'.
    gv_alv_liste = 'PRUEFER'.
    gv_struc   = gc_struc_pruefer.
    gv_int_tab = gc_int_pruefer.
  ELSEIF p_schul = 'X'.
    gv_alv_liste = 'SCHULUNG'.
    gv_struc   = gc_struc_schulung.
    gv_int_tab = gc_int_schulung.
  ELSE.
    gv_alv_liste = 'PRUEFER'.
    gv_struc   = gc_struc_pruefer.
    gv_int_tab = gc_int_pruefer.
  ENDIF.

  DO.
* Verarbeitung ---------------------------------------------------------
    PERFORM alv_daten_laden.

    PERFORM alv_feldkatalog_laden.

    PERFORM alv_daten_ausgeben.

    IF gv_exit_alv IS INITIAL.
      EXIT.
    ENDIF.
  ENDDO.
*&---------------------------------------------------------------------*
*&      Form  ALV_DATEN_AUSGEBEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_daten_ausgeben .

  DATA: lt_event_exit   TYPE slis_t_event_exit.
  DATA: ls_event_exit   TYPE slis_event_exit.
**--- pf2 used by salv and also by application (double-click) --------*
  CLEAR: ls_event_exit, lt_event_exit.
  ls_event_exit-ucomm = '&IC1'.
  ls_event_exit-after = 'X'.
  APPEND ls_event_exit TO lt_event_exit.

  CASE gv_alv_liste.
    WHEN 'PRUEFER'.
* ALV-Grid ausgeben
      gs_alv_layout = gs_alv_layout_p.
      gs_alv_layout-box_fieldname     = 'SELECTED'.  "field for checkbox
      gs_alv_layout-colwidth_optimize = 'X'.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          i_callback_program       = gv_repid
          i_callback_pf_status_set = gc_formstat
          i_callback_user_command  = gc_formname
          i_grid_title             = gv_grid_title
          is_layout                = gs_alv_layout
          it_fieldcat              = gt_fieldcat[]
          i_save                   = 'A'
          is_variant               = gs_alv_variant_p
*    IT_EVENTS
          it_event_exit            = lt_event_exit
        IMPORTING
          e_exit_caused_by_caller  = gv_exit_alv
        TABLES
          t_outtab                 = gt_alv_pruefer
        EXCEPTIONS
          program_error            = 1
          OTHERS                   = 2.
      IF sy-subrc <> 0.
* Implement suitable error handling here
        MESSAGE e829(yqmlims).
      ENDIF.
    WHEN 'SCHULUNG'.
* ALV-Grid ausgeben
      gs_alv_layout = gs_alv_layout_p.
      gs_alv_layout-box_fieldname     = 'SELECTED'.  "field for checkbox
      gs_alv_layout-colwidth_optimize = 'X'.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          i_callback_program       = gv_repid
          i_callback_pf_status_set = gc_formstat
          i_callback_user_command  = gc_formname
          i_grid_title             = gv_grid_title
          is_layout                = gs_alv_layout
          it_fieldcat              = gt_fieldcat[]
          i_save                   = 'A'
          is_variant               = gs_alv_variant_s
*    IT_EVENTS
          it_event_exit            = lt_event_exit
        IMPORTING
          e_exit_caused_by_caller  = gv_exit_alv
        TABLES
          t_outtab                 = gt_alv_schulung
        EXCEPTIONS
          program_error            = 1
          OTHERS                   = 2.
      IF sy-subrc <> 0.
* Implement suitable error handling here
        MESSAGE e829(yqmlims).
      ENDIF.

  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_DATEN_LADEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_daten_laden .

  DATA: lv_field_name   TYPE char32.
  DATA: lt_alv_schulung TYPE TABLE OF gty_alv_schulung.

  FIELD-SYMBOLS <lv_date>    TYPE dats.
  FIELD-SYMBOLS <lv_pn_flag> TYPE any.

  SELECT * FROM yqm_pruefer_t
    INTO TABLE gt_alv_pruefer
*    INTO CORRESPONDING FIELDS OF TABLE gt_alv_pruefer
    WHERE kname          IN so_kname
    AND   yvxfan         IN so_fname
    AND   pn_vertrag     IN so_pn_v
    AND   in_listung     IN so_in
    AND   aus_listung    IN so_aus
    AND   aktiv          IN so_aktiv.
  IF sy-subrc <> 0.
    CLEAR gt_alv_pruefer.
  ENDIF.

  IF NOT gt_alv_pruefer[] IS INITIAL.
    SELECT * FROM yqm_pruefers_t
      INTO TABLE gt_alv_schulung
*      INTO CORRESPONDING FIELDS OF TABLE gt_alv_schulung
      FOR ALL ENTRIES IN gt_alv_pruefer
      WHERE kname EQ gt_alv_pruefer-kname.
    IF sy-subrc <> 0.
      CLEAR gt_alv_schulung.
    ENDIF.
  ENDIF.

  SELECT * FROM yqm_schulung_t
    INTO CORRESPONDING FIELDS OF TABLE gt_schulung.
  IF sy-subrc <> 0.
    CLEAR gt_schulung.
  ENDIF.

  SORT gt_alv_pruefer  BY kname.
  SORT gt_alv_schulung BY kname lfdnr.

  lt_alv_schulung[] = gt_alv_schulung[].
  DELETE lt_alv_schulung WHERE loekz = 'X'.
  DELETE ADJACENT DUPLICATES FROM lt_alv_schulung COMPARING kname schulung.

  LOOP AT gt_alv_pruefer INTO gs_alv_pruefer.

    IF    gs_alv_pruefer-in_listung   LE sy-datlo
    AND ( gs_alv_pruefer-aus_listung  IS INITIAL
      OR  gs_alv_pruefer-aus_listung  GE sy-datlo ).
      gs_alv_pruefer-in_listung_flag = 'X'.
    ELSE.
      CLEAR gs_alv_pruefer-in_listung_flag.
    ENDIF.

    LOOP AT lt_alv_schulung
      INTO gs_alv_schulung
      WHERE kname = gs_alv_pruefer-kname
      AND   loekz EQ space.

      CASE gs_alv_schulung-schulung.
        WHEN 'AUD_EXT'
          OR 'AUD_INT'
          OR 'DVGW_BASIC'
          OR 'DVGW_RE'.
          CONCATENATE 'GS_ALV_PRUEFER-' gs_alv_schulung-schulung INTO lv_field_name.
          ASSIGN (lv_field_name) TO <lv_date>.
          IF sy-subrc = 0.
            <lv_date> = gs_alv_schulung-zeitpunkt.
          ENDIF.
          MODIFY gt_alv_pruefer FROM gs_alv_pruefer.
        WHEN 'PN_BUEB'
          OR 'PN_SENSO'
          OR 'PN_CHEMIE'
          OR 'PN_MIKRO'
          OR 'PN_LEGIO'.
          IF NOT gs_alv_schulung-valid_to IS INITIAL
          AND    gs_alv_schulung-valid_to GE sy-datlo.
            CONCATENATE 'GS_ALV_PRUEFER-' gs_alv_schulung-schulung '_DATUM' INTO lv_field_name.
            ASSIGN (lv_field_name)  TO <lv_date>.
            IF sy-subrc = 0.
              <lv_date> = gs_alv_schulung-zeitpunkt.
            ENDIF.
            CONCATENATE 'GS_ALV_PRUEFER-' gs_alv_schulung-schulung INTO lv_field_name.
            ASSIGN (lv_field_name) TO <lv_pn_flag>.
            IF sy-subrc = 0.
              <lv_pn_flag> = 'X'.
            ENDIF.
          ENDIF.
        WHEN OTHERS.
      ENDCASE.
    ENDLOOP.
    MODIFY gt_alv_pruefer FROM gs_alv_pruefer.
  ENDLOOP.

  LOOP AT gt_alv_pruefer INTO gs_alv_pruefer.
    IF NOT gs_alv_pruefer-in_listung_flag IN so_list
    OR NOT gs_alv_pruefer-aud_ext         IN so_aud_e
    OR NOT gs_alv_pruefer-aud_int         IN so_aud_i
    OR NOT gs_alv_pruefer-dvgw_basic      IN so_dv_b
    OR NOT gs_alv_pruefer-dvgw_re         IN so_dv_r
    OR NOT gs_alv_pruefer-pn_bueb_datum   IN so_pnd_b
    OR NOT gs_alv_pruefer-pn_senso_datum  IN so_pnd_s
    OR NOT gs_alv_pruefer-pn_chemie_datum IN so_pnd_c
    OR NOT gs_alv_pruefer-pn_mikro_datum  IN so_pnd_m
    OR NOT gs_alv_pruefer-pn_legio_datum  IN so_pnd_l
    OR NOT gs_alv_pruefer-pn_bueb         IN so_pn_b
    OR NOT gs_alv_pruefer-pn_senso        IN so_pn_s
    OR NOT gs_alv_pruefer-pn_chemie       IN so_pn_c
    OR NOT gs_alv_pruefer-pn_mikro        IN so_pn_m
    OR NOT gs_alv_pruefer-pn_legio        IN so_pn_l.
      DELETE TABLE gt_alv_pruefer FROM gs_alv_pruefer.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_FELDKATALOG_LADEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_feldkatalog_laden .

  DATA:
    ls_fieldcat TYPE slis_fieldcat_alv.

* Es darf nicht SY-REPID übergeben werden, da dieses überschrieben wird
  gv_repid = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = gv_repid
      i_internal_tabname     = gv_int_tab
      i_structure_name       = gv_struc
      i_client_never_display = 'X'
      i_inclname             = space
      i_bypassing_buffer     = space
      i_buffer_active        = space
    CHANGING
      ct_fieldcat            = gt_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
    CLEAR gt_fieldcat.
  ENDIF.

* Spalten ausblenden
  DELETE gt_fieldcat WHERE fieldname = 'SELECTED'.

  LOOP AT gt_fieldcat INTO ls_fieldcat.
    CASE ls_fieldcat-fieldname .
      WHEN 'AKTIV'.
        ls_fieldcat-checkbox = 'X'.
      WHEN 'LOEKZ'.
        ls_fieldcat-checkbox = 'X'.
      WHEN 'PN_BUEB'.
        ls_fieldcat-checkbox = 'X'.
      WHEN 'PN_SENSO'.
        ls_fieldcat-checkbox = 'X'.
      WHEN 'PN_CHEMIE'.
        ls_fieldcat-checkbox = 'X'.
      WHEN 'PN_MIKRO'.
        ls_fieldcat-checkbox = 'X'.
      WHEN 'PN_LEGIO'.
        ls_fieldcat-checkbox = 'X'.
    ENDCASE.
    MODIFY gt_fieldcat FROM ls_fieldcat.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  handle_external_user_command
*&---------------------------------------------------------------------*
*       hier wird der funktionscode beim doppelklick
*       auf die listzeile abgefragt.
*----------------------------------------------------------------------*
*  -->  iv_ucomm        funktionscode
*  <--  iv_selfield    tabellen-infos
*----------------------------------------------------------------------*
FORM handle_external_user_command USING iv_ucomm    TYPE sy-ucomm
                                        iv_selfield TYPE slis_selfield. "#EC CALLED

  DATA: ls_param TYPE rsparams.
  DATA: lt_param TYPE TABLE OF rsparams.
  DATA: lv_ref_grid TYPE REF TO cl_gui_alv_grid.
  IF lv_ref_grid IS INITIAL.
    CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
      IMPORTING
        e_grid = lv_ref_grid.
  ENDIF.
  IF NOT lv_ref_grid IS INITIAL.
    CALL METHOD lv_ref_grid->check_changed_data.
  ENDIF.

  CASE iv_ucomm.

    WHEN '&IC1'.
      READ TABLE gt_alv_pruefer INTO gs_alv_pruefer INDEX iv_selfield-tabindex.
      IF sy-subrc <> 0.
        CLEAR gs_alv_pruefer.
      ENDIF.

    WHEN 'CRE_PR'. "Prüfer anlegen
      gv_aktyp = 'A'.
      CLEAR yqm_alv_pruefer.
      yqm_alv_pruefer-aktiv = 'X'.
      CALL SCREEN 0200 STARTING AT 5 5.
      iv_selfield-exit = 'X'.

    WHEN 'MOD_PR'. "Prüfer ändern
      gv_aktyp = 'V'.
      LOOP AT gt_alv_pruefer INTO gs_alv_pruefer WHERE selected = 'X'.
        MOVE-CORRESPONDING gs_alv_pruefer TO yqm_alv_pruefer.
        CALL SCREEN 0200 STARTING AT 5 5.
      ENDLOOP.
      iv_selfield-exit = 'X'.

    WHEN 'CRE_SCH'. "Prüferschulung anlegen
      gv_aktyp = 'A'.
      LOOP AT gt_alv_pruefer INTO gs_alv_pruefer WHERE selected = 'X'.
        CLEAR yqm_alv_prueferschulung.
        yqm_alv_prueferschulung-kname = gs_alv_pruefer-kname.
        LOOP AT gt_alv_schulung
          INTO gs_alv_schulung
          WHERE kname = gs_alv_pruefer-kname.
        ENDLOOP.
        yqm_alv_prueferschulung-lfdnr = gs_alv_schulung-lfdnr + 1.
        CALL SCREEN 0300 STARTING AT 5 5.
      ENDLOOP.
      iv_selfield-exit = 'X'.

    WHEN 'OVW_SCH'. "Übersicht Schulung
      gv_aktyp = 'V'.
      CLEAR lt_param.
      LOOP AT gt_alv_pruefer INTO gs_alv_pruefer WHERE selected = 'X'.
*        MOVE-CORRESPONDING gs_alv_pruefer TO yqm_alv_pruefer.
        ls_param-selname = 'SO_KNAME'.
        ls_param-kind    = 'S'.
        ls_param-sign    = 'I'.
        ls_param-option  = 'EQ'.
        ls_param-low     = gs_alv_pruefer-kname.
        APPEND ls_param TO lt_param.
      ENDLOOP.

      IF NOT lt_param IS INITIAL.
        ls_param-selname = 'P_SCHUL'.
        ls_param-kind    = 'P'.
        ls_param-sign    = 'I'.
        ls_param-option  = 'EQ'.
        ls_param-low     = 'X'.
        APPEND ls_param TO lt_param.

        SUBMIT yqmlims_maintain_pruefer
              WITH SELECTION-TABLE lt_param
              AND RETURN.

        iv_selfield-exit = 'X'.
      ENDIF.

    WHEN 'MOD_SCH'. "Prüferschulung ändern
      gv_aktyp = 'V'.
      LOOP AT gt_alv_schulung
          INTO gs_alv_schulung WHERE selected = 'X'.
        MOVE-CORRESPONDING gs_alv_schulung TO yqm_alv_prueferschulung.
        CALL SCREEN 0300 STARTING AT 5 5.
      ENDLOOP.
      iv_selfield-exit = 'X'.

    WHEN 'DEL_SCH'. "Prüferschulung löschen
      CLEAR gt_prueferschulung.
      LOOP AT gt_alv_schulung
          INTO gs_alv_schulung WHERE selected = 'X'.
        MOVE-CORRESPONDING gs_alv_schulung TO gs_prueferschulung.
        gs_prueferschulung-loekz     = 'X'.
        gs_prueferschulung-aenderer  = sy-uname.
        gs_prueferschulung-aenderdat = sy-datlo.
        APPEND gs_prueferschulung TO gt_prueferschulung.
      ENDLOOP.

      IF NOT gt_prueferschulung[] IS INITIAL.
        MODIFY yqm_pruefers_t FROM TABLE gt_prueferschulung.
        IF sy-subrc = 0.
          COMMIT WORK AND WAIT.
          iv_selfield-exit = 'X'.
        ELSE.
          MESSAGE s028(yqmlims) WITH 'YQM_PRUEFERS_T'.
        ENDIF.
      ENDIF.
  ENDCASE.

ENDFORM.                                          "user_command
*&---------------------------------------------------------------------*
*&      Form  status_set
*&---------------------------------------------------------------------*
FORM status_set USING et_extab TYPE slis_t_extab.           "#EC CALLED

  CASE gv_alv_liste.
    WHEN 'PRUEFER'.
      APPEND 'MOD_SCH' TO et_extab.
      APPEND 'DEL_SCH' TO et_extab.
    WHEN 'SCHULUNG'.
      APPEND 'CRE_PR'  TO et_extab.
      APPEND 'MOD_PR'  TO et_extab.
      APPEND 'OVW_SCH' TO et_extab.
      APPEND 'CRE_SCH' TO et_extab.
  ENDCASE.

  SET PF-STATUS 'STANDARD_FULLSCREEN' EXCLUDING et_extab. "#EC * Button

ENDFORM.                    "status_set
*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS '0200'.
  SET TITLEBAR '200'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_0200 INPUT.

  LEAVE TO SCREEN 0.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  CASE gv_ok_code.
    WHEN 'ABBR'.
      LEAVE TO SCREEN 0.
    WHEN 'ENTR'.
      IF gv_aktyp = 'A'.
        SELECT COUNT( * ) FROM yqm_pruefer_t
          WHERE kname = yqm_alv_pruefer-kname.
        IF sy-subrc = 0.
          MESSAGE e828(yqmlims) WITH yqm_alv_pruefer-kname.
          EXIT.
        ENDIF.
      ENDIF.
    WHEN 'SAVE'.
      IF gv_aktyp = 'A'.
        SELECT COUNT( * ) FROM yqm_pruefer_t
          WHERE kname = yqm_alv_pruefer-kname.
        IF sy-subrc = 0.
          MESSAGE e828(yqmlims) WITH yqm_alv_pruefer-kname.
          EXIT.
        ENDIF.
        MOVE-CORRESPONDING yqm_alv_pruefer TO gs_pruefer.
        gs_pruefer-aktiv      = 'X'.
        gs_pruefer-ersteller  = sy-uname.
        gs_pruefer-erstelldat = sy-datlo.
      ELSE.
        MOVE-CORRESPONDING yqm_alv_pruefer TO gs_pruefer.
        gs_pruefer-aenderer  = sy-uname.
        gs_pruefer-aenderdat = sy-datlo.
      ENDIF.

      MODIFY yqm_pruefer_t FROM gs_pruefer.
      IF sy-subrc = 0.
        COMMIT WORK AND WAIT.
        LEAVE TO SCREEN 0.
      ENDIF.

  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  LOOP_AT_SCREEN_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE loop_at_screen_0200 OUTPUT.
  CASE gv_aktyp.
    WHEN 'A'. "Anlegen

    WHEN 'V'. "Ändern

      LOOP AT SCREEN.
        IF screen-name = 'YQM_ALV_PRUEFER-KNAME'.
          screen-input = '0'.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_0300 INPUT.

  LEAVE TO SCREEN 0.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  LOOP_AT_SCREEN_0300  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE loop_at_screen_0300 OUTPUT.
  CASE gv_aktyp.
    WHEN 'A'. "Anlegen

    WHEN 'V'. "Ändern
      LOOP AT SCREEN.
        IF screen-name = 'YQM_ALV_PRUEFERSCHULUNG-KNAME'
        OR screen-name = 'YQM_ALV_PRUEFERSCHULUNG-LFDNR'.
          screen-input = '0'.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.

  DATA: gv_month TYPE i.

  CASE gv_ok_code.
    WHEN 'ABBR'.
      LEAVE TO SCREEN 0.
    WHEN 'ENTR'.
      IF gv_aktyp = 'A'.
        IF NOT yqm_alv_prueferschulung-zeitpunkt IS INITIAL
          AND  yqm_alv_prueferschulung-valid_to  IS INITIAL.
          READ TABLE gt_schulung
            INTO gs_schulung
            WITH KEY schulung = yqm_alv_prueferschulung-schulung.
          IF sy-subrc = 0.
            gv_month = gs_schulung-validity.
            CALL FUNCTION 'OIL_DATE_ADD_MONTH'
              EXPORTING
                months  = gv_month
                olddate = yqm_alv_prueferschulung-zeitpunkt
              IMPORTING
                newdate = yqm_alv_prueferschulung-valid_to.
          ENDIF.
        ENDIF.
      ENDIF.
    WHEN 'SAVE'.
      IF gv_aktyp = 'A'.
        MOVE-CORRESPONDING yqm_alv_prueferschulung TO gs_prueferschulung.
        gs_prueferschulung-ersteller   = sy-uname.
        gs_prueferschulung-erstelldat  = sy-datlo.
      ELSE.
        MOVE-CORRESPONDING yqm_alv_prueferschulung TO gs_prueferschulung.
        gs_prueferschulung-aenderer  = sy-uname.
        gs_prueferschulung-aenderdat = sy-datlo.
      ENDIF.

      MODIFY yqm_pruefers_t FROM gs_prueferschulung.
      IF sy-subrc = 0.
        COMMIT WORK AND WAIT.
        LEAVE TO SCREEN 0.
      ELSE.
        MESSAGE s028(yqmlims) WITH 'YQM_PRUEFERS_T'.
      ENDIF.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  SET PF-STATUS '0300'.
  SET TITLEBAR '300'.
ENDMODULE.
