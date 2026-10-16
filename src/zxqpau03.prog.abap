*&---------------------------------------------------------------------*
*& Include          ZXQPAU03
*&---------------------------------------------------------------------*
**----------------------------------------------------------------------
**
**   INCLUDE ZXQPAU03
**
**----------------------------------------------------------------------
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"       IMPORTING
*"             VALUE(I_QALS) TYPE  QALS STRUCTURE  QALS
*"       TABLES
*"              T_PLMK STRUCTURE  PLMKB
*"              T_QAPO STRUCTURE  QAPO
*"----------------------------------------------------------------------

* User-Exit nur für Prüfart CHTP durchlaufen
CHECK i_qals-art = 'YQM_TP'.

TYPE-POOLS: ibco2.

DATA:
  ls_configuration    TYPE ibco2_instance_rec2,
  ls_plmk_config_vals TYPE ibco2_value_rec,
  ls_plmk             TYPE plmkb,
  ls_caufv            TYPE caufvdb,
  ls_spez_pmk         TYPE yqm_spez_pmk_t.

DATA:
  lt_plmk_tab TYPE STANDARD TABLE OF plmkb,
  lt_caufv_bt TYPE STANDARD TABLE OF caufvdb,
  lt_spez_pmk TYPE STANDARD TABLE OF yqm_spez_pmk_t,
  lr_plmk     TYPE RANGE OF ibvalue0-atwrt.

DATA:
  lv_cuobj   TYPE pmsdo-cuobj,
  lv_stellen TYPE qstellen.

*----------------------------------------------------------------------
*
* Initialisierung der Daten                                           *
*----------------------------------------------------------------------

CLEAR   lr_plmk.
CLEAR   lt_plmk_tab.

* Wenn das Prüflos aus einem Serviceauftrag erzeugt wurde...
IF i_qals-aufnr IS NOT INITIAL.

* Instandhaltungsauftrag aus dem Memory lesen, da noch nicht unbedingt auf der Datenbank
  CALL FUNCTION 'CO_BH_CAUFV_BT_FETCH'
    TABLES
      et_caufv_bt = lt_caufv_bt.

  READ TABLE lt_caufv_bt INTO ls_caufv
    WITH KEY aufnr = i_qals-aufnr.

*  CALL FUNCTION 'IBAPI_H_ORDER_READ'
*    EXPORTING
*      iv_aufnr           = i_qals-aufnr
**     IV_ENQUEUE_ORDER   = 'X'
**     IV_DONT_SET_BAPIFLAG       =
*    IMPORTING
**     EV_AUFPL           =
*      es_caufvd          = ls_caufvd
**     ES_AFFLD           =
**     ES_PMSDO           =
**     ES_AFPOD           =
**     ET_SERNO_OLIST     =
**     ES_SETTLMT_PROFILE =
*    EXCEPTIONS
*      order_locked       = 1
*      order_read_error   = 2
*      order_incompatible = 3
*      OTHERS             = 4.
  IF sy-subrc = 0.
* Implement suitable error handling here
    SELECT SINGLE int_obj_no
         FROM crms4_serv_i_search
         INTO @DATA(lv_int_obj_no)
         WHERE  object_type = 'BUS2000116'
           AND    object_id   = @ls_caufv-service_doc_id
           AND    number_int  = @ls_caufv-service_doc_item_id
           AND    int_obj_no <> '0'.
    IF sy-subrc = 0.
      lv_cuobj = lv_int_obj_no.
    ENDIF.

* ... nur im Falle eine Konfiguration geht es hier weiter...
    IF NOT lv_cuobj IS INITIAL.

* ...  dann wird die Konfiguration nachgelesen,...
      CALL FUNCTION 'CUCB_GET_SINGLE_INSTANCE'
        EXPORTING
          instance                     = lv_cuobj
        IMPORTING
          instance_rec                 = ls_configuration
        EXCEPTIONS
          invalid_instance             = 1
          instance_is_a_classification = 2
          OTHERS                       = 3.

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ELSE.

