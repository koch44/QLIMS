*&---------------------------------------------------------------------*
*& Include          YQ_LFW1P01
*&---------------------------------------------------------------------*
* Korrektur Christian Fischer 29.09.2026:
*  - write_prot: W-Saetze wieder ins Attachment (gt_m_ta1) statt Body
*  - set_t1:     Kettenzuweisung Probedatum korrigiert (Richtung)
*  - set_t1:     Extension-Pruefung setzt cv_subrc statt CHECK
*  - neu:        Empfaengerliste je Mail leeren
*  - neu:        Testumleitung nur im Nicht-Produktivsystem
*  - kopf:       Absicherung READ TABLE (kein Dump bei fehlendem Satz)
*&---------------------------------------------------------------------*
CLASS lcl_lfw IMPLEMENTATION.

  METHOD constructor.

    gv_m_uname_i = iv_uname_i.
    gt_m_rng_datum = it_rng_datum.
    gt_m_rng_los = it_rng_los.
    gt_m_rng_anl = it_rng_anl.
    gt_m_rng_kunnr = it_rng_kunnr.
    gt_m_rng_ext = it_rng_ext.
    gt_m_rng_txt = it_rng_txt.
    gt_m_rng_stat = it_rng_stat.
    gv_m_down = iv_down.
    gv_m_ausgabef = iv_ausgabef.
    gv_m_adr = iv_adr.
    gv_m_url = iv_url.
    gv_m_low = iv_low.
    gv_m_pfad = iv_pfad.
    gt_m_rng_probe = it_rng_probe.

  ENDMETHOD.

  METHOD run.

* Korrektur 29.09.2026: Rueckgabe, ob ueberhaupt etwas zu verarbeiten ist
*                  (alt: EXIT in START-OF-SELECTION hat das Lesen der LDB verhindert)
    CLEAR gv_m_subrc.
    select_y_data( ).
    rv_ok = xsdbool( gv_m_subrc IS INITIAL ).

  ENDMETHOD.

  METHOD select_y_data.

    "Selektion festwertetabelle
    SELECT SINGLE werk FROM yqm_0100form_t
      INTO CORRESPONDING FIELDS OF @gs_m_yq0100form
      WHERE datvon LE @sy-datum
        AND datbis GE @sy-datum.
    IF sy-subrc <> 0.
      CLEAR gs_m_yq0100form.
    ENDIF.

    WRITE: / 'YQ_LFW Schnittstelle f. Wasserwirtschaftsamt'.

    IF gv_m_uname_i IS INITIAL.
      gv_m_uname = sy-uname.
    ELSE.
      gv_m_uname = gv_m_uname_i.
    ENDIF.

    SELECT * FROM yqm_anlass_t
      INTO CORRESPONDING FIELDS OF TABLE @gt_m_zqmanlass
      WHERE kzamt = 'X'.
    IF sy-subrc <> 0.
      CLEAR gt_m_zqmanlass.
    ENDIF.

    SELECT * FROM yqm_amtsbez_t
      INTO CORRESPONDING FIELDS OF TABLE @gt_m_yqamtsbez.
    IF sy-subrc <> 0.
      CLEAR gt_m_yqamtsbez.
    ENDIF.

    SELECT kunnr, kzsebam, txtsebam
      FROM yqm_pfad_t
      INTO CORRESPONDING FIELDS OF TABLE @gt_m_zqpfad
      WHERE kzsebam = 'X'.
    IF sy-subrc <> 0.
      CLEAR gt_m_zqpfad.
    ENDIF.

    SELECT SINGLE bname, ustyp FROM usr02
      INTO @gs_m_usr02
      WHERE bname = @gv_m_uname.

    IF sy-subrc <> 0.
      CLEAR gs_m_usr02.
    ENDIF.

    IF gs_m_usr02-ustyp <> 'A'.

      CLEAR: gt_m_rng_datum, gt_m_rng_los, gt_m_rng_anl, gt_m_rng_kunnr, gt_m_rng_ext, gv_m_down.

      SELECT FROM yqm_sebam_t                 "#EC CI_ALL_FIELDS_NEEDED
        FIELDS *
        INTO TABLE @gt_m_yqsebam.
      IF sy-subrc <> 0.
        CLEAR gt_m_yqsebam.
      ENDIF.
      LOOP AT gt_m_yqsebam ASSIGNING FIELD-SYMBOL(<ls_yqsebam>).
        IF <ls_yqsebam>-quitkz = 'X'.
          IF <ls_yqsebam>-senddat IS INITIAL.
            APPEND INITIAL LINE TO gt_m_rng_los ASSIGNING FIELD-SYMBOL(<ls_rng_los>).
            <ls_rng_los>-sign       = 'I'.
            <ls_rng_los>-option     = 'EQ'.
            <ls_rng_los>-low        = <ls_yqsebam>-prueflos.
          ENDIF.
        ENDIF.
      ENDLOOP.
      DATA(lv_lines) = lines( gt_m_rng_los ).
      IF lv_lines = 0.
        WRITE: / 'keine Sätze für Batchlauf selektiert.'.
        gv_m_subrc = 4.                                     "Korrektur 29.09.2026
        EXIT.
      ENDIF.
    ENDIF.
    SORT gt_m_rng_los BY low.

  ENDMETHOD.

  METHOD set_qals.

    gs_m_qals = is_qals.

  ENDMETHOD.

  METHOD check_qals.

    DATA lv_subrc  TYPE sy-subrc.


    CHECK gs_m_qals-yqm_probedatum IN gt_m_rng_datum.
    CHECK gs_m_qals-prueflos     IN gt_m_rng_los.
    CHECK gs_m_qals-yqm_anlass     IN gt_m_rng_anl.

    CHECK gs_m_qals-yqm_kunnrzl IN gt_m_rng_kunnr.
    CHECK gs_m_qals-stat35 = 'X'.
    CLEAR lv_subrc.
    LOOP AT gt_m_rng_stat ASSIGNING FIELD-SYMBOL(<ls_rng_stat>).
      lv_subrc = chcek_status( iv_objnr = gs_m_qals-objnr
                               iv_stat  = <ls_rng_stat>-low ).
      IF lv_subrc = 0.
        EXIT.
      ENDIF.
    ENDLOOP.

    rv_subrc = lv_subrc.

  ENDMETHOD.

  METHOD chcek_status.

    rv_subrc = 9.
    CALL FUNCTION 'QAST_STATUS_CHECK'
      EXPORTING
        i_objnr          = iv_objnr
        i_status         = iv_stat
      EXCEPTIONS
        status_not_activ = 1.
    IF sy-subrc = 0.
      rv_subrc =  sy-subrc .
    ENDIF.

  ENDMETHOD.

  METHOD set_t1.

    TYPES: BEGIN OF lty_stammpruefmerkmal,
             zaehler TYPE qpmk-zaehler,
             mkmnr   TYPE qpmk-mkmnr,
             version TYPE qpmk-version,
             werks   TYPE qpmk-werks,
             dummy20 TYPE qpmk-dummy20,
           END OF lty_stammpruefmerkmal.

    DATA:
      ls_t3_fail TYPE lty_m_t3_fail,
      lv_stellen TYPE qamv-stellen,
      ls_qpmk    TYPE lty_stammpruefmerkmal,
      lt_qpmk    TYPE STANDARD TABLE OF lty_stammpruefmerkmal WITH DEFAULT KEY,
      lv_medium  TYPE yqm_medium.


    IF iv_tabname = 'QALS'.
      READ TABLE gt_m_zqmanlass TRANSPORTING NO FIELDS
        WITH KEY anlass = gs_m_qals-yqm_anlass.
      IF sy-subrc = 0.
        cs_t1-yqm_anlass = gs_m_qals-yqm_anlass.
      ELSE.
        cv_subrc = sy-subrc.
        RETURN.
      ENDIF.

      READ TABLE gt_m_zqpfad ASSIGNING FIELD-SYMBOL(<ls_pfad>)
        WITH KEY kunnr = gs_m_qals-yqm_kunnrzl.
      IF  sy-subrc = 0.
        cs_t1-kunnr  = <ls_pfad>-kunnr.
      ELSE.
        cv_subrc = sy-subrc.
        RETURN.
      ENDIF.

