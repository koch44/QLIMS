FUNCTION y_qmlims_qapp_cust_samples_cre.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_QALS) TYPE  QALS
*"  TABLES
*"      QPPSV_TAB TYPE  YQM_TT_QPPSV_TAB
*"----------------------------------------------------------------------

  CONSTANTS lc_entnahme TYPE qprs-prtyp VALUE '1'.

  DATA:
    lv_tdname          TYPE thead-tdname,
    lv_ktext           TYPE qprs-ktext,
    lv_tp_spez         TYPE flag,
    lv_probenahmeart   TYPE yqm_probenahmeart,
    lv_lines           TYPE sy-tfill,
    lv_infeort         TYPE qprsinfeort,
    lv_prziehverf      TYPE qprvpt-prziehverf,
    lv_bearbeiter      TYPE qprsbearbeiter,
    lv_probenehmer03   TYPE yqm_probenehmer03,
    lv_probenahmedatum TYPE yqm_probenahmedatum,
    lv_probenahmezeit  TYPE yqm_probenahmezeit,
    lv_probenanzahl    TYPE qpranz1,
    lv_hv_probenanzahl TYPE qpranz1,
    lv_cuobj           TYPE vbap-cuobj,
    lv_field_pnart     TYPE char32.

  DATA:
    ls_lines        TYPE tline,
    ls_qppsv        TYPE yqm_qppsv,
    ls_qprn         TYPE qprn,
    ls_qprs         TYPE qprs,
    ls_qprvp        TYPE qprvp,
    ls_dynp_entorte TYPE yqm_dynpro_entorte.

  DATA:
    lt_lines        TYPE STANDARD TABLE OF tline,
    lt_qppsv        TYPE yqm_tt_qppsv_tab,
    lt_qprs         TYPE STANDARD TABLE OF qprs,
    lt_qprvp        TYPE STANDARD TABLE OF qprvp,
    lt_dynp_entorte TYPE STANDARD TABLE OF yqm_dynpro_entorte.

  DATA: BEGIN OF ls_ltextkey,
          mandt      TYPE qprvpt-mandt,
          prziehverf TYPE qprvpt-prziehverf,
          version    TYPE qprvpt-version,
          posnrprzv  TYPE qprvpt-posnrprzv,
        END OF ls_ltextkey.

  FIELD-SYMBOLS <lv_pn_art> TYPE any.

  CHECK i_qals-slwbez = '910'.

  READ TABLE qppsv_tab INTO ls_qppsv INDEX 1.

*  SELECT SINGLE cuobj
*    FROM vbap
*    INTO @lv_cuobj
*    WHERE vbeln = @i_qals-kdauf
*      AND posnr = @i_qals-kdpos
*      AND cuobj <> '0'.

*  IF sy-subrc = 0.
  IF NOT i_qals-yqm_cuobj IS INITIAL.
    lv_cuobj = i_qals-yqm_cuobj.
    CALL FUNCTION 'Y_QMLIMS_SERVICE_GET_CONF_VALS'
      EXPORTING
        i_cuobj                   = lv_cuobj
      IMPORTING
        ev_probenahmeanweisung    = lv_prziehverf
        ev_probenehmer03          = lv_probenehmer03
*       ev_probenehmer40          = lv_probenehmer40
        ev_probenahmedatum        = lv_probenahmedatum
        ev_probenahmezeit         = lv_probenahmezeit
        ev_probenanzahl           = lv_probenanzahl
        ev_tp_spez_probenahmeorte = lv_tp_spez.

    lv_bearbeiter = lv_probenehmer03.
  ENDIF.

  IF lv_prziehverf IS INITIAL.
    lv_prziehverf = 'LEG-STD'.
  ENDIF.

* Sollen die Probenahmeorte zum Technischen Platz
* aus Tabelle yqm_qprv_tplnr ermittelt werden?
  IF lv_prziehverf = 'LEG-STD'
     AND lv_tp_spez = 'X'.