* ...eine Ranges Tabelle für die Merkmalswerte wird aufgebaut...
        LOOP AT ls_configuration-values
             INTO ls_plmk_config_vals
             WHERE atwrt NE space.

          APPEND VALUE #(
              sign   = 'I'
              option = 'EQ'
              low    = ls_plmk_config_vals-atwrt
          ) TO lr_plmk.

        ENDLOOP.
      ENDIF.

* Alle Merkmale, die nicht über die Konfiguration ausgewählt wurden
* werden eliminiert
      DELETE t_plmk WHERE NOT verwmerkm IN lr_plmk.

    ENDIF.

    IF NOT i_qals-yqm_spezid IS INITIAL.
* ...die Tabelle der Spezifikationen wird nachgelesen...
      SELECT * FROM yqm_spez_pmk_t INTO TABLE lt_spez_pmk
             WHERE spezid = i_qals-yqm_spezid.
      IF sy-subrc <> 0.
        CLEAR lt_spez_pmk.
      ENDIF.
* Gepuffertes Lesen der QMTB
      IF NOT lt_spez_pmk[] IS INITIAL.
        SELECT werks, pmtnr, version, gueltigab, loekz
          FROM qmtb INTO TABLE @DATA(lt_qmtb)
          FOR ALL ENTRIES IN @lt_spez_pmk
          WHERE werks      = @lt_spez_pmk-qmtb_werks
          AND   pmtnr      = @lt_spez_pmk-pmethode
          AND   gueltigab  LE @sy-datum
          AND   loekz      = 2.
        IF sy-subrc = 0.
          SORT lt_qmtb BY werks   ASCENDING
                          pmtnr   ASCENDING
                          version DESCENDING.
        ENDIF.
      ENDIF.

* Wenn eine Spezifikation ausgewählt wurde werden einige Vorgaben aus
* der Spezifikationstabelle übernommen
      LOOP AT t_plmk INTO ls_plmk.
* Die Merkmale werden mit den Prüfvorgaben aus der
* Spezifikationstabelle abgeglichen
        LOOP AT lt_spez_pmk
          INTO ls_spez_pmk
          WHERE qpmk_zaehl = ls_plmk-qpmk_zaehl
          AND   verwmerkm  = ls_plmk-verwmerkm.
*         AND   mkversion  = ls_plmk-mkversion.
          IF NOT ls_spez_pmk-stellen IS INITIAL.
            ls_plmk-stellen = ls_spez_pmk-stellen.
          ENDIF.
          IF NOT ls_spez_pmk-signifikanztyp IS INITIAL.
            ls_plmk-dummy40+1(2) = ls_spez_pmk-signifikanztyp.
          ENDIF.
          IF NOT ls_spez_pmk-cert_grenze IS INITIAL.
            ls_plmk-yqm_cert_grenze = ls_spez_pmk-cert_grenze.
          ENDIF.
          IF  NOT ls_spez_pmk-qmtb_werks IS INITIAL
          AND NOT ls_spez_pmk-pmethode   IS INITIAL.
            READ TABLE lt_qmtb INTO DATA(ls_qmtb)
              WITH KEY werks = ls_spez_pmk-qmtb_werks
                       pmtnr = ls_spez_pmk-pmethode
                       BINARY SEARCH.
            IF sy-subrc <> 0.
              CLEAR ls_qmtb.
            ENDIF.

            ls_plmk-qmtb_werks = ls_qmtb-werks.
            ls_plmk-pmethode   = ls_qmtb-pmtnr.
            ls_plmk-pmtversion = ls_qmtb-version.

          ENDIF.

          IF NOT ls_spez_pmk-sollwert IS INITIAL.
            CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
              EXPORTING
                i_character_string       = ls_spez_pmk-sollwert
                i_number_of_digits       = ls_plmk-stellen
              IMPORTING
                e_value_not_initial_flag = ls_plmk-sollwni
                e_fltp_value             = ls_plmk-sollwert.
          ENDIF.
          IF NOT ls_spez_pmk-toleranzun IS INITIAL.
            CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
              EXPORTING
                i_character_string       = ls_spez_pmk-toleranzun
                i_number_of_digits       = ls_plmk-stellen
              IMPORTING
                e_value_not_initial_flag = ls_plmk-tolunni
                e_fltp_value             = ls_plmk-toleranzun.
          ENDIF.
          IF NOT ls_spez_pmk-toleranzob IS INITIAL.