* Korrektur 29.09.2026: Zuweisung laeuft von rechts nach links -
*                  Probedatum muss ganz rechts stehen
      cs_t1-datum                       = gv_m_t2_datum = gs_m_qals-yqm_probedatum.
      cs_t1-probezeit                   = gs_m_qals-yqm_probezeit.
      cs_t1-prueflos                    = gs_m_qals-prueflos.
      cs_t1-ktextlos                    = gs_m_qals-ktextlos.
      cs_t1-probgew                     = gs_m_qals-yqm_probengewinnung.
      gv_m_werk                         = gs_m_qals-werk.
      cs_t1-pltxt                       = gs_m_qals-ktextmat.
    ENDIF.

    IF iv_tabname = 'QAVE'.

      set_qapp( CHANGING cs_t1 = cs_t1 ).

      SELECT SINGLE yqm_extension, yqm_betreiber, yqm_bezeichnung, tplnr, yqm_wasserwirtnr, yqm_bestellnr, yqm_wasserwirt, yqm_medium, iloan
        FROM iflot
        INTO @DATA(ls_iflot)
        WHERE tplnr = @cs_t1-tplnr.
      IF sy-subrc <> 0.
        WRITE: '227 - kein Satz', cs_t1-tplnr.
      ENDIF.
      IF ls_iflot-yqm_extension NOT IN gt_m_rng_ext.
        ls_t3_fail-text1 = 'Kunde: '.
        ls_t3_fail-sep1 = ' '.
        ls_t3_fail-text2 = 'Techn.Platz: '.
        ls_t3_fail-sep2 = ' '.
        ls_t3_fail-text3 = 'Merkmal-Nr./-Txt: '.
        ls_t3_fail-sep3 = ' '.
        ls_t3_fail-text4 = ' '.
        CONCATENATE 'ausgewählte Extension weicht ab! Technischer Platz: '
                     cs_t1-tplnr 'Extension: ' ls_iflot-yqm_extension
                     'Prüflos:' cs_t1-prueflos
                      INTO ls_t3_fail SEPARATED BY ' '.

        APPEND ls_t3_fail TO gt_m_t3_fail.
* Korrektur 29.09.2026: statt CHECK Rueckgabecode setzen, damit der
*                  Aufrufer den Satz verwerfen kann (alt: CHECK im GET)
        cv_subrc = 4.
        RETURN.
      ENDIF.
      CLEAR: cs_t1-strno, cs_t1-tplnr.
      cs_t1-betreiber         = ls_iflot-yqm_betreiber.
      cs_t1-bez               = ls_iflot-yqm_bezeichnung.
      cs_t1-strno             = ls_iflot-tplnr.
      cs_t1-tplnr             = ls_iflot-tplnr.
      cs_t1-yqm_wasserwirtnr    = ls_iflot-yqm_wasserwirtnr.
      cs_t1-yqm_bestellnr       = ls_iflot-yqm_bestellnr.
      cs_t1-yqm_wasserwirt      = ls_iflot-yqm_wasserwirt.
      cs_t1-yqm_medium          = ls_iflot-yqm_medium.
      cs_t1-yqm_extension       = ls_iflot-yqm_extension.

      APPEND INITIAL LINE TO gt_m_t2 ASSIGNING FIELD-SYMBOL(<ls_t2>).
      <ls_t2> = gs_m_qals-yqm_probedatum.

      SELECT SINGLE eqfnr FROM iloa
        INTO @DATA(lv_iloa_eqfnr)
        WHERE iloan = @ls_iflot-iloan
          AND owner = '2'.
      IF sy-subrc = 0.
        IF lv_iloa_eqfnr IS NOT INITIAL.
          cs_t1-eqfnr = lv_iloa_eqfnr.
        ELSE.
          cs_t1-eqfnr = 'EQFNR fehlt'.
        ENDIF.
      ELSE.
        cs_t1-eqfnr = 'K E I N'.
      ENDIF.

    ENDIF.

    IF iv_tabname = 'QAMV'.

      cs_t1-steuerkz = gs_m_qamv-steuerkz.
      lv_stellen     = gs_m_qamv-stellen.
      cs_t1-merknr   = gs_m_qamv-verwmerkm.

      CLEAR: ls_qpmk, lt_qpmk.
      SELECT zaehler, mkmnr, version, werks, dummy20 FROM qpmk
        INTO CORRESPONDING FIELDS OF TABLE @lt_qpmk
        WHERE mkmnr   = @cs_t1-merknr
          AND zaehler = @gv_m_werk.
      IF sy-subrc <> 0.
        CLEAR lt_qpmk.
      ENDIF.

      SORT lt_qpmk BY version DESCENDING.
      LOOP AT lt_qpmk INTO ls_qpmk.
        cs_t1-dummy20  = ls_qpmk-dummy20.
        EXIT.
      ENDLOOP.
      SELECT SINGLE kurztext FROM qpmt
        INTO @DATA(lv_qpmt_kurztext)
        WHERE zaehler = @gv_m_werk
          AND mkmnr   = @cs_t1-merknr
          AND version = @ls_qpmk-version
          AND sprache = 'D'.

      IF sy-subrc <> 0.
        CLEAR lv_qpmt_kurztext.
      ENDIF.

      cs_t1-kurztext = lv_qpmt_kurztext.

    ENDIF.

    IF iv_tabname = 'QASR'.

      cs_t1-exkuwwanpl(3)     = cs_t1-yqm_extension.
      cs_t1-exkuwwanpl+3(10)  = cs_t1-kunnr.
      cs_t1-exkuwwanpl+13(40) = cs_t1-yqm_wasserwirt.
      cs_t1-exkuwwanpl+53(5)  = cs_t1-yqm_anlass.

      IF gs_m_qals-slwbez = '910'.
        cs_t1-exkuwwanpl+58(12) = cs_t1-phynr.
      ELSE.
        cs_t1-exkuwwanpl+58(12) = cs_t1-prueflos.
      ENDIF.

      cs_t1-attribut = gs_m_qasr-attribut.
      cs_t1-mandant  = sy-mandt.

      IF cs_t1-steuerkz(1) EQ 'X'.
        IF gs_m_qasr-mittelwert IS INITIAL.
          CLEAR cs_t1-mittelwert.
          cs_t1-mittelwert(1) = '0'.
        ELSE.
          IF cs_t1-steuerkz(1) EQ 'X'.
            gv_m_fbmittelw = get_messwert( ).
          ENDIF.
          IF gv_m_fbmittelw(12) IS INITIAL.
            lv_stellen = get_stellen( ).
            WRITE gv_m_fbmittelw+12(10) TO cs_t1-mittelwert NO-GAP.
            SHIFT cs_t1-mittelwert BY lv_stellen PLACES.
          ELSE.
            cs_t1-mittelwert = 'Überlauf!!'.
            CONCATENATE 'Mittelwert zu groß: ' gv_m_fbmittelw
            INTO cs_t1-kurztext.

            ls_t3_fail-text1 = 'Kunde: '.
            ls_t3_fail-sep1 = ' '.
            ls_t3_fail-text2 = 'Techn.Platz: '.
            ls_t3_fail-sep2 = ' '.
            ls_t3_fail-text3 = 'Merkmal-Nr./-Txt: '.
            ls_t3_fail-sep3 = ' '.
            ls_t3_fail-text4 = ' '.

            ls_t3_fail-name1    = cs_t1-name1.
            ls_t3_fail-strno    = cs_t1-strno.
            ls_t3_fail-kurztext = cs_t1-kurztext.
            ls_t3_fail-merknr   = cs_t1-merknr.
            APPEND ls_t3_fail TO gt_m_t3_fail.
            gv_m_cnt_fail = gv_m_cnt_fail + 1.
          ENDIF.
        ENDIF.

      ELSE.
        CLEAR cs_t1-mittelwert.
        gv_m_fbmittelw = qualitaet( ).
        cs_t1-mittelwert = gv_m_fbmittelw.
      ENDIF.

      IF gs_m_qamv-verwmerkm = '50001311'.
        lv_medium = gs_m_qpcd-code(2).
      ENDIF.

      cs_t1-slwbez = gs_m_qals-slwbez.

      IF gs_m_qals-slwbez = '910'.
        READ TABLE gt_m_qapp INTO DATA(ls_qapp)
          WITH KEY prueflos = gs_m_qasr-prueflos
                   vorglfnr = gs_m_qasr-vorglfnr
                   probenr  = gs_m_qasr-probenr BINARY SEARCH.
        IF sy-subrc = 0.
          IF ls_qapp-userc1 IS NOT INITIAL.
            cs_t1-phynr      = ls_qapp-phynr.
          ENDIF.
        ENDIF.
        IF cs_t1-phynr IS NOT INITIAL.
          READ TABLE gt_m_qprs INTO DATA(ls_qprs)
            WITH KEY phynr = cs_t1-phynr BINARY SEARCH.
          IF sy-subrc = 0.
            cs_t1-ktextphynr   = ls_qprs-ktext.

            IF NOT ls_qprs-entdatum IS INITIAL.
              cs_t1-datum      = ls_qprs-entdatum.
            ENDIF.

            IF NOT ls_qprs-entzeit IS INITIAL.
              cs_t1-probezeit  = ls_qprs-entzeit.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSE.
        CLEAR ls_qapp.
        CLEAR ls_qprs.
      ENDIF.

      IF lv_medium IS NOT INITIAL.
        cs_t1-yqm_medium = lv_medium.
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD set_qave.

    gs_m_qave = is_qave.

  ENDMETHOD.

  METHOD set_qapp.

    IF gs_m_qals-slwbez = '910'.
