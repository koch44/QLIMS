*&---------------------------------------------------------------------*
*& Include          ZXCQBU02
*&---------------------------------------------------------------------*

* Erweiterung LIMS
* Bei der Aufnahme von ungeplanten Merkmalen in die Ergebniserfassung
* soll auch die Spezifikationstabelle interprtiert werden
* Dazu muss das Feld QALS-YQM_SPEZID gefüllt sein
  DATA: ls_qals           TYPE qals.
  DATA: ls_spez_pmk       TYPE yqm_spez_pmk_t.
  DATA: lv_name_qals(32)  VALUE '(SAPLQEEB)QALS'.
  FIELD-SYMBOLS <ls_qals> TYPE any.

  e_qpmk = i_qpmk.
  e_qpmt = i_qpmt.
  e_qpmz = i_qpmz.

  ASSIGN (lv_name_qals) TO <ls_qals>.
  IF sy-subrc = 0.
    ls_qals = <ls_qals>.

    IF NOT ls_qals-yqm_spezid IS INITIAL.

* Wenn eine Spezifikation ausgewählt wurde werden einige Vorgaben aus
* der Spezifikationstabelle übernommen
      SELECT SINGLE * FROM yqm_spez_pmk_t INTO ls_spez_pmk
             WHERE spezid     = ls_qals-yqm_spezid
             AND   qpmk_zaehl = e_qpmk-zaehler
             AND   verwmerkm  = e_qpmk-mkmnr.
*             AND   mkversion  = e_qpmk-version.
      IF sy-subrc = 0.
* Das ungeplante Merkmale wird mit den Prüfvorgaben aus der
* Spezifikationstabelle abgeglichen

        IF NOT ls_spez_pmk-stellen IS INITIAL.
          e_qpmk-stellen = ls_spez_pmk-stellen.
        ENDIF.
        IF NOT ls_spez_pmk-signifikanztyp IS INITIAL.
          e_qpmk-dummy40+1(2) = ls_spez_pmk-signifikanztyp.
        ENDIF.

        IF  NOT ls_spez_pmk-qmtb_werks IS INITIAL
        AND NOT ls_spez_pmk-pmethode   IS INITIAL.
          e_qpmz-werkpm     = ls_spez_pmk-qmtb_werks.
          e_qpmz-pmethode   = ls_spez_pmk-pmethode.
        ENDIF.

        IF NOT ls_spez_pmk-sollwert IS INITIAL.
          CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
            EXPORTING
              i_character_string       = ls_spez_pmk-sollwert
              i_number_of_digits       = e_qpmk-stellen
            IMPORTING
              e_value_not_initial_flag = e_qpmk-sollwni
              e_fltp_value             = e_qpmk-sollwert.
        ENDIF.
        IF NOT ls_spez_pmk-toleranzun IS INITIAL.
          CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
            EXPORTING
              i_character_string       = ls_spez_pmk-toleranzun
              i_number_of_digits       = e_qpmk-stellen
            IMPORTING
              e_value_not_initial_flag = e_qpmk-tolunni
              e_fltp_value             = e_qpmk-toleranzun.
        ENDIF.
        IF NOT ls_spez_pmk-toleranzob IS INITIAL.
          CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
            EXPORTING
              i_character_string       = ls_spez_pmk-toleranzob
              i_number_of_digits       = e_qpmk-stellen
            IMPORTING
              e_value_not_initial_flag = e_qpmk-tolobni
              e_fltp_value             = e_qpmk-toleranzob.
        ENDIF.
        IF NOT ls_spez_pmk-grenzeun1  IS INITIAL.
          CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
            EXPORTING
              i_character_string       = ls_spez_pmk-grenzeun1
              i_number_of_digits       = e_qpmk-stellen
            IMPORTING
              e_value_not_initial_flag = e_qpmk-grenzun1ni
              e_fltp_value             = e_qpmk-grenzeun1.
        ENDIF.
        IF NOT ls_spez_pmk-grenzeob1  IS INITIAL.
          CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
            EXPORTING
              i_character_string       = ls_spez_pmk-grenzeob1
              i_number_of_digits       = e_qpmk-stellen
            IMPORTING
              e_value_not_initial_flag = e_qpmk-grenzob1ni
              e_fltp_value             = e_qpmk-grenzeob1.
        ENDIF.
        IF NOT ls_spez_pmk-grenzeun2  IS INITIAL.
          CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
            EXPORTING
              i_character_string       = ls_spez_pmk-grenzeun2
              i_number_of_digits       = e_qpmk-stellen
            IMPORTING
              e_value_not_initial_flag = e_qpmk-grenzun2ni
              e_fltp_value             = e_qpmk-grenzeun2.
        ENDIF.
        IF NOT ls_spez_pmk-grenzeob2  IS INITIAL.
          CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
            EXPORTING
              i_character_string       = ls_spez_pmk-grenzeob2
              i_number_of_digits       = e_qpmk-stellen
            IMPORTING
              e_value_not_initial_flag = e_qpmk-grenzob2ni
              e_fltp_value             = e_qpmk-grenzeob2.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
