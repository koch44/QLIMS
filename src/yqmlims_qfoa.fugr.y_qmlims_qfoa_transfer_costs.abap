FUNCTION y_qmlims_qfoa_transfer_costs.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_QALS) LIKE  QALS STRUCTURE  QALS
*"     REFERENCE(I_QAVE) LIKE  QAVE STRUCTURE  QAVE
*"     VALUE(I_NO_STATUS_CHECK) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(E_SUBRC) LIKE  SY-SUBRC
*"  TABLES
*"      E_PROTOCOL STRUCTURE  RQEVP
*"----------------------------------------------------------------------

* Dieser Baustein ersetzt die Transaktion ZCOST und ermöglicht eine
* automatisierte Kostenübertragung als Folgeaktion zum VE.
*
* Die Prüfkosten, die aus den im Prüflos hinterlegten Leistungsarten
* ermittelt werden, werden über die CO-Leistungsverrechnung dem
* Empfängerauftrag belastet.

  DATA: lv_uname  TYPE sy-uname,
        ls_usr03  TYPE usr03,
        lv_manual TYPE flag,
        lv_cont   TYPE c,
        lv_text   TYPE text255.

  CLEAR: gs_qals,
         gs_cost_header,
         gv_display_log,
         gs_qamv,
         gs_qasr,
         gt_qamv,
         gt_qasr.

  CLEAR: lv_manual,
         lv_cont.

  gs_qals = i_qals.

* Statusschema für Prüflosherkunft ermitteln
  SELECT SINGLE art, stsma
    FROM tq30
    WHERE art = @gc_pruefart
    INTO @gs_tq30.
  IF sy-subrc <> 0.
    MESSAGE a705(yqmlims) WITH gc_pruefart.
  ENDIF.

  IF gs_tq30-stsma IS INITIAL.
    MESSAGE a706(yqmlims) WITH gc_pruefart.
  ENDIF.

* Labor-Customizing lesen (Kostenrechnungskreis/Kostenstelle)
  SELECT SINGLE kokrs, kostl
    FROM yqm_vnltcu_t
    WHERE swerk = @i_qals-werk
    INTO @DATA(ls_vnltcu).
  IF sy-subrc = 0.
    gv_kostl = ls_vnltcu-kostl.
    gv_kokrs = ls_vnltcu-kokrs.
  ENDIF.

* Tabelle für Kostenstelle pro Leistungsart
  SELECT *
    FROM yqm_vnltilv_t
    INTO TABLE @gt_vnltilv
    WHERE kokrs = @ls_vnltcu-kokrs.
  IF sy-subrc <> 0.
    CLEAR gt_vnltilv  .
  ELSE.
    SORT gt_vnltilv BY kokrs lstar datbi.
  ENDIF.

* Interne Statusnummer zum Anwenderstatus KSTU ermitteln
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language      = sy-langu
      mode          = 'E'
      stsma         = gs_tq30-stsma
      txt04         = gc_kstu
    IMPORTING
      status_number = gv_stat_kstu
    EXCEPTIONS
      OTHERS        = 5.
  IF sy-subrc <> 0.
    MESSAGE a707(yqmlims) WITH gc_kstu gs_tq30-stsma.
  ENDIF.

* Prüfen ob Kostenübertragung bereits erfolgt
  CALL FUNCTION 'STATUS_CHECK'
    EXPORTING
      bypass_buffer = 'X'
      objnr         = gs_qals-objnr
      status        = gv_stat_kstu
    EXCEPTIONS
      OTHERS        = 3.
  IF sy-subrc = 0.
    MESSAGE i788(yqmlims) WITH gs_qals-prueflos.
    RETURN.
  ENDIF.