*   Legionellenprüfung mit Prüfpunkten
      SELECT prueflos, vorglfnr, probenr, tplnr, phynr, userc1 FROM qapp
        INTO CORRESPONDING FIELDS OF TABLE @gt_m_qapp
        WHERE prueflos = @gs_m_qals-prueflos.

      IF sy-subrc = 0.
        SORT gt_m_qapp BY prueflos vorglfnr probenr.
        READ TABLE gt_m_qapp INTO gs_m_qapp INDEX 1.
        IF sy-subrc = 0.
          cs_t1-tplnr = gs_m_qapp-tplnr.
        ENDIF.
        LOOP AT gt_m_qapp INTO gs_m_qapp.
          gs_m_qapp-phynr = gs_m_qapp-userc1+6(12).
          MODIFY gt_m_qapp FROM gs_m_qapp.
          IF gs_m_qapp-phynr NOT IN gt_m_rng_probe.
            DELETE TABLE gt_m_qapp FROM gs_m_qapp.
          ENDIF.
        ENDLOOP.

        IF gt_m_qapp[] IS NOT INITIAL.
          SELECT ktext, phynr, entdatum, entzeit  FROM qprs
            INTO CORRESPONDING FIELDS OF TABLE @gt_m_qprs
            FOR ALL ENTRIES IN @gt_m_qapp
            WHERE phynr = @gt_m_qapp-phynr.
          IF sy-subrc = 0.
            SORT gt_m_qprs BY phynr.
          ELSE.
            CLEAR gt_m_qprs.
          ENDIF.
        ENDIF.
      ELSE.
        CLEAR gt_m_qapp.
      ENDIF.

    ELSE.
      SELECT SINGLE prueflos, vorglfnr, probenr, tplnr, phynr, userc1 FROM qapp
        INTO CORRESPONDING FIELDS OF @gs_m_qapp
             WHERE prueflos = @gs_m_qals-prueflos.
      IF sy-subrc <> 0.
        CLEAR gs_m_qapp.
      ENDIF.
      cs_t1-tplnr = gs_m_qapp-tplnr.

    ENDIF.

  ENDMETHOD.

  METHOD set_qamv.

    gs_m_qamv = is_qamv.

  ENDMETHOD.

  METHOD set_qasr.

    gs_m_qasr = is_qasr.

  ENDMETHOD.

  METHOD get_messwert.

    CALL FUNCTION 'FLTP_CHAR_CONVERSION'
      EXPORTING
        decim = gs_m_qamv-stellen
        input = gs_m_qasr-mittelwert
        ivalu = 'X'
      IMPORTING
        flstr = rv_fbmittelw.

  ENDMETHOD.

  METHOD get_stellen.

    DATA(lv_fbmittelw) = gv_m_fbmittelw+12(10).

    CLEAR rv_stellen.
    IF NOT lv_fbmittelw(1) IS INITIAL.
      rv_stellen = 0.
      EXIT.
    ENDIF.
    DO.
      IF rv_stellen < 10.
        rv_stellen = rv_stellen + 1.
      ELSE.
        EXIT.
      ENDIF.
      IF NOT lv_fbmittelw+rv_stellen(1) IS INITIAL.
        EXIT.
      ENDIF.
    ENDDO.

  ENDMETHOD.

  METHOD qualitaet.

    SELECT SINGLE * FROM qpcd
      INTO CORRESPONDING FIELDS OF @gs_m_qpcd
      WHERE katalogart = @gs_m_qasr-katalgart1
        AND codegruppe = @gs_m_qasr-gruppe1
        AND code = @gs_m_qasr-code1
        AND version = @gs_m_qasr-version1.
    IF sy-subrc <> 0.
      CLEAR gs_m_qpcd.
    ENDIF.

    SELECT SINGLE * FROM yqm_code_t
      INTO @DATA(ls_yqcode)
      WHERE code = @gs_m_qpcd-code.
    IF sy-subrc = 0.
      rv_fbmittelw = ls_yqcode-codelfw.
    ELSE.
      rv_fbmittelw = 'RC>0'.
    ENDIF.

  ENDMETHOD.

  METHOD append_t1.

    APPEND is_t1 TO gt_m_t1.

  ENDMETHOD.

  METHOD error2file.

    DATA: lv_zl(9)    TYPE n,
          lv_msg_text TYPE char80,
          lv_len      TYPE i VALUE 300.

    CHECK gv_m_cnt_fail > 0.

    SORT gt_m_t3_fail BY strno.
    WRITE gv_m_cnt_fail TO lv_zl NO-ZERO.
    OPEN DATASET gv_m_ausgabef FOR OUTPUT IN TEXT MODE ENCODING NON-UNICODE MESSAGE lv_msg_text.
    IF sy-subrc <> 0.
      MESSAGE lv_msg_text TYPE 'E'.
    ENDIF.
    DATA(lv_fail) = |{ TEXT-001 } { lv_zl }|.
    TRANSFER lv_fail TO gv_m_ausgabef.

    LOOP AT gt_m_t3_fail ASSIGNING FIELD-SYMBOL(<lt_group_t3_fail>)
      GROUP BY ( strno = <lt_group_t3_fail>-strno ).

      LOOP AT GROUP <lt_group_t3_fail> ASSIGNING FIELD-SYMBOL(<ls_t3_fail>).
        DATA(ls_fail) = <ls_t3_fail>.
        CLEAR <ls_t3_fail>.
      ENDLOOP.
      TRANSFER ls_fail TO gv_m_ausgabef LENGTH lv_len.

    ENDLOOP.

    CLOSE DATASET gv_m_ausgabef.

  ENDMETHOD.

  METHOD write_prot.

    CONSTANTS lc_tab TYPE c LENGTH 1 VALUE cl_abap_char_utilities=>horizontal_tab.

    DATA: lv_cnt_t1 TYPE i,
          lv_start  TYPE char1,
          BEGIN OF ls_p2,
            lit1(1)        VALUE 'W',
            dummy20(4),        "ersten 4 Stellen von LIKE QPMK-DUMMY20,
            qualitat       TYPE rqpas-qualitat,
            attribut       TYPE qasr-attribut,
            mittelwert(10),
          END OF ls_p2,
          lv_t1i     TYPE i,
          lv_ta1     TYPE solisti1,
          lt_tg      TYPE STANDARD TABLE OF qals-prueflos,
          ls_yqsebam TYPE yqm_sebam_t,
          lt_yqsebam TYPE STANDARD TABLE OF yqm_sebam_t.


    DATA(lv_cnt_t1_lines) = lines( gt_m_t1 ).
    IF lv_cnt_t1_lines = 0.
      WRITE: / 'Keine Sätze zur Selektion vorhanden: '.
      EXIT.
    ENDIF.

    DATA(ls_t1) = VALUE lty_m_t1( yqm_extension = 'ZZZ'
                                kunnr = 'ZZZZZZZZZZ'
                                yqm_wasserwirt = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'
                                yqm_anlass = 'ZZZZZ'
                                prueflos = '999999999999'
                                phynr = '999999999999'
                                exkuwwanpl = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ999999999999'
                                merknr = 'ZZZZZZZZ'
                                dummy20 = 'ZZZZZZZZZZZZZZZZZZZZ'
                                ).
    APPEND ls_t1 TO gt_m_t1.
    SORT gt_m_t1 BY yqm_extension kunnr yqm_wasserwirt yqm_anlass prueflos phynr dummy20.
    SORT gt_m_t2.
    READ TABLE gt_m_t2 ASSIGNING FIELD-SYMBOL(<lv_t2>) INDEX 1.

    LOOP AT gt_m_t1 ASSIGNING FIELD-SYMBOL(<ls_t1>)
      WHERE merknr NE ' '
        AND dummy20 NE ' '.

      lv_cnt_t1 = lv_cnt_t1 + 1.
      IF lv_cnt_t1 = 1.
        CLEAR ls_t1.
        ls_t1 = <ls_t1>.
        DATA(lv_exkuwwanpl) = <ls_t1>-exkuwwanpl.
        neu( EXPORTING is_t1         = <ls_t1>
             CHANGING  cv_exkuwwanpl = lv_exkuwwanpl
                       cv_start      = lv_start ).
      ENDIF.
      IF <ls_t1>-yqm_wasserwirt IS NOT INITIAL.
        IF lv_exkuwwanpl <> <ls_t1>-exkuwwanpl.
          IF lv_exkuwwanpl(58) <> <ls_t1>-exkuwwanpl(58).
            ausgabe( <ls_t1> ).
            neu( EXPORTING is_t1         = <ls_t1>
                 CHANGING  cv_exkuwwanpl = lv_exkuwwanpl
                           cv_start      = lv_start ).
          ENDIF.

          IF  lv_exkuwwanpl(58) = <ls_t1>-exkuwwanpl(58).
            IF lv_exkuwwanpl+58(12) <> <ls_t1>-exkuwwanpl+58(12).
              IF lv_cnt_t1 > 1.
                posende( ).
                poskopf( EXPORTING is_t1         = <ls_t1>
                         CHANGING  cv_start      = lv_start
                                   cv_exkuwwanpl = lv_exkuwwanpl ).
              ENDIF.
            ENDIF.
          ENDIF.
          lv_exkuwwanpl  = <ls_t1>-exkuwwanpl.
        ENDIF.
      ENDIF.

      CASE <ls_t1>-slwbez.
        WHEN '910'.
          gs_m_pe-ktextlos = <ls_t1>-ktextphynr.
        WHEN OTHERS.
          gs_m_pe-ktextlos = <ls_t1>-ktextlos.
      ENDCASE.

      IF <ls_t1>-kunnr <> 'ZZZZZZZZZZ'.

        CLEAR: ls_p2-dummy20, ls_p2-qualitat, ls_p2-attribut,
                     ls_p2-mittelwert.
        ls_p2-dummy20        = <ls_t1>-dummy20(4).
        ls_p2-qualitat       = 'X'.
        CASE <ls_t1>-attribut(1).
          WHEN '[' OR '(' OR 'U'.
            ls_p2-attribut = 'B'.
          WHEN '~'.
            ls_p2-attribut   = 'N'.
            ls_p2-mittelwert = '0'.
          WHEN '<' OR '>'.
            ls_p2-attribut       = <ls_t1>-attribut.
            CLEAR: lv_t1i.
            DO.
              IF lv_t1i > 10.
                EXIT.
              ENDIF.
              IF <ls_t1>-mittelwert <> 'Überlauf!!'.
                IF <ls_t1>-mittelwert+lv_t1i(1) IS INITIAL.
                  ls_p2-mittelwert = <ls_t1>-mittelwert .
                  CLEAR <ls_t1>-mittelwert.
                  EXIT.
                ENDIF.
              ENDIF.
              lv_t1i = lv_t1i + 1.
            ENDDO.
          WHEN OTHERS.
            CLEAR ls_p2-attribut.
            IF <ls_t1>-mittelwert <> 'Überlauf!!'.
              ls_p2-mittelwert = <ls_t1>-mittelwert .
              CLEAR <ls_t1>-mittelwert.
            ENDIF.
        ENDCASE.

        CLEAR lv_ta1.
        lv_ta1      = ls_p2-lit1.                 " 0   1
        lv_ta1+1(1) = lc_tab.                     " 1   1
        lv_ta1+2    = ls_p2-dummy20.              " 2   4
        lv_ta1+6(1) = lc_tab.                     " 6   1
        lv_ta1+7    = ls_p2-qualitat.             " 7   1
        lv_ta1+8(1) = lc_tab.                     " 8   1
        IF ls_p2-attribut IS NOT INITIAL AND ls_p2-mittelwert IS NOT INITIAL.
          lv_ta1+9     = ls_p2-attribut.          " 9   1
          lv_ta1+10(1) = lc_tab.                  " 10  1
          lv_ta1+11    = ls_p2-mittelwert.        " 11  10
        ELSEIF ls_p2-attribut IS INITIAL.
          lv_ta1+9(1)  = lc_tab.                  " 9   1  war 10  1
          lv_ta1+10    = ls_p2-mittelwert.        " 10  10 war 11  10
        ELSEIF ls_p2-mittelwert IS INITIAL.
          lv_ta1+9     = ls_p2-attribut.          " 9   1
          lv_ta1+10(1) = lc_tab.                  " 10  1
        ENDIF.
        CONDENSE lv_ta1 NO-GAPS.