* Tabelle aus Memory des Programms ZQ03_PROBEANLIEF holen
    IMPORT gt_dynp_entorte TO lt_dynp_entorte
      FROM MEMORY ID 'YQM_QAPP'.

    IF sy-subrc <> 0
       OR lt_dynp_entorte IS INITIAL.

      lv_probenahmeart = i_qals-yqm_probenahmeart.

      SELECT *
        FROM yqm_qprv_tplnr_t
        INTO CORRESPONDING FIELDS OF TABLE @lt_dynp_entorte
        WHERE tplnr = @i_qals-yqm_tplnr.

      IF sy-subrc = 0.
        IF lv_probenahmeart IS NOT INITIAL.
*          CONCATENATE 'LS_QPRV_TPLNR-PN_ART_'
*                      lv_probenahmeart
*                 INTO lv_field_pnart.

          CONCATENATE 'PN_ART_'
                      lv_probenahmeart
                 INTO lv_field_pnart.

          LOOP AT lt_dynp_entorte INTO ls_dynp_entorte.
            ASSIGN COMPONENT lv_field_pnart OF STRUCTURE ls_dynp_entorte TO <lv_pn_art>.
            IF <lv_pn_art> IS ASSIGNED.
              IF <lv_pn_art> <> 'X'.
                DELETE lt_dynp_entorte.
              ENDIF.
            ENDIF.
          ENDLOOP.
        ENDIF.

        lv_probenanzahl = lines( lt_dynp_entorte ).
        SORT lt_dynp_entorte BY lfdnr.
      ELSE.
        CLEAR lt_dynp_entorte.
      ENDIF.
    ENDIF.
  ENDIF.

* Vorbereitung der Probenahme
  CALL FUNCTION 'QPRS_SAMPLE_DRAW_CREATE'
    EXPORTING
      i_qals         = i_qals
    IMPORTING
      e_qprn         = ls_qprn
    EXCEPTIONS
      no_sample_type = 1.

  IF sy-subrc <> 0.
    MESSAGE e021(yqmlims) WITH lv_prziehverf.
  ENDIF.

  CALL FUNCTION 'QDTA_SAMP_DRAWING_POS_READ'
    EXPORTING
      i_probenahmeverf = lv_prziehverf
      i_version        = '000001'
    TABLES
      qprvptab         = lt_qprvp
    EXCEPTIONS
      not_found        = 1
      OTHERS           = 2.

  IF sy-subrc = 0.
    lv_lines = lines( lt_qprvp ).

