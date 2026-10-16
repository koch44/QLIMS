FUNCTION y_qmlims_qfoa_create_evaluatio.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(i_qals) TYPE  qals
*"     REFERENCE(i_qave) TYPE  qave
*"     VALUE(i_no_status_check) TYPE  flag OPTIONAL
*"     VALUE(i_no_editor) TYPE  flag OPTIONAL
*"  EXPORTING
*"     VALUE(e_subrc) TYPE  sy-subrc
*"  TABLES
*"      e_protocol STRUCTURE  rqevp OPTIONAL
*"----------------------------------------------------------------------

  DATA: lv_cont   TYPE c,
        lv_text   TYPE text255,
        lv_tdname TYPE thead-tdname.

  DATA: ls_tq77t TYPE tq77t,
        lt_tq77t TYPE STANDARD TABLE OF tq77t WITH EMPTY KEY,
        ls_tq17t TYPE tq17t,
        lt_tq17t TYPE STANDARD TABLE OF tq17t WITH EMPTY KEY.

  DATA: lv_status_beur TYPE jest-stat.

  DATA: ls_qamv TYPE qamv,
        lt_qamv TYPE STANDARD TABLE OF qamv WITH EMPTY KEY,
        ls_qasr TYPE qasr,
        lt_qasr TYPE STANDARD TABLE OF qasr WITH EMPTY KEY,
        ls_qapp TYPE qapp,
        lt_qapp TYPE STANDARD TABLE OF qapp WITH EMPTY KEY.

  DATA: ls_dummy40 TYPE yqm_dummy40.

  DATA: lt_lines TYPE STANDARD TABLE OF tline WITH EMPTY KEY.

  DATA: BEGIN OF ls_tdobject,
          mandant    TYPE qasr-mandant,
          katalgart1 TYPE qasr-katalgart1,
          gruppe1    TYPE qasr-gruppe1,
          code1      TYPE qasr-code1,
          version1   TYPE qasr-version1,
          langu      TYPE sy-langu,
        END OF ls_tdobject.

  " Default
  CLEAR gv_subrc.
  e_subrc = 0.

  CLEAR gt_results.
  CLEAR gt_lines.

  " Texte für Attribut/Fehlerklasse
  SELECT *
    FROM tq77t
    WHERE sprache = @sy-langu
    INTO TABLE @lt_tq77t.
  IF sy-subrc <> 0.
    CLEAR lt_tq77t.
  ENDIF.

  SELECT *
    FROM tq17t
    WHERE sprache = @sy-langu
    INTO TABLE @lt_tq17t.
  IF sy-subrc <> 0.
    CLEAR lt_tq17t.
  ENDIF.

  " Nachschlagen wird oft gemacht → sortieren für READ ... BINARY SEARCH
  SORT lt_tq77t BY sprache attribut.
  SORT lt_tq17t BY sprache fehlklasse.

  " Material-Spezifisch
  SELECT *
    FROM yqm_matn_mk_t
    WHERE matnr = @i_qals-matnr
    ORDER BY matnr, zaehler
    INTO TABLE @gt_matn_mk.
  IF sy-subrc <> 0.
    CLEAR gt_matn_mk.
  ENDIF.

  IF gt_matn_mk IS INITIAL.
    CLEAR gt_matn_mk.
  ENDIF.

  gs_qals = i_qals.
  gv_no_editor = i_no_editor.

  " Aktivitätstyp bestimmen (Display/Change)
  CALL FUNCTION 'STATUS_CHECK'
    EXPORTING
      bypass_buffer = 'X'
      objnr         = gs_qals-objnr
      status        = 'I0218'
    EXCEPTIONS
      OTHERS        = 3.

  IF sy-subrc = 0.
    gv_aktyp = 'A'.
  ELSE.
    CLEAR gv_aktyp.
  ENDIF.

  " Belegdaten lesen
  SELECT *
    FROM qapp
    WHERE prueflos = @gs_qals-prueflos
    INTO TABLE @lt_qapp.
  IF sy-subrc <> 0.
    CLEAR lt_qapp.
  ENDIF.

  SELECT *
    FROM qamv
    WHERE prueflos = @gs_qals-prueflos
    INTO TABLE @lt_qamv.
  IF sy-subrc <> 0.
    CLEAR lt_qamv.
  ENDIF.

  SELECT *
    FROM qasr
    WHERE prueflos = @gs_qals-prueflos
    INTO TABLE @lt_qasr.
  IF sy-subrc <> 0.
    CLEAR lt_qasr.
  ENDIF.

  " QPRS nur wenn Proben vorhanden
  IF lt_qapp IS NOT INITIAL.
    SELECT phynr, ktext, sortnr
      FROM qprs
      WHERE plos2 = @gs_qals-prueflos
      INTO TABLE @DATA(lt_qprs).
    IF sy-subrc <> 0.
      CLEAR lt_qprs.
    ENDIF.

  ENDIF.

  " Sortieren für READ TABLE
  SORT lt_qapp BY prueflos vorglfnr probenr.
  SORT lt_qprs BY phynr.
  SORT lt_qasr BY prueflos vorglfnr merknr probenr.

  LOOP AT lt_qamv INTO ls_qamv.

    CLEAR gs_results.
    gs_results = CORRESPONDING #( ls_qamv ).
    ls_dummy40 = ls_qamv-dummy40.

    " VORNR bestimmen
    CALL FUNCTION 'QIBP_GET_VORNR'
      EXPORTING
        i_insplot      = ls_qamv-prueflos
        i_inspoper_int = ls_qamv-vorglfnr
      IMPORTING
        e_inspoper     = gs_results-vornr
      EXCEPTIONS
        OTHERS         = 3.

    IF sy-subrc <> 0.
      CLEAR gs_results-vornr.
    ENDIF.

    " Ergebnisse zu Merkmal
    LOOP AT lt_qasr INTO ls_qasr
      WHERE prueflos = ls_qamv-prueflos
        AND vorglfnr = ls_qamv-vorglfnr
        AND merknr   = ls_qamv-merknr.

      gs_results = CORRESPONDING #( BASE ( gs_results ) ls_qasr ).

      " TPLNR / PHYSNR bestimmen
      IF lt_qapp IS NOT INITIAL.
        READ TABLE lt_qapp INTO ls_qapp
          WITH KEY prueflos = ls_qasr-prueflos
                   vorglfnr = ls_qasr-vorglfnr
                   probenr  = ls_qasr-probenr
          BINARY SEARCH.

        IF sy-subrc = 0.
          gs_results-tplnr = ls_qapp-tplnr.
          gs_results-phynr = ls_qapp-userc1+6(12).
        ELSE.
          gs_results-tplnr = gs_qals-yqm_tplnr.
          gs_results-phynr = gs_qals-yqm_qphysprnr. " FIX: war fälschlich tplnr
        ENDIF.
      ELSE.
        gs_results-tplnr = gs_qals-yqm_tplnr.
        gs_results-phynr = gs_qals-yqm_qphysprnr.   " FIX
      ENDIF.

      " QPRS-Text
      IF gs_results-phynr IS NOT INITIAL AND lt_qprs IS NOT INITIAL.
        READ TABLE lt_qprs INTO DATA(ls_qprs)
          WITH KEY phynr = gs_results-phynr
          BINARY SEARCH.
        IF sy-subrc = 0.
          gs_results-ktext  = ls_qprs-ktext.
          gs_results-sortnr = ls_qprs-sortnr.
        ENDIF.
      ENDIF.

      gs_results-statusr = ls_qasr-satzstatus.

      CASE gs_results-mbewertg.
        WHEN 'A'.
          gs_results-mbewertg_icon = icon_checked.
        WHEN 'R'.
          gs_results-mbewertg_icon = icon_incomplete.
        WHEN OTHERS.
          CLEAR gs_results-mbewertg_icon.
      ENDCASE.

      IF ls_dummy40-nbeurtrel IS NOT INITIAL.
        gs_results-nbeurtrel = 'X'.
      ENDIF.

      " Beurteilungstext (QPCT) aus Katalog lesen
      IF ls_dummy40-beurteilung IS NOT INITIAL
         AND ls_qasr-katalgart1 IS NOT INITIAL
         AND ls_qasr-gruppe1    IS NOT INITIAL
         AND ls_qasr-code1      IS NOT INITIAL.

        CLEAR: lv_tdname, lt_lines.

        ls_tdobject-mandant    = ls_qasr-mandant.
        ls_tdobject-katalgart1 = ls_qasr-katalgart1.
        ls_tdobject-gruppe1    = ls_qasr-gruppe1.
        ls_tdobject-code1      = ls_qasr-code1.
        ls_tdobject-version1   = ls_qasr-version1.
        ls_tdobject-langu      = sy-langu.

        lv_tdname = ls_tdobject.

        CALL FUNCTION 'READ_TEXT'
          EXPORTING
            id       = 'QPCT'
            language = sy-langu
            name     = lv_tdname
            object   = 'QKATALOG'
          TABLES
            lines    = lt_lines
          EXCEPTIONS
            OTHERS   = 8.

        IF sy-subrc = 0 AND lt_lines IS NOT INITIAL.
          APPEND LINES OF lt_lines TO gt_lines.
        ENDIF.

      ENDIF.

      " Attribut-Text
      IF gs_results-attribut IS NOT INITIAL.
        READ TABLE lt_tq77t INTO ls_tq77t
          WITH KEY sprache  = sy-langu
                   attribut = gs_results-attribut
          BINARY SEARCH.
        IF sy-subrc = 0.
          gs_results-attribut_text = ls_tq77t-kurztext.
        ENDIF.
      ENDIF.

      " Fehlerklasse-Text
      IF gs_results-fehlklas IS NOT INITIAL.
        READ TABLE lt_tq17t INTO ls_tq17t
          WITH KEY sprache    = sy-langu
                   fehlklasse = gs_results-fehlklas
          BINARY SEARCH.
        IF sy-subrc = 0.
          gs_results-fehlklas_text = ls_tq17t-kurztext.
        ENDIF.
      ENDIF.

      " Formatierungen
      PERFORM fltp_char_conversion CHANGING gs_results.

      IF gs_results-gruppe1 IS NOT INITIAL AND gs_results-code1 IS NOT INITIAL.
        CALL FUNCTION 'QPK1_CODE_TEXT'
          EXPORTING
            i_katalogart = gs_results-katalgart1
            i_codegruppe = gs_results-gruppe1
            i_code       = gs_results-code1
          IMPORTING
            e_text       = gs_results-code_txt
            e_grouptext  = gs_results-gruppe_txt
          EXCEPTIONS
            OTHERS       = 2.

        IF sy-subrc <> 0.
          CLEAR: gs_results-code_txt, gs_results-gruppe_txt.
        ENDIF.
      ELSE.
        CLEAR: gs_results-code_txt, gs_results-gruppe_txt.
      ENDIF.

      APPEND gs_results TO gt_results.

    ENDLOOP.

    " SUBRC-Behandlung: sy-subrc nach LOOP ist nur sinnvoll als "Loop lief nicht".
    " Wir bauen hier bewusst die Ersatzlogik, wenn KEIN QASR gefunden wurde.
    IF sy-subrc <> 0 AND lt_qapp IS NOT INITIAL.
      LOOP AT lt_qapp INTO ls_qapp
        WHERE prueflos = ls_qamv-prueflos
          AND vorglfnr = ls_qamv-vorglfnr.

        gs_results = CORRESPONDING #( ls_qamv ).
        gs_results-vorglfnr = ls_qapp-vorglfnr.
        gs_results-probenr  = ls_qapp-probenr.
        gs_results-tplnr    = ls_qapp-tplnr.
        gs_results-phynr    = ls_qapp-userc1+6(12).

        PERFORM fltp_char_conversion CHANGING gs_results.

        IF gs_results-gruppe1 IS NOT INITIAL AND gs_results-code1 IS NOT INITIAL.
          CALL FUNCTION 'QPK1_CODE_TEXT'
            EXPORTING
              i_katalogart = gs_results-katalgart1
              i_codegruppe = gs_results-gruppe1
              i_code       = gs_results-code1
            IMPORTING
              e_text       = gs_results-code_txt
              e_grouptext  = gs_results-gruppe_txt
            EXCEPTIONS
              OTHERS       = 2.
          IF sy-subrc <> 0.
            CLEAR: gs_results-code_txt, gs_results-gruppe_txt.
          ENDIF.
        ELSE.
          CLEAR: gs_results-code_txt, gs_results-gruppe_txt.
        ENDIF.

        APPEND gs_results TO gt_results.
      ENDLOOP.
    ENDIF.

  ENDLOOP.

  " Screen
  IF gv_no_editor = 'X'.
    CALL SCREEN 200 STARTING AT 1 1 ENDING AT 200 30.
  ELSE.
    CALL SCREEN 200 STARTING AT 1 1 ENDING AT 200 50.
  ENDIF.

  e_subrc = gv_subrc.

  " Status BEUR setzen?
  IF gv_subrc = 0 AND gv_no_editor <> 'X'.

    CALL FUNCTION 'STATUS_TEXT_CONVERSION'
      EXPORTING
        language      = sy-langu
        mode          = 'E'
        objnr         = gs_qals-objnr
        txt04         = gc_beur
      IMPORTING
        status_number = lv_status_beur
      EXCEPTIONS
        OTHERS        = 5.

    IF sy-subrc <> 0.
      MESSAGE a307(yqmlims) WITH gc_beur gs_qals-stsma.
    ENDIF.

    CALL FUNCTION 'STATUS_CHECK'
      EXPORTING
        bypass_buffer = 'X'
        client        = sy-mandt
        objnr         = gs_qals-objnr
        status        = lv_status_beur
      EXCEPTIONS
        OTHERS        = 3.

    IF sy-subrc <> 0.

      CONCATENATE 'Für Prüflos'(009)
                  gs_qals-prueflos
                  'wurde der Status BEUR (Beurteilung erforderlich) noch nicht gesetzt.'(010)
                  'Soll dieser Status gesetzt werden?'(011)
             INTO lv_text
             SEPARATED BY space.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar       = 'Status BEUR (Beurteilung erforderlich) setzen?'(008)
          text_question  = lv_text
          text_button_1  = 'Ja'(004)
          text_button_2  = 'Nein'(005)
          default_button = '1'
        IMPORTING
          answer         = lv_cont
        EXCEPTIONS
          OTHERS         = 2.
      IF sy-subrc = 0.
        IF lv_cont = '1'.
          lv_cont = 'X'.
        ELSE.
          CLEAR lv_cont.
        ENDIF.
      ELSE.
        CLEAR lv_cont.
      ENDIF.

      IF lv_cont = 'X'.
        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            objnr       = gs_qals-objnr
            user_status = lv_status_beur
          EXCEPTIONS
            OTHERS      = 4.

        IF sy-subrc = 0.
          COMMIT WORK.
        ELSE.
          MESSAGE e302(yqmlims) WITH gs_qals-prueflos 'BEUR'.
        ENDIF.
      ENDIF.

    ENDIF.
  ENDIF.

ENDFUNCTION.