* Korrektur 29.09.2026: Merkmalsergebnisse gehoeren ins Attachment (alt: ta1),
*                  nicht in den Mailbody
        APPEND lv_ta1 TO gt_m_ta1.

      ENDIF.
    ENDLOOP.

    WRITE: / 'Selektierte Prüflose: '.
    SORT gt_m_rng_los BY low.
    LOOP AT gt_m_rng_los ASSIGNING FIELD-SYMBOL(<ls_rng_los>).
      WRITE: / <ls_rng_los>-sign, <ls_rng_los>-option, <ls_rng_los>-low, <ls_rng_los>-high .
    ENDLOOP.
    SORT gt_m_t1 BY prueflos.
    WRITE: / 'Verarbeitete Prüflose: '.
    LOOP AT gt_m_t1 ASSIGNING <ls_t1>.
      READ TABLE lt_tg ASSIGNING FIELD-SYMBOL(<ls_tg>) WITH KEY table_line = <ls_t1>-prueflos.
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO lt_tg ASSIGNING <ls_tg>.
        <ls_tg> = <ls_t1>-prueflos.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_tg ASSIGNING <ls_tg>.
      WRITE: / <ls_tg>.
    ENDLOOP.

    IF gs_m_usr02-ustyp <>'A'.
      LOOP AT gt_m_rng_los ASSIGNING <ls_rng_los>.
        READ TABLE gt_m_yqsebam ASSIGNING FIELD-SYMBOL(<ls_yqsebam>) WITH KEY prueflos = <ls_rng_los>-low.
        IF sy-subrc = 0.
          CLEAR ls_yqsebam.
          <ls_yqsebam>-senddat = sy-datum.
          MOVE-CORRESPONDING <ls_yqsebam> TO ls_yqsebam.
          APPEND ls_yqsebam TO lt_yqsebam.
        ENDIF.
      ENDLOOP.

      IF lt_yqsebam IS NOT INITIAL.
        UPDATE yqm_sebam_t FROM TABLE lt_yqsebam.
        IF sy-subrc <> 0.
          gv_m_subrc = sy-subrc.
        ENDIF.
      ENDIF.

    ENDIF.

    WRITE: / 'YQ_LFW Ende'.
    CHECK gv_m_subrc IS INITIAL.

  ENDMETHOD.

  METHOD neu.

    DATA ls_empfaenger TYPE solisti1.

    cv_start = 'E'.

