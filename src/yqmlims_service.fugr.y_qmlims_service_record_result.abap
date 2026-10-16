FUNCTION y_qmlims_service_record_result.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(IV_PRUEFLOS) TYPE  QPLOS
*"     VALUE(IV_PN) TYPE  YQM_PROBENEHMER03 OPTIONAL
*"     VALUE(IV_PN_DATUM) TYPE  YQM_PROBENAHMEDATUM OPTIONAL
*"     VALUE(IV_PN_ZEIT) TYPE  YQM_PROBENAHMEZEIT OPTIONAL
*"  TABLES
*"      IT_QPMK_DATA STRUCTURE  YQM03_PR_QPMK_DATA
*"----------------------------------------------------------------------

  DATA: ls_qpmk_data            TYPE yqm03_pr_qpmk_data.
  DATA: ls_inspoper             TYPE bapi2045l2.
  DATA: lt_inspoper             TYPE TABLE OF bapi2045l2.
  DATA: ls_insppoints           TYPE bapi2045l4.
  DATA: lt_insppoints           TYPE TABLE OF bapi2045l4.
  DATA: ls_char_requirements    TYPE bapi2045d1.
  DATA: lt_char_requirements    TYPE TABLE OF bapi2045d1.
*  DATA: lt_char_requirements_h  TYPE TABLE OF bapi2045d1.
  DATA: ls_sample_results_h     TYPE bapi2045d3.
  DATA: ls_sample_results       TYPE bapi2045d3.
  DATA: lt_sample_results       TYPE TABLE OF bapi2045d3.
  DATA: lt_sample_results_u     TYPE TABLE OF bapi2045d3.
  DATA: ls_return               TYPE bapiret2.
  DATA: lt_return               TYPE TABLE OF bapiret2.
  DATA: lv_messwert             TYPE qaqee-messwert.
  DATA: lv_attribut             TYPE qaser-attribut.


* Alle Daten zum eben erzeugten Prüflos besorgen
* 1. Prüfvorgänge
  CALL FUNCTION 'BAPI_INSPOPER_GETLIST'
    EXPORTING
      insplot       = iv_prueflos
    TABLES
      inspoper_list = lt_inspoper.

* Jetzt werden alle Prüfvorgänge abgearbeitet...
  LOOP AT lt_inspoper INTO ls_inspoper.

    CALL FUNCTION 'BAPI_INSPOPER_GETDETAIL'
      EXPORTING
        insplot                = ls_inspoper-insplot
        inspoper               = ls_inspoper-inspoper
        read_insppoints        = 'X'
        read_char_requirements = 'X'
        read_sample_results    = 'X'
        max_insppoints         = '999999'
      IMPORTING
        return                 = ls_return
      TABLES
        insppoints             = lt_insppoints
        char_requirements      = lt_char_requirements
        sample_results         = lt_sample_results.

    IF ls_return IS INITIAL.
* Wenn zu diesem Vorgang Prüfpunktergebnisse erwartet werden,...
      CHECK NOT lt_sample_results[] IS INITIAL.
      LOOP AT lt_insppoints INTO ls_insppoints.
        CLEAR lt_sample_results_u.
* Jetzt werden alle Zeilen der übergebenen Messwerte abgearbeitet.
        LOOP AT lt_sample_results INTO ls_sample_results
          WHERE insplot    = ls_insppoints-insplot
          AND   inspoper   = ls_insppoints-inspoper
          AND   inspsample = ls_insppoints-insppoint.

          ls_sample_results_h = ls_sample_results.
          READ TABLE lt_char_requirements INTO ls_char_requirements
               WITH KEY insplot    = ls_sample_results-insplot
                        inspoper   = ls_sample_results-inspoper
                        inspchar   = ls_sample_results-inspchar.
          IF sy-subrc = 0.
            LOOP AT it_qpmk_data INTO ls_qpmk_data
              WHERE werks     = ls_char_requirements-pmstr_char
              AND   verwmerkm = ls_char_requirements-mstr_char
              AND   messwert  NE space.

              CLEAR ls_sample_results.
              CLEAR lv_attribut.

              MOVE-CORRESPONDING ls_inspoper TO ls_sample_results.