* Auftrag sperren / ggf. manuell ausweichen
  WHILE lv_cont IS INITIAL.

    CALL FUNCTION 'ENQUEUE_ESORDER'
      EXPORTING
        aufnr          = i_qals-aufnr
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
          " Auftrag gesperrt von User
          lv_uname = sy-msgv1.

          CALL FUNCTION 'SUSR_USER_ADDRESS_READ'
            EXPORTING
              user_name  = lv_uname
            IMPORTING
              user_usr03 = ls_usr03
            EXCEPTIONS
              OTHERS     = 2.

          IF sy-subrc = 0.
            MESSAGE s210(yqmlims) WITH i_qals-aufnr
                                       ls_usr03-name1
                                       ls_usr03-name2 INTO lv_text.
          ELSE.
            MESSAGE s210(yqmlims) WITH i_qals-aufnr
                                       'User'
                                       lv_uname INTO lv_text.
          ENDIF.

          CONCATENATE lv_text
                      'Soll die Kostenübertragung erneut versucht werden?'(007)
                 INTO lv_text
                 SEPARATED BY space.

          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar       = TEXT-006
              text_question  = lv_text
              text_button_1  = 'Ja'(004)
              text_button_2  = 'Nein'(005)
              default_button = '1'
            IMPORTING
              answer         = lv_cont
            EXCEPTIONS
              OTHERS         = 2.
          IF sy-subrc <> 0.
            lv_cont   = 'X'.
            lv_manual = 'X'.
          ELSE.
            IF lv_cont = '1'.
              CLEAR lv_cont.
            ELSE.
              lv_cont   = 'X'.
              lv_manual = 'X'.
            ENDIF.
          ENDIF.
        WHEN OTHERS.
          lv_cont   = 'X'.
          lv_manual = 'X'.
      ENDCASE.

    ELSE.
      lv_cont = 'X'.
      CLEAR lv_manual.
    ENDIF.

  ENDWHILE.

  IF lv_manual = 'X'.
    MESSAGE s211(yqmlims) WITH i_qals-aufnr.
    RETURN.
  ENDIF.

* Automatische Kostenübertragung
  gs_cost_header-buchdatum = i_qave-vdatum.

  CLEAR gt_log_handle.
  gs_log-object    = 'YQM'.
  gs_log-subobject = 'YQM_COST'.

  CONCATENATE 'Kostenübertragung Prüflos'
              gs_qals-prueflos
         INTO gs_log-extnumber
         SEPARATED BY space.

  CALL FUNCTION 'BAL_LOG_CREATE'
    EXPORTING
      i_s_log      = gs_log
    IMPORTING
      e_log_handle = gs_log_handle
    EXCEPTIONS
      OTHERS       = 1.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    APPEND gs_log_handle TO gt_log_handle.
  ENDIF.

* Kostenstellenwährung ermitteln
  PERFORM ermittlung_waehrung.

* Spezielle Abrechnungsaufträge nachlesen
  PERFORM lesen_abr_auftraege.

* Kostentabellen laden
  PERFORM lesen_kostentabellen.

* Kostenquelle ermitteln
  PERFORM ermitteln_kostenquelle.

* Standardumfang ermitteln (abhängig von Kostenquelle)
  CLEAR gr_merkmal.

  IF gs_cost_header-kostenquelle = 'T'
     OR gs_cost_header-kostenquelle = 'K'
     OR gs_cost_header-kostenquelle = 'L'.

    IF gs_kosten4-stumf IS NOT INITIAL.
      PERFORM ermitteln_standardumfang.
    ENDIF.

  ENDIF.

  IF gs_cost_header-kostenquelle = 'M'
     OR gr_merkmal IS NOT INITIAL.
    PERFORM lesen_merkmalsdaten.
  ENDIF.

* Tarifdaten lesen
  PERFORM lesen_tarif_daten.

* Leistungsarten ermitteln
  PERFORM lesen_lst_arten.

* Leistungsarten aufbereiten
  PERFORM aufbereiten_lstarten.

* Kosten berechnen
  PERFORM berechnen_kosten.

* Kosten übertragen
  PERFORM uebertragen_kosten.

  IF gv_display_log = 'X'.
    PERFORM display_log.
    PERFORM save_log.
  ENDIF.

ENDFUNCTION.