* Korrektur 29.09.2026: Empfaenger je Mail neu aufbauen (alt: REFRESH lt_empfaenger)
    CLEAR gt_m_empfaenger.

    DATA(lt_adr6) = mailadresse( is_t1-kunnr ).

    LOOP AT lt_adr6 ASSIGNING FIELD-SYMBOL(<ls_adr6>).
      ls_empfaenger = <ls_adr6>-smtp_addr.
* Korrektur 29.09.2026: Umleitung auf Testadresse nur im NICHT-Produktivsystem
      IF sy-sysid(1) <> 'P' AND gv_m_adr IS INITIAL.
        ls_empfaenger = gv_m_url.
      ENDIF.
      APPEND ls_empfaenger TO gt_m_empfaenger.
    ENDLOOP.

    READ TABLE gt_m_yqamtsbez ASSIGNING FIELD-SYMBOL(<ls_yqamtsbez>)
      WITH KEY wasserwirt = is_t1-yqm_wasserwirt.
    IF sy-subrc = 0 AND <ls_yqamtsbez> IS ASSIGNED.
      ls_empfaenger = <ls_yqamtsbez>-mail.
      APPEND ls_empfaenger TO gt_m_empfaenger.
    ENDIF.

    dateiopen( is_t1 ).
    kopf( is_t1 ).
    starttxt( EXPORTING is_t1         = is_t1
              CHANGING  cv_start      = cv_start
                        cv_exkuwwanpl = cv_exkuwwanpl ).
    gt_m_bemerkung = bemerkung( is_t1 ).
    anmerkung( ).


  ENDMETHOD.

  METHOD mailadresse.

    TYPES: BEGIN OF lty_kna1,
             kunnr TYPE kna1-kunnr,
             name1 TYPE kna1-name1,
             name2 TYPE kna1-name2,
             stras TYPE kna1-stras,
             pstlz TYPE kna1-pstlz,
             ort01 TYPE kna1-ort01,
             adrnr TYPE kna1-adrnr,
           END OF lty_kna1.

    DATA: ls_kna1 TYPE lty_kna1,
          ls_body TYPE solisti1.

    SELECT SINGLE kunnr, adrnr, name1, name2, pstlz, ort01, stras FROM kna1
      INTO CORRESPONDING FIELDS OF @ls_kna1
      WHERE kunnr = @iv_kunnr.
    IF sy-subrc <> 0.
      CLEAR ls_kna1.
    ENDIF.

    SELECT  addrnumber, smtp_addr, persnumber FROM adr6
      INTO CORRESPONDING FIELDS OF TABLE @rt_adr6
      WHERE addrnumber = @ls_kna1-adrnr
        AND persnumber = @space.
    IF sy-subrc <> 0.
      CLEAR rt_adr6.
    ENDIF.


    ls_body = 'Betrifft:'.
    APPEND ls_body TO gt_m_body.
    CLEAR ls_body.
    APPEND ls_body TO gt_m_body.
    ls_body-line = |{ ls_kna1-name1 } { ls_kna1-name2 }|.
    APPEND ls_body TO gt_m_body.
    CLEAR ls_body.
    ls_body = ls_kna1-stras.
    APPEND ls_body TO gt_m_body.
    CLEAR ls_body.
    APPEND ls_body TO gt_m_body.
    ls_body-line = |{ ls_kna1-pstlz } { ls_kna1-ort01 }|.
    APPEND ls_body TO gt_m_body.
    CLEAR ls_body.
    APPEND ls_body TO gt_m_body.
    APPEND ls_body TO gt_m_body.

  ENDMETHOD.

  METHOD dateiopen.

    DATA:
      lv_datzlc(5),
      lv_sebam_kunde(20),
      lv_datnam(44).

    IF gv_m_datzl > 9999.
      CLEAR gv_m_datzl.
    ENDIF.
    gv_m_datzl = gv_m_datzl + 1.
    WRITE gv_m_datzl TO lv_datzlc LEFT-JUSTIFIED.
    CLEAR: lv_sebam_kunde.

    READ TABLE gt_m_zqpfad ASSIGNING FIELD-SYMBOL(<ls_zqpfad>)
      WITH KEY kunnr = is_t1-kunnr.
    IF sy-subrc IS INITIAL AND <ls_zqpfad> IS ASSIGNED AND <ls_zqpfad>-txtsebam IS NOT INITIAL.
      lv_sebam_kunde = <ls_zqpfad>-txtsebam.
    ENDIF.

    lv_datnam = |{ lv_sebam_kunde }_{ sy-datum }_{ lv_datzlc }.{ is_t1-yqm_extension }|.
    gv_m_attach1 = lv_datnam.
    gv_m_betreff = |{ TEXT-002 }|. "Elektronische Messdatenübermittlung


  ENDMETHOD.

  METHOD kopf.

    DATA: BEGIN OF ls_lit1,
            lit1(30) VALUE '/DATENAUSTAUSCH/V2.0/ASCII/<>/',
            tab1(2)  TYPE x   VALUE '000A',
          END OF ls_lit1,
          BEGIN OF ls_lit2,
            lit2(06) VALUE '<KOPF>',
            tab1(2)  TYPE x   VALUE '000A',
          END OF ls_lit2,
          BEGIN OF ls_lit3,
            lit3(27) VALUE 'WASSER - ABWASSER - ANALYSE',
            tab1(2)  TYPE x   VALUE '000A',
          END OF ls_lit3,
          BEGIN OF ls_lit4,
            lit4(25) VALUE 'Schnittstellenversion:2.0',
            tab1(2)  TYPE x   VALUE '000A',
          END OF ls_lit4,
          BEGIN OF ls_lit5,
            lit5(28)  VALUE 'Datum des ersten Speicherns:',
            datum(10),
            tab1(2)   TYPE x   VALUE '000A',
          END OF ls_lit5,
          BEGIN OF ls_lit6,
            lit6(18)  VALUE 'Überwachungsdatum:',
            uedat(10),        " QALS-ZZPROBEDATUM,
            tab1(2)   TYPE x   VALUE '000A',
          END OF ls_lit6,
          BEGIN OF ls_lit7,
            lit7(20) VALUE 'Art der Überwachung:',
            artueb   VALUE 'E', " like qals-zzueberwachung,
            tab1(2)  TYPE x   VALUE '000A',
          END OF ls_lit7,
          BEGIN OF ls_lit8,
            lit8(23)  VALUE 'Anlaß der Untersuchung:',
            anlass(5),
            tab1(2)   TYPE x   VALUE '000A',
          END OF ls_lit8,
          BEGIN OF ls_lit9,
            lit9(34)      VALUE 'Name Betreiber/Träger/Unternehmen:',
            betreiber(62),         "      LIKE KNA1-NAME1, "35
            tab1(2)       TYPE x   VALUE '000A',
          END OF ls_lit9,
          BEGIN OF ls_litb,
            litb(12) VALUE 'Bezeichnung:',
            bez(50),           "bleibt leer
            tab1(2)  TYPE x   VALUE '000A',
          END OF ls_litb,
          BEGIN OF ls_empfname,
            empfname(10) VALUE 'Empfänger:',
            empf(50),          "LIKE IFLOT-ZZWASSERWIRT,
            tab1(2)      TYPE x   VALUE '000A',
          END OF ls_empfname,
          BEGIN OF ls_abs,
            abs(9)      VALUE  'Absender:',
            absname(56) VALUE  'N-ERGIE Aktiengesellschaft, 90338 Nürnberg ',
            tab1(2)     TYPE x   VALUE '000A',
          END OF ls_abs,
          BEGIN OF ls_lablit,
            lablit(14) VALUE 'Labor - ID:52 ',
            tab1(2)    TYPE x   VALUE '000A',
          END OF ls_lablit,
          BEGIN OF ls_labidname,
            labidname(52) VALUE 'Laborname: Labor der N-ERGIE Aktiengesellschaft ',
            tab1(2)       TYPE x   VALUE '000A',
          END OF ls_labidname,
          BEGIN OF ls_betr1,
            betr1(50),       "VALUE 'Betreff:Probenahmeprotokoll für WVA',
            betr(50),
            tab1(2)   TYPE x   VALUE '000A',
          END OF ls_betr1,
          BEGIN OF ls_betr2,
            betr2(30) VALUE 'Art des überwachten Objekts:',
            ueobj(30),
            tab1(2)   TYPE x   VALUE '000A',
          END OF ls_betr2,
          BEGIN OF ls_lito,
            lito(29)  VALUE 'Übergeordnete Objektkennzahl:',
            objkz(13),         "bleibt leer
            tab1(2)   TYPE x   VALUE '000A',
          END OF ls_lito,
          BEGIN OF ls_kopfende,
            kopfende(10) VALUE '<KOPFENDE>',
            tab1(2)      TYPE x   VALUE '000A',
          END OF ls_kopfende,
          lv_ta1 TYPE solisti1.

    CLEAR gv_m_zzwasserwirt.

    READ TABLE gt_m_yqamtsbez ASSIGNING FIELD-SYMBOL(<ls_yqamtsbez>)
      WITH KEY wasserwirt = is_t1-yqm_wasserwirt.
    IF sy-subrc IS INITIAL AND <ls_yqamtsbez> IS ASSIGNED.
      gv_m_zzwasserwirt = <ls_yqamtsbez>-amtsname.
    ENDIF.
    IF gv_m_zzwasserwirt IS INITIAL.
      gv_m_zzwasserwirt = is_t1-yqm_wasserwirt.
    ENDIF.

    ls_lit5-datum = datum( sy-datum ).