* Anzahl Nachkommastellen für obere Toleranzgrenze kann
* unterschiedliche Anzahl Nachkommastellen haben entsprechend der
* Spezifikationstabelle
            CALL FUNCTION 'CHAR_FLTP_CONVERSION'
              EXPORTING
                string             = ls_spez_pmk-toleranzob
              IMPORTING
                decim              = lv_stellen
*               flstr              = lv_fltp_value
              EXCEPTIONS
                exponent_too_big   = 1
                exponent_too_small = 2
                string_not_fltp    = 3
                too_many_decim     = 4
                OTHERS             = 5.
            IF sy-subrc = 0.
              ls_plmk-yqm_toloben_diff_dec_places = lv_stellen - ls_plmk-stellen .
            ENDIF.

            CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
              EXPORTING
                i_character_string       = ls_spez_pmk-toleranzob
                i_number_of_digits       = lv_stellen
              IMPORTING
                e_value_not_initial_flag = ls_plmk-tolobni
                e_fltp_value             = ls_plmk-toleranzob.

          ENDIF.
          IF NOT ls_spez_pmk-grenzeun1  IS INITIAL.
            CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
              EXPORTING
                i_character_string       = ls_spez_pmk-grenzeun1
                i_number_of_digits       = ls_plmk-stellen
              IMPORTING
                e_value_not_initial_flag = ls_plmk-grenzun1ni
                e_fltp_value             = ls_plmk-grenzeun1.
          ENDIF.
          IF NOT ls_spez_pmk-grenzeob1  IS INITIAL.
            CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
              EXPORTING
                i_character_string       = ls_spez_pmk-grenzeob1
                i_number_of_digits       = ls_plmk-stellen
              IMPORTING
                e_value_not_initial_flag = ls_plmk-grenzob1ni
                e_fltp_value             = ls_plmk-grenzeob1.
          ENDIF.
          IF NOT ls_spez_pmk-grenzeun2  IS INITIAL.
            CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
              EXPORTING
                i_character_string       = ls_spez_pmk-grenzeun2
                i_number_of_digits       = ls_plmk-stellen
              IMPORTING
                e_value_not_initial_flag = ls_plmk-grenzun2ni
                e_fltp_value             = ls_plmk-grenzeun2.
          ENDIF.
          IF NOT ls_spez_pmk-grenzeob2  IS INITIAL.
            CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
              EXPORTING
                i_character_string       = ls_spez_pmk-grenzeob2
                i_number_of_digits       = ls_plmk-stellen
              IMPORTING
                e_value_not_initial_flag = ls_plmk-grenzob2ni
                e_fltp_value             = ls_plmk-grenzeob2.
          ENDIF.
          IF NOT ls_spez_pmk-plausiunten IS INITIAL.
            CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
              EXPORTING
                i_character_string       = ls_spez_pmk-plausiunten
                i_number_of_digits       = ls_plmk-stellen
              IMPORTING
                e_value_not_initial_flag = ls_plmk-plausiunni
                e_fltp_value             = ls_plmk-plausiunte.
          ENDIF.
          IF NOT ls_spez_pmk-plausioben IS INITIAL.
            CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
              EXPORTING
                i_character_string       = ls_spez_pmk-plausioben
                i_number_of_digits       = ls_plmk-stellen
              IMPORTING
                e_value_not_initial_flag = ls_plmk-plausiobni
                e_fltp_value             = ls_plmk-plausioben.
          ENDIF.

* Geändertes Merkmal an die Hilfstabelle hängen
          APPEND ls_plmk TO lt_plmk_tab.
        ENDLOOP.
* Wenn über die Spezifikationstabelle keine Änderungen gemacht wurden,
* wird das Originalmerkmal übernommen
        IF sy-subrc <> 0.
          APPEND ls_plmk TO lt_plmk_tab.
        ENDIF.
      ENDLOOP.

      CLEAR t_plmk.
      CLEAR t_plmk.

      t_plmk[] = lt_plmk_tab[].

    ENDIF.

    DATA: lv_excluded     TYPE qkz.