* Meßwert und Attribut trennen (Eingabe <0.75)
              lv_messwert = ls_qpmk_data-messwert.

              IF     lv_messwert CS 'N.G.'.
                REPLACE 'N.G.'               IN lv_messwert WITH '('.
              ELSEIF lv_messwert CS 'n.g.'.
                REPLACE 'n.g.'               IN lv_messwert WITH '('.
              ELSEIF lv_messwert CS 'k.A.'.
                REPLACE 'k.A.'               IN lv_messwert WITH '['.
              ELSEIF lv_messwert CS 'N.N.'.
                REPLACE 'N.N.'               IN lv_messwert WITH '~'.
              ELSEIF lv_messwert CS 'n.n.'.
                REPLACE 'n.n.'               IN lv_messwert WITH '~'.
              ELSEIF lv_messwert CS 'NG'.
                REPLACE 'NG'                 IN lv_messwert WITH '('.
              ELSEIF lv_messwert CS 'ng'.
                REPLACE 'ng'                 IN lv_messwert WITH '('.
              ELSEIF lv_messwert CS 'NN'.
                REPLACE 'NN'                 IN lv_messwert WITH '~'.
              ELSEIF lv_messwert CS 'nn'.
                REPLACE 'nn'                 IN lv_messwert WITH '~'.
              ELSEIF lv_messwert CS 'KA'.
                REPLACE 'KA'                 IN lv_messwert WITH '['.
              ELSEIF lv_messwert CS 'ka'.
                REPLACE 'ka'                 IN lv_messwert WITH '['.
              ELSEIF lv_messwert CS 'kA'.
                REPLACE 'kA'                 IN lv_messwert WITH '['.
              ELSEIF lv_messwert CS 'SB'.
                REPLACE 'SB'                 IN lv_messwert WITH '{'.
              ELSEIF lv_messwert CS 'sb'.
                REPLACE 'sb'                 IN lv_messwert WITH '{'.
              ELSEIF lv_messwert CS 'sB'.
                REPLACE 'sB'                 IN lv_messwert WITH '{'.
              ELSEIF lv_messwert CS 'S.B.'.
                REPLACE 'S.B.'               IN lv_messwert WITH '{'.
              ELSEIF lv_messwert CS 's.B.'.
                REPLACE 's.B.'               IN lv_messwert WITH '{'.
              ELSEIF lv_messwert CS 'NA'.
                REPLACE 'NA'                 IN lv_messwert WITH 'U'.
              ELSEIF lv_messwert CS 'N.A.'.
                REPLACE 'N.A.'               IN lv_messwert WITH 'U'.
              ELSEIF lv_messwert CS 'n.a.'.
                REPLACE 'n.a.'               IN lv_messwert WITH 'U'.
              ELSEIF lv_messwert CS 'na'.
                REPLACE 'na'                 IN lv_messwert WITH 'U'.
              ELSEIF lv_messwert CS 'nA'.
                REPLACE 'nA'                 IN lv_messwert WITH 'U'.
              ELSEIF lv_messwert CS 'Na'.
                REPLACE 'Na'                 IN lv_messwert WITH 'U'.
              ENDIF.

              PERFORM messwert_attribut_trennen IN PROGRAM saplqeem
                      CHANGING lv_messwert
                               lv_attribut.

              ls_sample_results-inspchar   = ls_sample_results_h-inspchar.
              ls_sample_results-inspsample = ls_sample_results_h-inspsample.
              ls_sample_results-start_date = iv_pn_datum.
              ls_sample_results-start_time = iv_pn_zeit.
              ls_sample_results-end_date   = iv_pn_datum.
              ls_sample_results-end_time   = iv_pn_zeit.
              ls_sample_results-inspector  = iv_pn.
              ls_sample_results-closed     = 'X'.
              ls_sample_results-evaluated  = 'X'.
              ls_sample_results-mean_value = lv_messwert.
              ls_sample_results-smpl_attr  = lv_attribut.

              APPEND ls_sample_results TO lt_sample_results_u.

            ENDLOOP.
          ENDIF.
        ENDLOOP.

        IF NOT lt_sample_results_u[] IS INITIAL.
* ...diese Prüfergebnisse werden anschliessend verbucht...
          CALL FUNCTION 'BAPI_INSPOPER_RECORDRESULTS'
            EXPORTING
              insplot        = ls_inspoper-insplot
              inspoper       = ls_inspoper-inspoper
              insppointdata  = ls_insppoints
            IMPORTING
              return         = ls_return
            TABLES
              sample_results = lt_sample_results_u
              returntable    = lt_return.
*          APPEND LINES OF lt_return TO gt_bapiret.

** Verbuchung der Ergebnisse anstossen
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = 'X'.

* Sicherheitshalber manuell clearen.
          CALL FUNCTION 'QIBP_INSPOPER_CLEARBUFFER'.

* Globale Daten der FG QEEM zurücksetzen
          CALL FUNCTION 'QEEM_INT_OPERATION_RESET'
            EXPORTING
              i_data_initialize_proc       = 'X'
              i_lot_change_initialize_proc = 'X'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  IF sy-subrc = 0.
* Verbuchung der Ergebnisse anstossen
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.

* Sicherheitshalber manuell clearen.
    CALL FUNCTION 'QIBP_INSPOPER_CLEARBUFFER'.

* Globale Daten der FG QEEM zurücksetzen
    CALL FUNCTION 'QEEM_INT_OPERATION_RESET'
      EXPORTING
        i_data_initialize_proc       = 'X'
        i_lot_change_initialize_proc = 'X'.

  ELSE.
* Es wurden keine Prüfvorgänge angelegt

** Externe Protokollierung
*    ls_protokoll-ret = 1.
*    MOVE '057' TO ls_protokoll-fehlnr.
*    MESSAGE w057(ziis_qm) INTO ls_protokoll-fehltxt.
*    APPEND ls_protokoll TO et_protokoll.

  ENDIF.

ENDFUNCTION.