* Korrektur 29.09.2026: Zugriff auf <ls_t1> nur bei erfolgreichem READ
    READ TABLE gt_m_t1 ASSIGNING FIELD-SYMBOL(<ls_t1>)
      WITH KEY prueflos = is_t1-prueflos.
    IF sy-subrc IS INITIAL AND <ls_t1> IS ASSIGNED.
      gv_m_t2_datum = <ls_t1>-datum.
      ls_lit6-uedat = datum( <ls_t1>-datum ).
    ELSE.
      ls_lit6-uedat = datum( is_t1-datum ).
    ENDIF.

    ls_lit9-betreiber = is_t1-betreiber.
    ls_litb-bez       = is_t1-bez.
    ls_empfname-empf  = gv_m_zzwasserwirt.

    lv_ta1 = ls_lit1-lit1.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1 = ls_lit2-lit2.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1 = ls_lit3-lit3.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1 = ls_lit4-lit4.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1-line = |{ ls_lit5-lit5 }{ ls_lit5-datum }|.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1-line = |{ ls_lit6-lit6 }{ ls_lit6-uedat }|.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1-line = |{ ls_lit7-lit7 }{ ls_lit7-artueb }|.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    ls_lit8-anlass = is_t1-yqm_anlass.
    IF gv_m_low IS NOT INITIAL.
      TRANSLATE ls_lit8-anlass TO LOWER CASE.
    ENDIF.
    lv_ta1-line = |{ ls_lit8-lit8 }{ ls_lit8-anlass }|.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1-line = |{ ls_lit9-lit9 }{ ls_lit9-betreiber }|.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1-line = |{ ls_abs-abs }{ ls_abs-absname }|.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1 = ls_lablit-lablit.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1 = ls_labidname-labidname.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1-line = |{ ls_empfname-empfname }{ ls_empfname-empf }|.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    READ TABLE gt_m_zqmanlass ASSIGNING FIELD-SYMBOL(<ls_zqmanlass>)
      WITH KEY anlass = is_t1-yqm_anlass.
    IF sy-subrc IS INITIAL AND <ls_zqmanlass> IS ASSIGNED.
      ls_betr1-betr1 = |Betreff:{ <ls_zqmanlass>-anlass_txt }|.
    ELSE.
      ls_betr1-betr1 = |{ TEXT-003 }|. "|Betreff:Probenahmeprotokoll für WVA|.
    ENDIF.
    lv_ta1-line = |{ ls_betr1-betr1 }{ ls_betr1-betr }|.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    CASE is_t1-slwbez.
      WHEN '910'.
        ls_betr2-ueobj = |{ TEXT-004 }|. "|Sonstiges|.
        lv_ta1-line = |{ ls_betr2-betr2 }{ ls_betr2-ueobj }|.
        APPEND lv_ta1 TO gt_m_ta1.
        CLEAR lv_ta1.

        ls_lito-objkz = is_t1-yqm_bestellnr.
        lv_ta1-line = |{ ls_lito-lito }{ ls_lito-objkz }|.
        APPEND lv_ta1 TO gt_m_ta1.
        CLEAR lv_ta1.

      WHEN OTHERS.
        ls_betr2-ueobj = is_t1-yqm_extension.
        lv_ta1-line = |{ ls_betr2-betr2 }{ ls_betr2-ueobj }|.
        APPEND lv_ta1 TO gt_m_ta1.
        CLEAR lv_ta1.

        lv_ta1 = ls_lito-lito.
        APPEND lv_ta1 TO gt_m_ta1.
        CLEAR lv_ta1.

    ENDCASE.

    lv_ta1-line = |{ ls_litb-litb }{ ls_litb-bez }|.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    lv_ta1 = ls_kopfende-kopfende.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

  ENDMETHOD.

  METHOD datum.

    rv_datum(2)     = iv_dats+6(2).
    rv_datum+2(1)   = '.'.
    rv_datum+3(2)   = iv_dats+4(2).
    rv_datum+5(1)   = '.'.
    rv_datum+6(4)   = iv_dats(4).

  ENDMETHOD.

  METHOD starttxt.

    DATA: BEGIN OF ls_daten,
            daten(55) VALUE '<DATEI:DATEN:ASC::Daten der Probenahmen und Analysen>',
            tab1(2)   TYPE x   VALUE '000A',
          END OF ls_daten,
          lv_ta1 TYPE solisti1.

    lv_ta1 = ls_daten-daten.
    APPEND lv_ta1 TO gt_m_ta1.
    CLEAR lv_ta1.

    poskopf( EXPORTING is_t1         = is_t1
             CHANGING  cv_start      = cv_start
                       cv_exkuwwanpl = cv_exkuwwanpl ).

  ENDMETHOD.

  METHOD poskopf.

    CONSTANTS lc_tab TYPE c LENGTH 1 VALUE cl_abap_char_utilities=>horizontal_tab.

    DATA: BEGIN OF ls_p1,
            sa(1)              VALUE 'P',
            prueflos(30),      " LIKE QALS-PRUEFLOS
            medium(2),         " LIKE IFLOT-ZZMEDIUM
            zzprobedatum(10),  " LIKE QALS-ZZPROBEDATUM
            probezeit(5),      " LIKE QALS-ZZPROBEZEIT
            probgew            VALUE 'A',
            zzwasserwirtnr(13),  " LIKE IFLO-ZZWASSERWIRTNR
            pltxt(50),         " LIKE IFLO-PLTXT
            eqfnr(50),         " LIKE ILOA-EQFNR
          END OF ls_p1,
          lv_prueflos TYPE qals-prueflos,
          lv_ta1      TYPE solisti1,
          lv_pos      TYPE i,
          lv_len      TYPE i.

    IF is_t1-kunnr <> 'ZZZZZZZZZZ'.
      ls_p1-prueflos = is_t1-prueflos.
      lv_prueflos = is_t1-prueflos.
      APPEND lv_prueflos TO gt_m_prueflos.
      ls_p1-medium = is_t1-yqm_medium.
      ls_p1-zzprobedatum = datum( is_t1-datum ).
      ls_p1-probezeit = |{ is_t1-probezeit+2(2) }:{ is_t1-probezeit(2) }|.
      IF is_t1-probgew IS NOT INITIAL.
        ls_p1-probgew = is_t1-probgew.
      ELSE.
        ls_p1-probgew = 'A'.
      ENDIF.
      ls_p1-zzwasserwirtnr = is_t1-yqm_wasserwirtnr.
      ls_p1-pltxt = is_t1-pltxt.
      ls_p1-eqfnr = is_t1-eqfnr.

      " Satzart + TAB
      lv_ta1 = ls_p1-sa.
      lv_ta1+1(1) = lc_tab.

      " Prüflos bzw. Phys. Probennummer (feste Länge)   2 / 30
      IF is_t1-phynr IS NOT INITIAL.
        lv_ta1+2 = is_t1-phynr.
        DESCRIBE FIELD is_t1-phynr LENGTH lv_len IN CHARACTER MODE.
      ELSE.
        lv_ta1+2 = ls_p1-prueflos.
        DESCRIBE FIELD is_t1-prueflos LENGTH lv_len IN CHARACTER MODE.
      ENDIF.
      lv_pos = lv_len + 2.
      lv_ta1+lv_pos(1) = lc_tab.
      lv_pos = lv_pos + 1.

      " Medium                                            33 / 2
      lv_ta1+lv_pos = ls_p1-medium.
      lv_pos = lv_pos + 2.
      lv_ta1+lv_pos(1) = lc_tab.
      lv_pos = lv_pos + 1.

      " Probedatum                                        36 / 10
      lv_ta1+lv_pos = ls_p1-zzprobedatum.
      lv_pos = lv_pos + 10.
      lv_ta1+lv_pos(1) = lc_tab.
      lv_pos = lv_pos + 1.

      " Probezeit                                         47 / 5
      lv_ta1+lv_pos = ls_p1-probezeit.
      lv_pos = lv_pos + 5.
      lv_ta1+lv_pos(1) = lc_tab.
      lv_pos = lv_pos + 1.

      " Probengewinnung                                   53 / 1
      lv_ta1+lv_pos = ls_p1-probgew.
      lv_pos = lv_pos + 1.
      lv_ta1+lv_pos(1) = lc_tab.
      lv_pos = lv_pos + 1.

      " Wasserwirtschaftsnummer (feste Länge)             55 / 13
      lv_ta1+lv_pos = ls_p1-zzwasserwirtnr.
      DESCRIBE FIELD ls_p1-zzwasserwirtnr LENGTH lv_len IN CHARACTER MODE.
      lv_pos = lv_pos + lv_len.
      lv_ta1+lv_pos(1) = lc_tab.
      lv_pos = lv_pos + 1.

      " Bezeichnung Techn. Platz (variable Länge)         69 / 50
      lv_ta1+lv_pos = ls_p1-pltxt.
      lv_pos = lv_pos + strlen( ls_p1-pltxt ).
      lv_ta1+lv_pos(1) = lc_tab.
      lv_pos = lv_pos + 1.

      " Sortierfeld                                      120 / 50
      lv_ta1+lv_pos = ls_p1-eqfnr.

      APPEND lv_ta1 TO gt_m_ta1.
      CLEAR lv_ta1.
    ENDIF.

    cv_exkuwwanpl+58(12) = is_t1-exkuwwanpl+58(12).
    CLEAR cv_start.

  ENDMETHOD.

  METHOD bemerkung.

    DATA:
      lv_name  TYPE thead-tdname,
      lt_lines TYPE tlinet.

    CLEAR rt_bemerkung.

    CASE is_t1-slwbez.
      WHEN '910'.

        lv_name = |{ sy-mandt }{ is_t1-prueflos }L|.

        CALL FUNCTION 'READ_TEXT'
          EXPORTING
            id                      = 'QAVE'
            language                = sy-langu
            name                    = lv_name
            object                  = 'QPRUEFLOS'
          TABLES
            lines                   = lt_lines
          EXCEPTIONS
            id                      = 1
            language                = 2
            name                    = 3
            not_found               = 4
            object                  = 5
            reference_check         = 6
            wrong_access_to_archive = 7
            OTHERS                  = 8.
        IF sy-subrc = 0.