* Auch bei Legionellenprüfungen kann die Probenanzahl < 3 sein
* Deswegen werden nur soviele Positionen im Probenahmeverfahren
* berücksichtigt, wie Proben angelegt werden sollen
    IF lv_prziehverf = 'LEG-STD'
       AND lv_probenanzahl IS NOT INITIAL
       AND lines( lt_qprvp ) > lv_probenanzahl.
      DELETE lt_qprvp FROM lv_probenanzahl + 1 TO lines( lt_qprvp ).
    ENDIF.

    READ TABLE lt_qprvp INTO ls_qprvp INDEX 1.
    IF sy-subrc <> 0.
      CLEAR ls_qprvp.
      RETURN. " oder Fehlerbehandlung
    ENDIF.

    IF lt_dynp_entorte IS NOT INITIAL.

      IF lv_probenanzahl IS NOT INITIAL.
        lv_hv_probenanzahl = lv_probenanzahl.
      ELSE.
        lv_hv_probenanzahl = lines( lt_dynp_entorte ).
      ENDIF.

      DO lv_hv_probenanzahl TIMES.

        READ TABLE lt_dynp_entorte INTO ls_dynp_entorte INDEX sy-index.
        IF sy-subrc <> 0.
          CLEAR ls_dynp_entorte.
        ENDIF.

        IF ls_dynp_entorte-pntime IS INITIAL
           AND lv_probenahmezeit IS NOT INITIAL.
          ls_dynp_entorte-pntime = lv_probenahmezeit.
        ENDIF.

        CALL FUNCTION 'QPRS_MASTER_SAMPLE_CREATE'
          EXPORTING
            i_pn_nr          = ls_qprn-pn_nr
            i_prtyp          = lc_entnahme
            i_gbtyp          = ls_qprvp-gebinde1
            i_menge          = '1'
            i_meinh          = 'ST'
            i_pnver          = ls_qprvp-prziehverf
            i_pnvev          = ls_qprvp-version
            i_pnpos          = ls_qprvp-posnrprzv
            i_gebeh          = ls_qprvp-losgebeh
            i_tpbis          = ls_qprvp-probnrpl
            i_ktext          = ls_dynp_entorte-ktext
            i_entort         = ls_qppsv-ip-tplnr
            i_infeort        = ls_dynp_entorte-infeort
            i_bearbeiter     = lv_bearbeiter
            i_entdatum       = lv_probenahmedatum
            i_entzeit        = ls_dynp_entorte-pntime
            i_test           = space
            i_kzmanu         = space
          IMPORTING
            e_qprs           = ls_qprs
          EXCEPTIONS
            no_authorization = 1
            OTHERS           = 2.
        IF sy-subrc = 0.
          APPEND ls_qprs TO lt_qprs.
        ENDIF.
      ENDDO.

    ELSE.

      LOOP AT lt_qprvp INTO ls_qprvp.

        lv_hv_probenanzahl = lv_probenanzahl.

        IF sy-tabix = lv_lines.
          IF lv_prziehverf CS 'STD'
             AND lv_probenanzahl IS NOT INITIAL.

            IF lv_hv_probenanzahl >= lv_lines + 1.
              lv_hv_probenanzahl = lv_hv_probenanzahl - lv_lines + 1.
            ELSE.
              lv_hv_probenanzahl = '1'.
            ENDIF.
          ELSE.
            lv_hv_probenanzahl = '1'.
          ENDIF.
        ELSE.
          lv_hv_probenanzahl = '1'.
        ENDIF.

        MOVE-CORRESPONDING ls_qprvp TO ls_ltextkey.
        lv_tdname = ls_ltextkey.

        CALL FUNCTION 'READ_TEXT'
          EXPORTING
            id                      = 'QPVP'
            language                = sy-langu
            name                    = lv_tdname
            object                  = 'QPRV'
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
          READ TABLE lt_lines INTO ls_lines INDEX 1.
          lv_ktext   = ls_lines-tdline.
          lv_infeort = ls_lines-tdline.
        ELSE.
          CLEAR: lv_ktext,
                 lv_infeort,
                 ls_lines.
        ENDIF.

        DO lv_hv_probenanzahl TIMES.

          CALL FUNCTION 'QPRS_MASTER_SAMPLE_CREATE'
            EXPORTING
              i_pn_nr          = ls_qprn-pn_nr
              i_prtyp          = lc_entnahme
              i_gbtyp          = ls_qprvp-gebinde1
              i_menge          = '1'
              i_meinh          = 'ST'
              i_pnver          = ls_qprvp-prziehverf
              i_pnvev          = ls_qprvp-version
              i_pnpos          = ls_qprvp-posnrprzv
              i_gebeh          = ls_qprvp-losgebeh
              i_tpbis          = ls_qprvp-probnrpl
              i_ktext          = lv_ktext
              i_entort         = ls_qppsv-ip-tplnr
              i_infeort        = lv_infeort
              i_bearbeiter     = lv_bearbeiter
              i_entdatum       = lv_probenahmedatum
              i_test           = space
              i_kzmanu         = space
            IMPORTING
              e_qprs           = ls_qprs
            EXCEPTIONS
              no_authorization = 1
              OTHERS           = 2.
          IF sy-subrc = 0.
            APPEND ls_qprs TO lt_qprs.
          ENDIF.
        ENDDO.

      ENDLOOP.
    ENDIF.
  ENDIF.

  LOOP AT qppsv_tab INTO ls_qppsv.
    LOOP AT lt_qprs INTO ls_qprs.
      ls_qppsv-ip-phynr = ls_qprs-phynr.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = ls_qprs-phynr
        IMPORTING
          output = ls_qppsv-ip-userc1.

      ls_qppsv-ip-userc1akt = 'X'.
      APPEND ls_qppsv TO lt_qppsv.
    ENDLOOP.
  ENDLOOP.

  qppsv_tab[] = lt_qppsv[].


ENDFUNCTION.
