"&---------------------------------------------------------------------"
"& Include          YQM_KUNDE_EXCEL_FORMS
"&---------------------------------------------------------------------"

"---------------------------------------------------------------------"
" Hauptprogramm
"---------------------------------------------------------------------"
FORM main.

  PERFORM select_data.
  PERFORM filter_status.
  PERFORM load_customizing.
  PERFORM process_data.
  PERFORM display_alv.

ENDFORM.

"---------------------------------------------------------------------"
" Datenselektion
"---------------------------------------------------------------------"
FORM select_data.

  SELECT *
    FROM yqm_sel_kunde_ex
    WHERE prueflos        IN @so_prlos
      AND yqm_tplnr       IN @so_tplnr
      AND yqm_probedatum  IN @so_zeit
      AND vdatum          IN @so_vdat
      AND stat35         = 'X'
      AND ( kunnr = @p_kunnr OR @p_kunnr IS INITIAL )
    INTO TABLE @gt_sel.

  IF sy-subrc <> 0.
    MESSAGE 'Keine Daten gefunden' TYPE 'I'.
  ENDIF.

ENDFORM.

"---------------------------------------------------------------------"
" Statuslogik
"---------------------------------------------------------------------"
FORM filter_status.

  DATA: lt_stat   TYPE STANDARD TABLE OF bapi2045ss,
        lv_gesp   TYPE abap_bool,
        lv_sper   TYPE abap_bool,
        lv_ve     TYPE abap_bool,
        ls_return TYPE bapireturn1.

  LOOP AT gt_sel ASSIGNING <gs_sel>.

    CLEAR: lt_stat, lv_gesp, lv_sper, lv_ve.

    DATA(ls_lang) = VALUE bapi2045la( langu = sy-langu ).

    CALL FUNCTION 'BAPI_INSPLOT_GETDETAIL'
      EXPORTING
        number        = <gs_sel>-prueflos
        language      = ls_lang
      TABLES
        system_status = lt_stat
      EXCEPTIONS
        OTHERS        = 1.

    "------------------------------------------------------------------*
* Technischer Fehler (RFC / Laufzeitfehler)
    "------------------------------------------------------------------*
    IF sy-subrc <> 0.

      MESSAGE |BAPI_INSPLOT_GETDETAIL Fehler bei Prüflos { <gs_sel>-prueflos }|
        TYPE 'W'.

      CONTINUE.

    ENDIF.

    "------------------------------------------------------------------*
* BAPI Fehler (fachlich)
    "------------------------------------------------------------------*
    IF ls_return-type = 'E' OR
       ls_return-type = 'A'.

      MESSAGE |BAPI Fehler für Prüflos { <gs_sel>-prueflos }: { ls_return-message }|
        TYPE 'W'.

      CONTINUE.

    ENDIF.

    "------------------------------------------------------------------*
* Warnung (nicht abbrechen)
    "------------------------------------------------------------------*
    IF ls_return-type = 'W'.

      MESSAGE |BAPI Warnung für Prüflos { <gs_sel>-prueflos }: { ls_return-message }|
        TYPE 'I'.

    ENDIF.

    "------------------------------------------------------------------*
* Kein Status zurückgegeben
    "------------------------------------------------------------------*
    IF lt_stat IS INITIAL.

      MESSAGE |Keine Statusdaten für Prüflos { <gs_sel>-prueflos } gefunden|
        TYPE 'W'.

      CONTINUE.

    ENDIF.

    LOOP AT lt_stat ASSIGNING FIELD-SYMBOL(<ls_stat>).

      CASE <ls_stat>-sys_status.
        WHEN gc_status_gesp.
          lv_gesp = abap_true.
        WHEN gc_status_sper.
          lv_sper = abap_true.
        WHEN gc_status_ve.
          lv_ve = abap_true.
      ENDCASE.

    ENDLOOP.

    IF lv_gesp = abap_true. CONTINUE. ENDIF.
    IF lv_sper = abap_true. CONTINUE. ENDIF.
    IF lv_ve   = abap_false. CONTINUE. ENDIF.

    APPEND <gs_sel> TO gt_sel_filtered.

  ENDLOOP.