*     erstmal die eingefügten Text aus dem VE entfernen
*     Format in SAPScript FixZeile
*     Dieses Format kommt nur vor bei einem automatischen Verwendungs-
*     entscheid. Bei normaler Gutachtenverarbeitung werden diese
*     gesperrten Texte nicht eingefügt. Aber es ist auch möglich den
*     Status GUTE nachträglich, d.h. nach dem VE zu setzen.
          LOOP AT lt_lines TRANSPORTING NO FIELDS WHERE tdformat(1) = '>'.
            DELETE lt_lines INDEX sy-tabix.
          ENDLOOP.

          CALL FUNCTION 'FORMAT_TEXTLINES'
            EXPORTING
              formatwidth = 70
            TABLES
              lines       = lt_lines
            EXCEPTIONS
              bound_error = 1
              OTHERS      = 2.
          IF sy-subrc <> 0.
            CLEAR lt_lines.
          ENDIF.
        ENDIF.

      WHEN OTHERS.
    ENDCASE.

    rt_bemerkung[] = lt_lines[].

  ENDMETHOD.

  METHOD anmerkung.

    DATA ls_body  TYPE solisti1.

    ls_body = 'Hinweise: '.
    APPEND ls_body TO gt_m_body.
    CLEAR ls_body.

    ls_body-line =  'Dieses Mail wurde maschinell erstellt.'.
    APPEND ls_body TO gt_m_body.
    CLEAR ls_body.

    ls_body-line = |{ TEXT-005 }|."|Bei Fragen wenden Sie sich bitte an folgende Adresse:|.
    APPEND ls_body TO gt_m_body.
    CLEAR ls_body.

    leer( 2 ).

    LOOP AT gt_m_rng_txt ASSIGNING FIELD-SYMBOL(<ls_txt>).
      ls_body = <ls_txt>-low.
      APPEND ls_body TO gt_m_body.
      CLEAR ls_body.
    ENDLOOP.

    leer( 3 ).

  ENDMETHOD.

  METHOD leer.

    DATA ls_body  TYPE solisti1.

    ls_body = ' '.
    DO iv_times TIMES.
      APPEND ls_body TO gt_m_body.
    ENDDO.
    CLEAR ls_body.

  ENDMETHOD.

  METHOD ausgabe.

    endtext( ).
    ende( ).
    IF gv_m_down IS NOT INITIAL.
      pfad( ).
      EXIT.
    ENDIF.

    leer( 3 ).
    signature( ).
    callmail( is_t1 ).

  ENDMETHOD.

  METHOD endtext.

    DATA:
      lv_pos  TYPE i,
      lv_len  TYPE i,
      ls_body TYPE solisti1,
      BEGIN OF ls_bemerkung,
        bemerkung(55) VALUE '<DATEI:BEMERKUNG:ASC::Beurteilung des Gesamtbefundes>',
        tab1(2)       TYPE x   VALUE '000D',
      END OF ls_bemerkung.

    FIELD-SYMBOLS <lv_tab> TYPE any.

    posende( ).
    CLEAR ls_body.
    ls_body = ls_bemerkung-bemerkung.
    APPEND ls_body TO gt_m_ta1.

    LOOP AT gt_m_bemerkung ASSIGNING FIELD-SYMBOL(<ls_bemerkung>).
      CLEAR lv_pos.
      CLEAR lv_len.
      CLEAR ls_body.
      ls_body = <ls_bemerkung>-tdline.
      lv_len = strlen( <ls_bemerkung>-tdline ).
      lv_pos = lv_len.
      ASSIGN ls_body+lv_pos(1) TO <lv_tab> CASTING TYPE x.
      <lv_tab> = ls_bemerkung-tab1.
      APPEND ls_body TO gt_m_ta1.
    ENDLOOP.
    CLEAR ls_body.


  ENDMETHOD.

  METHOD posende.

    DATA ls_body TYPE solisti1.

    ls_body      = gs_m_pe-lit1.                               " 0   1
    ls_body+1(1) = cl_abap_char_utilities=>horizontal_tab.     " 1   1
    ls_body+2    = gs_m_pe-ktextlos.                           " 2   40
    APPEND ls_body TO gt_m_ta1.

  ENDMETHOD.

  METHOD ende.

    DATA:
      ls_body TYPE solisti1,
      BEGIN OF ls_ende,
        ende(25) VALUE '<Ende DATENAUSTAUSCH >',
        tab1(2)  TYPE x   VALUE '000A',
      END OF ls_ende.

    CLEAR ls_body.
    ls_body = ls_ende-ende.
    APPEND ls_body TO gt_m_ta1.
    CLEAR ls_body.

  ENDMETHOD.

  METHOD pfad.

    DATA lv_dl TYPE string.

    lv_dl = |{ gv_m_pfad }{ gv_m_attach1 }|.
    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        filename                = lv_dl
        filetype                = 'ASC'
        write_field_separator   = 'X'
        trunc_trailing_blanks   = 'X'
        write_lf                = 'X'
        dat_mode                = 'X'
      TABLES
        data_tab                = gt_m_ta1
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21.

    IF sy-subrc <> 0.
      CLEAR gt_m_ta1.
    ENDIF.
    CLEAR gt_m_ta1.

  ENDMETHOD.

  METHOD signature.

    DATA ls_body TYPE solisti1.

    IF gs_m_yq0100form-werk = '1102'.
      ls_body =  'N-ERGIE Netz GmbH'.
    ELSE.
      ls_body =  'N-ERGIE Service GmbH'.
    ENDIF.
    APPEND ls_body TO gt_m_body.
    ls_body = 'Postanschrift: 90338 Nürnberg'.
    APPEND ls_body TO gt_m_body.
    IF gs_m_yq0100form-werk = '1102'.
      ls_body = 'Hausanschrift: Sandreuthstr. 21, 90441 Nürnberg'.
    ELSE.
      ls_body = 'Hausanschrift: Am Plärrer 43, 90429 Nürnberg'.
    ENDIF.
    APPEND ls_body TO gt_m_body.
