class YCL_IM_QMLIMS_INPPROC_902 definition
  public
  final
  create public .

public section.

  interfaces IF_EX_QM_INPUT_PROCEDURE .
protected section.
private section.
ENDCLASS.



CLASS YCL_IM_QMLIMS_INPPROC_902 IMPLEMENTATION.


  method IF_EX_QM_INPUT_PROCEDURE~DISPLAY_DOCU.
  endmethod.


  METHOD if_ex_qm_input_procedure~input_procedure.

    DATA lv_decimal         TYPE i.
    DATA lv_diff_dec_places TYPE qdiff_dec_places.
    DATA lv_messwert_float        TYPE float.
    DATA lv_messwert        TYPE qmesswertc.
    DATA lv_messwert_char        TYPE qmesswertc.
    DATA ls_qmkst           TYPE qmkst.
    DATA ls_tqss1           TYPE tqss1.
    DATA lv_dummy40         TYPE yqm_dummy40.
    DATA lv_stellen         TYPE qstellen.
    DATA lv_fltp_value      TYPE qsollwerte.

    lv_dummy40 = is_inpproc_req-dummy40.
    lv_stellen = is_inpproc_req-stellen.

* Get decimal places
    CALL FUNCTION 'CHAR_FLTP_CONVERSION'
      EXPORTING
        string             = cv_value
      IMPORTING
        decim              = lv_decimal
        flstr              = lv_messwert_float
      EXCEPTIONS
        exponent_too_big   = 1
        exponent_too_small = 2
        string_not_fltp    = 3
        too_many_decim     = 4
        OTHERS             = 5.
    IF sy-subrc <> 0.
      RAISE input_procedure_not_possible.
    ENDIF.

* Get decimal places
    CALL FUNCTION 'CHAR_FLTP_CONVERSION'
      EXPORTING
        string             = cv_value
      IMPORTING
        flstr              = lv_fltp_value
      EXCEPTIONS
        exponent_too_big   = 1
        exponent_too_small = 2
        string_not_fltp    = 3
        too_many_decim     = 4
        OTHERS             = 5.
    IF sy-subrc <> 0.
      RAISE input_procedure_not_possible.
    ENDIF.

* Value summarized or single value
    ls_qmkst = is_inpproc_req-steuerkz.

    IF ls_qmkst-estukz IS INITIAL.
* Summarized recording
* Read plant dependent QM setting (additional decimal places)
      CALL FUNCTION 'TQSS1_READ'
        EXPORTING
          i_werks  = iv_plant
        IMPORTING
          e_tqss1  = ls_tqss1
        EXCEPTIONS
          no_entry = 1
          OTHERS   = 2.
      IF sy-subrc <> 0.
        RAISE input_procedure_not_possible.
      ENDIF.
    ENDIF.

    IF lv_messwert_float <> 0.
      CLEAR lv_messwert_char.

      CALL FUNCTION 'FLTP_CHAR_CONVERSION'
        EXPORTING
          decim = 16
          expon = 0
          input = lv_messwert_float
          ivalu = 'X'
*         MASKN = ' '
        IMPORTING
          flstr = lv_messwert_char.

      REPLACE ',' WITH '.' INTO lv_messwert_char.

      CALL FUNCTION 'Y_QMLIMS_SERVICE_SIGN_RUNDEN'
        EXPORTING
          iv_wert              = lv_messwert_char
          iv_sigtyp            = lv_dummy40-signifikanztyp
          iv_geplante_stellen  = lv_stellen
        IMPORTING
          ev_wert_char         = lv_messwert
          ev_diff_dec_places   = lv_diff_dec_places
        EXCEPTIONS
          sig_type_not_defined = 1
          sig_round_unexpected = 2
          sig_no_conversion    = 3
          OTHERS               = 4.
      IF sy-subrc <> 0.
*      REPLACE '.' WITH ',' INTO lv_messwert_char.
*      cv_value           = lv_messwert_char.
        MESSAGE i100(yqmlims).
      ELSE.
        cv_value           = lv_messwert.
        lv_decimal = lv_stellen + lv_diff_dec_places.
      ENDIF.
    ENDIF.

* Get difference decimal places
    cv_diff_dec_places = lv_decimal - is_inpproc_req-stellen
                                    - ls_tqss1-nkstellof.

* Wurde die Warngrenze überschritten?
    IF NOT is_inpproc_req-grenzun2ni IS INITIAL.

      CALL FUNCTION 'CHAR_FLTP_CONVERSION'
        EXPORTING
          string             = cv_value
        IMPORTING
          flstr              = lv_fltp_value
        EXCEPTIONS
          exponent_too_big   = 1
          exponent_too_small = 2
          string_not_fltp    = 3
          too_many_decim     = 4
          OTHERS             = 5.
      IF sy-subrc <> 0.
        RAISE input_procedure_not_possible.
      ENDIF.

* Aufruf Fkt-Baustein zur Toleranzprüfung
      CALL FUNCTION 'QEST_TOLERANCE_INSPECTION'
        EXPORTING
          aktf            = lv_fltp_value
          kzo             = is_inpproc_req-grenzun2ni
          kzu             = is_inpproc_req-grenzob2ni
          ogwf            = is_inpproc_req-grenzeun2
          stellen         = is_inpproc_req-stellen
          ugwf            = is_inpproc_req-grenzeob2
        EXCEPTIONS
          aktf_higher_ogw = 02
          aktf_lower_ugw  = 01.

      CASE sy-subrc.
        WHEN 0.
        WHEN 1.
          cv_attribut = 'W'.
        WHEN 2.
          cv_attribut = 'W'.
      ENDCASE.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
