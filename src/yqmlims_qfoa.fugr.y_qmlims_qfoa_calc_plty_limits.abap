FUNCTION y_qmlims_qfoa_calc_plty_limits.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_QALS) LIKE  QALS STRUCTURE  QALS
*"     REFERENCE(I_QAVE) LIKE  QAVE STRUCTURE  QAVE
*"  EXPORTING
*"     VALUE(E_SUBRC) LIKE  SY-SUBRC
*"  TABLES
*"      E_PROTOCOL STRUCTURE  RQEVP OPTIONAL
*"----------------------------------------------------------------------

* Dieser Baustein prüft, ob ein EIntrag in die Plausibilitätstabelle
* gemacht werden soll. Bei Bedarf wird aus den letzten bis zu 10 Messwerten die
* Standardabweichung berechnet und die doppelte Standardabweichung als
* untere und obere Plausibilitätsgrenze abgelegt.

  TYPES: lty_r_tplnr TYPE RANGE OF yqm_plty_limit_t-tplnr.

  TYPES: BEGIN OF lty_key,
           werks     TYPE yqm_plty_excl_t-werks,
           verwmerkm TYPE yqm_plty_excl_t-verwmerkm,
         END OF lty_key,
         lty_t_key TYPE STANDARD TABLE OF lty_key WITH EMPTY KEY.

  DATA lt_keys TYPE lty_t_key.

  DATA: lr_tplnr       TYPE lty_r_tplnr,
        lv_mittelwert  TYPE qasr-mittelwert,
        ls_plty_limits TYPE yqm_plty_limit_t,
        lt_plty_limits TYPE STANDARD TABLE OF yqm_plty_limit_t WITH EMPTY KEY,
        ls_vektor      TYPE LINE OF tvst_ftab,
        lt_vektor      TYPE tvst_ftab.

  CLEAR gv_subrc.
  CLEAR gt_plty_limits_u.
  CLEAR gt_plty_limits_i.

  CHECK i_qals-art = 'CHTP'.

  gs_qals = i_qals.

  " Exclude-Patterns (generic)
  SELECT *
    FROM yqm_tpln_excl_t
    WHERE generic = @abap_true
    INTO TABLE @gt_tpln_exclude.
  IF sy-subrc <> 0.
    CLEAR gt_tpln_exclude.
  ENDIF.

  " QAPP lesen
  SELECT prueflos, vorglfnr, tplnr, probenr
    FROM qapp
    WHERE prueflos = @gs_qals-prueflos
    INTO TABLE @DATA(lt_qapp).
  IF sy-subrc <> 0.
    CLEAR lt_qapp.
  ENDIF.
  CHECK lt_qapp IS NOT INITIAL.

  " QAPP anhand Patterns filtern (wie vorher)
  LOOP AT gt_tpln_exclude INTO gs_tpln_exclude.
    DELETE lt_qapp WHERE tplnr CP gs_tpln_exclude-tplnr.
  ENDLOOP.

  CHECK lt_qapp IS NOT INITIAL.

  " lr_tplnr aufbauen: nur TPLNR, die NICHT explizit in yqm_tpln_excl_t existieren
  " (COUNT(*) + sy-subrc ist dafür ungeeignet => EXISTS prüfen)
  LOOP AT lt_qapp INTO DATA(ls_qapp).
    SELECT SINGLE @abap_true
      FROM yqm_tpln_excl_t
      WHERE tplnr = @ls_qapp-tplnr
      INTO @DATA(lv_exists).
    IF sy-subrc <> 0.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_qapp-tplnr ) TO lr_tplnr.
    ENDIF.
  ENDLOOP.

  SORT lr_tplnr BY low.
  DELETE ADJACENT DUPLICATES FROM lr_tplnr COMPARING low.

  CHECK lr_tplnr IS NOT INITIAL.

  " QAMV / QASR lesen
  SELECT prueflos, vorglfnr, merknr,
         qpmk_werks, verwmerkm, grenzeun1, stellen
    FROM qamv
    WHERE prueflos = @gs_qals-prueflos
    INTO TABLE @DATA(lt_qamv).
  IF sy-subrc <> 0.
    CLEAR lt_qamv.
  ENDIF.

  SELECT prueflos, vorglfnr, merknr, probenr,
         satzstatus, attribut, mittelwert, mittelwni
    FROM qasr
    WHERE prueflos = @gs_qals-prueflos
    INTO TABLE @DATA(lt_qasr).
  IF sy-subrc <> 0.
    CLEAR lt_qasr.
  ENDIF.

  CHECK lt_qamv IS NOT INITIAL.

  " Schlüssel für FAE deduplizieren (ATC: FAE ohne Dedupe ist häufig Finding)
  lt_keys = VALUE lty_t_key(
    FOR ls_qamv_row IN lt_qamv
    ( werks     = ls_qamv_row-qpmk_werks
      verwmerkm = ls_qamv_row-verwmerkm )
  ).
  SORT lt_keys BY werks verwmerkm.
  DELETE ADJACENT DUPLICATES FROM lt_keys COMPARING werks verwmerkm.

  " Exclude-Liste lesen
  SELECT werks, verwmerkm
    FROM yqm_plty_excl_t
    FOR ALL ENTRIES IN @lt_keys
    WHERE werks     = @lt_keys-werks
      AND verwmerkm = @lt_keys-verwmerkm
    INTO TABLE @DATA(lt_plty_exclude).
  IF sy-subrc <> 0.
    CLEAR lt_plty_exclude.
  ENDIF.

  SORT lt_plty_exclude BY werks verwmerkm.

  " Limits lesen (nur für relevante TPLNRs)
  SELECT *
    FROM yqm_plty_limit_t
    FOR ALL ENTRIES IN @lt_keys
    WHERE tplnr     IN @lr_tplnr
      AND werks     = @lt_keys-werks
      AND verwmerkm = @lt_keys-verwmerkm
    INTO TABLE @lt_plty_limits.
  IF sy-subrc <> 0.
    CLEAR lt_plty_limits.
  ENDIF.

  SORT lt_plty_limits BY tplnr werks verwmerkm.

  " Sperren (wenn Sperre nicht geht -> sauber abbrechen)
  LOOP AT lt_plty_limits INTO ls_plty_limits.
    CALL FUNCTION 'ENQUEUE_EYQM_PLTY_LIMITS'
      EXPORTING
        tplnr          = ls_plty_limits-tplnr
        werks          = ls_plty_limits-werks
        verwmerkm      = ls_plty_limits-verwmerkm
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      gv_subrc = 8.
      EXIT.
    ENDIF.
  ENDLOOP.

  CHECK gv_subrc IS INITIAL.

  " Hauptlogik wie bei dir (nur MOVE/REFRESH modernisiert, Tabellenhandling sauber)
  LOOP AT lt_qamv INTO DATA(ls_qamv).

    READ TABLE lt_plty_exclude TRANSPORTING NO FIELDS
      WITH KEY werks     = ls_qamv-qpmk_werks
               verwmerkm = ls_qamv-verwmerkm
      BINARY SEARCH.
    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.

    LOOP AT lt_qapp INTO ls_qapp
      WHERE prueflos = ls_qamv-prueflos
        AND vorglfnr = ls_qamv-vorglfnr.

      CLEAR lt_vektor.

      LOOP AT lt_qasr INTO DATA(ls_qasr)
        WHERE prueflos   = ls_qamv-prueflos
          AND vorglfnr   = ls_qamv-vorglfnr
          AND merknr     = ls_qamv-merknr
          AND probenr    = ls_qapp-probenr
          AND satzstatus = '5'.

        READ TABLE lt_plty_limits INTO ls_plty_limits
          WITH KEY tplnr     = ls_qapp-tplnr
                   werks     = ls_qamv-qpmk_werks
                   verwmerkm = ls_qamv-verwmerkm
          BINARY SEARCH.

        IF sy-subrc = 0.

          IF ls_plty_limits-prueflos = i_qals-prueflos.
            CONTINUE.
          ENDIF.

          CASE ls_qasr-attribut.
            WHEN space OR '>' OR 'W'.
              lv_mittelwert = ls_qasr-mittelwert.
            WHEN '<'.
              lv_mittelwert = ls_qamv-grenzeun1.
            WHEN OTHERS.
              CONTINUE.
          ENDCASE.

          " Shift (wie vorher)
          ls_plty_limits-messwert10   = ls_plty_limits-messwert09.
          ls_plty_limits-messwert10ni = ls_plty_limits-messwert09ni.
          ls_plty_limits-messwert09   = ls_plty_limits-messwert08.
          ls_plty_limits-messwert09ni = ls_plty_limits-messwert08ni.
          ls_plty_limits-messwert08   = ls_plty_limits-messwert07.
          ls_plty_limits-messwert08ni = ls_plty_limits-messwert07ni.
          ls_plty_limits-messwert07   = ls_plty_limits-messwert06.
          ls_plty_limits-messwert07ni = ls_plty_limits-messwert06ni.
          ls_plty_limits-messwert06   = ls_plty_limits-messwert05.
          ls_plty_limits-messwert06ni = ls_plty_limits-messwert05ni.
          ls_plty_limits-messwert05   = ls_plty_limits-messwert04.
          ls_plty_limits-messwert05ni = ls_plty_limits-messwert04ni.
          ls_plty_limits-messwert04   = ls_plty_limits-messwert03.
          ls_plty_limits-messwert04ni = ls_plty_limits-messwert03ni.
          ls_plty_limits-messwert03   = ls_plty_limits-messwert02.
          ls_plty_limits-messwert03ni = ls_plty_limits-messwert02ni.
          ls_plty_limits-messwert02   = ls_plty_limits-messwert01.
          ls_plty_limits-messwert02ni = ls_plty_limits-messwert01ni.
          ls_plty_limits-messwert01   = lv_mittelwert.
          ls_plty_limits-messwert01ni = ls_qasr-mittelwni.

          IF ls_plty_limits-stellen IS INITIAL.
            ls_plty_limits-stellen = ls_qamv-stellen.
          ENDIF.

          ls_plty_limits-aenderer  = sy-uname.
          ls_plty_limits-aenderdat = sy-datlo.
          ls_plty_limits-prueflos  = gs_qals-prueflos.

          " Vektor füllen (MOVE -> =)
          IF ls_plty_limits-messwert01ni IS NOT INITIAL.
            ls_vektor-flt = ls_plty_limits-messwert01.
            APPEND ls_vektor TO lt_vektor.
          ENDIF.
          IF ls_plty_limits-messwert02ni IS NOT INITIAL.
            ls_vektor-flt = ls_plty_limits-messwert02.
            APPEND ls_vektor TO lt_vektor.
          ENDIF.
          IF ls_plty_limits-messwert03ni IS NOT INITIAL.
            ls_vektor-flt = ls_plty_limits-messwert03.
            APPEND ls_vektor TO lt_vektor.
          ENDIF.
          IF ls_plty_limits-messwert04ni IS NOT INITIAL.
            ls_vektor-flt = ls_plty_limits-messwert04.
            APPEND ls_vektor TO lt_vektor.
          ENDIF.
          IF ls_plty_limits-messwert05ni IS NOT INITIAL.
            ls_vektor-flt = ls_plty_limits-messwert05.
            APPEND ls_vektor TO lt_vektor.
          ENDIF.
          IF ls_plty_limits-messwert06ni IS NOT INITIAL.
            ls_vektor-flt = ls_plty_limits-messwert06.
            APPEND ls_vektor TO lt_vektor.
          ENDIF.
          IF ls_plty_limits-messwert07ni IS NOT INITIAL.
            ls_vektor-flt = ls_plty_limits-messwert07.
            APPEND ls_vektor TO lt_vektor.
          ENDIF.
          IF ls_plty_limits-messwert08ni IS NOT INITIAL.
            ls_vektor-flt = ls_plty_limits-messwert08.
            APPEND ls_vektor TO lt_vektor.
          ENDIF.
          IF ls_plty_limits-messwert09ni IS NOT INITIAL.
            ls_vektor-flt = ls_plty_limits-messwert09.
            APPEND ls_vektor TO lt_vektor.
          ENDIF.
          IF ls_plty_limits-messwert10ni IS NOT INITIAL.
            ls_vektor-flt = ls_plty_limits-messwert10.
            APPEND ls_vektor TO lt_vektor.
          ENDIF.

          CALL FUNCTION 'TV_VOLA_CALC'
            IMPORTING
              sigma  = ls_plty_limits-stdaw
              my     = ls_plty_limits-mittelwert
            TABLES
              vektor = lt_vektor
            EXCEPTIONS
              OTHERS = 3.

          IF sy-subrc = 0.
            ls_plty_limits-mittelwni = 'X'.

            IF ls_plty_limits-plausiunte IS INITIAL.
              ls_plty_limits-plausiunni = 'X'.
            ENDIF.
            ls_plty_limits-plausiunte =
              ls_plty_limits-mittelwert - ( 2 * ls_plty_limits-stdaw ).

            IF ls_plty_limits-plausioben IS INITIAL.
              ls_plty_limits-plausiobni = 'X'.
            ENDIF.
            ls_plty_limits-plausioben =
              ls_plty_limits-mittelwert + ( 2 * ls_plty_limits-stdaw ).
          ELSE.
            CLEAR: ls_plty_limits-mittelwert,
                   ls_plty_limits-mittelwni,
                   ls_plty_limits-stdaw,
                   ls_plty_limits-plausiunte,
                   ls_plty_limits-plausiunni,
                   ls_plty_limits-plausioben,
                   ls_plty_limits-plausiobni.
          ENDIF.

          APPEND ls_plty_limits TO gt_plty_limits_u.

        ELSE.
          CLEAR ls_plty_limits.
          ls_plty_limits-tplnr        = ls_qapp-tplnr.
          ls_plty_limits-werks        = ls_qamv-qpmk_werks.
          ls_plty_limits-verwmerkm    = ls_qamv-verwmerkm.
          ls_plty_limits-stellen      = ls_qamv-stellen.
          ls_plty_limits-messwert01   = ls_qasr-mittelwert.
          ls_plty_limits-messwert01ni = ls_qasr-mittelwni.
          ls_plty_limits-aenderer     = sy-uname.
          ls_plty_limits-aenderdat    = sy-datlo.
          ls_plty_limits-prueflos     = gs_qals-prueflos.
          APPEND ls_plty_limits TO gt_plty_limits_i.
        ENDIF.

      ENDLOOP.
    ENDLOOP.
  ENDLOOP.

  IF gt_plty_limits_u IS NOT INITIAL.
    SORT gt_plty_limits_u BY tplnr werks verwmerkm.
    DELETE ADJACENT DUPLICATES FROM gt_plty_limits_u COMPARING tplnr werks verwmerkm.
    MODIFY yqm_plty_limit_t FROM TABLE gt_plty_limits_u.
    IF sy-subrc <> 0.
      e_subrc = sy-subrc.
      EXIT.
    ENDIF.
  ENDIF.

  IF gt_plty_limits_i IS NOT INITIAL.
    SORT gt_plty_limits_i BY tplnr werks verwmerkm.
    DELETE ADJACENT DUPLICATES FROM gt_plty_limits_i COMPARING tplnr werks verwmerkm.
    INSERT yqm_plty_limit_t FROM TABLE gt_plty_limits_i.
    IF sy-subrc <> 0.
      e_subrc = sy-subrc.
      EXIT.
    ENDIF.
  ENDIF.

  e_subrc = gv_subrc.

ENDFUNCTION.