ENDFORM.

FORM load_customizing.

  SELECT * INTO TABLE @gt_param FROM yqm_param_t.

  IF sy-subrc <> 0.
    CLEAR gt_param.
  ELSE.
    SORT gt_param BY zaehler mkmnr.
  ENDIF.

  SELECT * INTO TABLE @gt_cert_attr FROM yqm_cert_attr_t.
  IF sy-subrc <> 0.
    CLEAR gt_cert_attr.
  ELSE.
    SORT gt_cert_attr BY attribut verwmerkm.
  ENDIF.

ENDFORM.

FORM process_data.

  LOOP AT gt_sel_filtered ASSIGNING <gs_sel>.

    CLEAR gs_exc.

    " Kunde
    IF <gs_sel>-yqm_kunnrzl IS INITIAL.
      gs_exc-yqm_kunnrzl = <gs_sel>-kunnr.
    ELSE.
      gs_exc-yqm_kunnrzl = <gs_sel>-yqm_kunnrzl.
    ENDIF.

    gs_exc-prueflos = <gs_sel>-prueflos.
    gs_exc-merknr   = <gs_sel>-verwmerkm.
    gs_exc-messid   = <gs_sel>-yqm_messid.

    " Filter Attribut
    IF <gs_sel>-attribut = '['.
      CONTINUE.
    ENDIF.

    " Mittelwert
    CALL FUNCTION 'FLTP_CHAR_CONVERSION'
      EXPORTING
        input = <gs_sel>-mittelwert
      IMPORTING
        flstr = gs_exc-mittelwert.

    " Einheit
    SELECT SINGLE mseht
      FROM t006a
      INTO @gs_exc-masseinhsw
      WHERE spras = 'D'
      AND msehi = @<gs_sel>-masseinhsw.

    IF sy-subrc <> 0.
      CLEAR gs_exc-masseinhsw.
    ENDIF.

    " Methode
    SELECT SINGLE kurztext
      FROM qmtt
      INTO @gs_exc-pmethode
      WHERE werks   = @<gs_sel>-qmtb_werks
        AND pmtnr   = @<gs_sel>-pmethode
        AND version = @<gs_sel>-pmtversion
        AND sprache = 'D'.

    IF sy-subrc <> 0.
      CLEAR gs_exc-pmethode.
    ENDIF.

    " Timestamp
    SELECT SINGLE vdatum, vezeiterf
      FROM qave
      INTO (@gs_exc-vedatum, @gs_exc-vezeit)
      WHERE prueflos = @gs_exc-prueflos.

    IF sy-subrc <> 0.
      CLEAR: gs_exc-vedatum,
             gs_exc-vezeit.
    ENDIF.

    IF sy-subrc = 0.
      CONVERT DATE gs_exc-vedatum TIME gs_exc-vezeit
        INTO TIME STAMP gs_exc-timestamp TIME ZONE sy-zonlo.
    ENDIF.

    APPEND gs_exc TO gt_exc.

    " ALV mapping
    CASE 'X'.
      WHEN pa_tab1.
        MOVE-CORRESPONDING gs_exc TO gs_it.
        APPEND gs_it TO gt_it.
      WHEN pa_tab2.
        MOVE-CORRESPONDING gs_exc TO gs_it2.
        APPEND gs_it2 TO gt_it2.
      WHEN pa_tab3.
        MOVE-CORRESPONDING gs_exc TO gs_it3.
        APPEND gs_it3 TO gt_it3.
    ENDCASE.

  ENDLOOP.

  IF gt_exc IS INITIAL.
    MESSAGE 'Keine Daten zur Auswertung vorhanden' TYPE 'I'.
    RETURN.
  ENDIF.

ENDFORM.

FORM output_summary.

  WRITE: / '***** Programmende *****'.

ENDFORM.