* Gme 14.10.22 Korrektur Fusszeile
    ls_body = 'Geschäftsführer: Dr. Peter Wolffram'.
    APPEND ls_body TO gt_m_body.
    ls_body = 'Sitz der Gesellschaft: Nürnberg'.
    APPEND ls_body TO gt_m_body.
    ls_body = 'Eingetragen beim Amtsgericht Nürnberg unter HR B 23081'.
    APPEND ls_body TO gt_m_body.

  ENDMETHOD.

  METHOD callmail.

    DATA:
      ls_docdata TYPE sodocchgi1,
      lt_objtxt  TYPE STANDARD TABLE OF solisti1,
      ls_objtxt  TYPE solisti1,
      ls_objpack TYPE sopcklsti1,
      lt_objpack TYPE STANDARD TABLE OF sopcklsti1,
      lv_i       TYPE i,
      lt_hex     TYPE STANDARD TABLE OF solix,
      ls_reclist TYPE somlreci1,
      lt_reclist TYPE STANDARD TABLE OF somlreci1,
      lt_objhead TYPE STANDARD TABLE OF solisti1,
      ls_objhead TYPE solisti1.


    WRITE: 'callmail'.
    WRITE: / 'Prüflose'.
    SORT gt_m_prueflos .
    LOOP AT gt_m_prueflos ASSIGNING FIELD-SYMBOL(<ls_prueflos>).
      WRITE: / <ls_prueflos>.
    ENDLOOP.
    CLEAR: gt_m_prueflos.
    WRITE: / 'Prüflose - Ende'.

    WRITE: / is_t1-kunnr, gv_m_zzwasserwirt, 'Kunde, Amt'.
    WRITE: / gv_m_betreff, 'Betreff'.

    ls_docdata-obj_descr = gv_m_betreff.
    lt_objtxt = gt_m_body.
    DATA(lv_cnt_body_lines) = lines( gt_m_body ).
    READ TABLE gt_m_body INTO ls_objtxt INDEX lv_cnt_body_lines.
    ls_docdata-doc_size   = ( lv_cnt_body_lines - 1 ) * 255 + strlen( ls_objtxt ).

    ls_objpack-transf_bin = ' '.
    ls_objpack-head_start = 1.
    ls_objpack-head_num   = 0.
    ls_objpack-body_start = 1.
    ls_objpack-body_num   = lv_cnt_body_lines.
    ls_objpack-doc_type   = 'RAW'.
    ls_objpack-doc_size   = ls_docdata-doc_size.
    APPEND ls_objpack TO lt_objpack.


    CALL FUNCTION 'SCMS_TEXT_TO_BINARY'
      EXPORTING
        encoding      = '1100'
      IMPORTING
        output_length = lv_i
      TABLES
        text_tab      = gt_m_ta1
        binary_tab    = lt_hex
      EXCEPTIONS
        failed        = 1
        OTHERS        = 2.
    IF sy-subrc <> 0.
      WRITE: / 'convert - Fehler:'.
      CASE sy-subrc.
        WHEN 1. WRITE: 'SCMS_TEXT_TO_BINARY -  FAILED'.
        WHEN 2. WRITE: 'SCMS_TEXT_TO_BINARY -  OTHERS'.
      ENDCASE.
    ENDIF.


    DATA(lv_cnt_tab_lines) = lines( lt_hex ).
    ls_docdata-doc_size   = lv_i.
*
    ls_objpack-transf_bin = 'X'.
    ls_objpack-head_start = 1.
    ls_objpack-head_num   = 1.
    ls_objpack-body_start = 1.
    ls_objpack-body_num   = lv_cnt_tab_lines.
    ls_objpack-doc_type   = 'BIN'.    " Datei vom Typ WVA wird abgelegt und ist mit Editor zu öffnen
    ls_objpack-doc_size   = ls_docdata-doc_size.
    ls_objpack-obj_name   = gv_m_attach1.
    ls_objpack-obj_descr  = gv_m_attach1.
    APPEND ls_objpack TO lt_objpack.

* Create receiver list
    CLEAR ls_reclist.
    LOOP AT gt_m_empfaenger ASSIGNING FIELD-SYMBOL(<ls_empfaenger>).
      ls_reclist-receiver = <ls_empfaenger>.
      ls_reclist-rec_type = 'U'.
      APPEND ls_reclist TO lt_reclist.
    ENDLOOP.

* Daten
    ls_objhead = gv_m_attach1.
    APPEND ls_objhead TO lt_objhead.

* Send Message
    CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
      EXPORTING
        document_data              = ls_docdata
        put_in_outbox              = 'X'
        commit_work                = 'X'
      TABLES
        packing_list               = lt_objpack
        object_header              = lt_objhead
        contents_txt               = lt_objtxt
        contents_hex               = lt_hex
        receivers                  = lt_reclist
      EXCEPTIONS
        too_many_receivers         = 1
        document_not_sent          = 2
        document_type_not_exist    = 3
        operation_no_authorization = 4
        parameter_error            = 5
        x_error                    = 6
        enqueue_error              = 7
        OTHERS                     = 8.
    IF sy-subrc NE 0.
      WRITE: 'callmail - Fehler:'.
      CASE sy-subrc.
        WHEN 1. WRITE: 'too_many_receivers'.
        WHEN 2. WRITE: 'document_not_sent'.
        WHEN 3. WRITE: 'document_type_not_exist'.
        WHEN 4. WRITE: 'operation_no_authorization'.
        WHEN 5. WRITE: 'parameter_error'.
        WHEN 6. WRITE: 'x_error'.
        WHEN 7. WRITE: 'enqueue_error '.
        WHEN 8. WRITE: 'OTHERS'.
      ENDCASE.
    ELSE.
      WRITE: / 'callmail - Ende'.
    ENDIF.
    CLEAR: gv_m_attach1, gt_m_ta1.
    CLEAR gt_m_body.

  ENDMETHOD.

ENDCLASS.