*    DATA: LS_PLTY_LIMITS  TYPE YQM_PLTY_LIMIT_T.
*    DATA: LT_PLTY_LIMITS  TYPE TABLE OF YQM_PLTY_LIMIT_T.

* Ist der technische Platz explizit von der Plausiprüfung ausgeschlossen?
    SELECT COUNT( * ) FROM yqm_tpln_excl_t
      WHERE ( tplnr   = i_qals-yqm_tplnr
         AND  generic = space ).
    IF sy-subrc = 0.
      lv_excluded = 'X'.
      EXIT.
    ENDIF.

    SELECT tplnr, generic FROM yqm_tpln_excl_t
      INTO TABLE @DATA(lt_tpln_exclude)
      WHERE generic = 'X'.
    IF sy-subrc <> 0.
      CLEAR lt_tpln_exclude.
    ENDIF.

    LOOP AT lt_tpln_exclude INTO DATA(ls_tpln_exclude).
      IF i_qals-yqm_tplnr CP ls_tpln_exclude-tplnr.
        lv_excluded = 'X'.
      ENDIF.
    ENDLOOP.

    CHECK lv_excluded IS INITIAL.

* Ist die Materialnummer explizit von der Plausiprüfung ausgeschlossen?
    SELECT COUNT( * ) FROM yqm_matn_excl_t
      WHERE ( matnr   = i_qals-matnr
         AND  generic = space ).
    IF sy-subrc = 0.
      lv_excluded = 'X'.
      EXIT.
    ENDIF.

    SELECT matnr, generic
      FROM yqm_matn_excl_t
      INTO TABLE @DATA(lt_matn_exclude)
      WHERE generic = 'X'.
    IF sy-subrc <> 0.
      CLEAR lt_matn_exclude.
    ENDIF.

    LOOP AT lt_matn_exclude INTO DATA(ls_matn_exclude).
      IF i_qals-matnr CP ls_matn_exclude-matnr.
        lv_excluded = 'X'.
      ENDIF.
    ENDLOOP.

    CHECK lv_excluded IS INITIAL.

    IF NOT t_plmk[] IS INITIAL.

* Die genauen (berechneten) Plausibilitätsgrenzen werden zugemischt
      SELECT  tplnr, verwmerkm, werks,
              plausioben, plausiobni,
              plausiunte, plausiunni
        FROM yqm_plty_limit_t INTO TABLE @DATA(lt_plty_limits)
        FOR ALL ENTRIES IN @t_plmk
        WHERE tplnr     = @i_qals-yqm_tplnr
        AND   werks     = @t_plmk-qpmk_werks
        AND   verwmerkm = @t_plmk-verwmerkm.
      IF sy-subrc = 0.
        SORT lt_plty_limits BY tplnr verwmerkm werks.
      ELSE.
        CLEAR lt_plty_limits.
      ENDIF.

      LOOP AT t_plmk INTO ls_plmk.
        READ TABLE lt_plty_limits INTO DATA(ls_plty_limits)
          WITH KEY tplnr     = i_qals-yqm_tplnr
                   werks     = ls_plmk-qpmk_werks
                   verwmerkm = ls_plmk-verwmerkm.
        IF sy-subrc = 0.
*          ls_qmkst = ls_plmk-steuerkz.
          IF NOT ls_plty_limits-plausiunni IS INITIAL.
            ls_plmk-plausiunte   = ls_plty_limits-plausiunte.
            ls_plmk-plausiunni   = ls_plty_limits-plausiunni.
          ENDIF.
          IF NOT ls_plty_limits-plausiobni IS INITIAL.
            ls_plmk-plausioben   = ls_plty_limits-plausioben.
            ls_plmk-plausiobni   = ls_plty_limits-plausiobni.
          ENDIF.
        ENDIF.
        MODIFY t_plmk FROM ls_plmk.
      ENDLOOP.
    ENDIF.
  ENDIF.
ENDIF.
