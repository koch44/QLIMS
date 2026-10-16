class YCL_IM_QMLIMS_INPPROC_901 definition
  public
  final
  create public .

public section.

  interfaces IF_EX_QM_INPUT_PROCEDURE .
protected section.
private section.
ENDCLASS.



CLASS YCL_IM_QMLIMS_INPPROC_901 IMPLEMENTATION.


  METHOD if_ex_qm_input_procedure~display_docu.
  ENDMETHOD.


  METHOD if_ex_qm_input_procedure~input_procedure.

    DATA lv_decimal    TYPE i.
    DATA lv_fltp_value TYPE qsollwerte.
    DATA lv_char_value TYPE qsollwertc.
    DATA lv_stellen    TYPE qstellen.
    DATA ls_qmkst      TYPE qmkst.
    DATA ls_tqss1      TYPE tqss1.

* Get decimal places
    CALL FUNCTION 'CHAR_FLTP_CONVERSION'
      EXPORTING
        string             = cv_value
      IMPORTING
        decim              = lv_decimal
        flstr              = lv_fltp_value
      EXCEPTIONS
        exponent_too_big   = 1
        exponent_too_small = 2
        string_not_fltp    = 3
        too_many_decim     = 4
        OTHERS             = 5.
    IF sy-subrc <> 0.
      RAISE input_procedure_not_possible.
    ELSE.
      lv_stellen = lv_decimal.
    ENDIF.

    CASE is_inpproc_req-inpproc.
      WHEN 'Z01'. " Prüfung Warngrenze (ohne Anpassung Nachkommastellen )

* Falls der eingegeben Wert zuviele Nachkommastellen hat, wird er gerundet
        IF lv_stellen GT is_inpproc_req-stellen.

          CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
            EXPORTING
              i_number_of_digits = is_inpproc_req-stellen
              i_fltp_value       = lv_fltp_value
            IMPORTING
              e_char_field       = lv_char_value.

          cv_value = lv_char_value.
          lv_decimal = is_inpproc_req-stellen.
        ENDIF.

      WHEN 'Z03'. " Prüfung Warngrenze (mit Anpassung Nachkommastellen )
* Falls der eingegeben Wert zuviele Nachkommastellen hat, wird nicht gerundet
* Statt dessen wird die Anzahl Nachommastellen korrigiert

*  --> hier ist also nichts zu tun
      WHEN OTHERS.

    ENDCASE.

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

* Get difference decimal places
    cv_diff_dec_places = lv_decimal - is_inpproc_req-stellen
                                    - ls_tqss1-nkstellof.

* Wurde die Warngrenze überschritten?
    IF NOT is_inpproc_req-grenzun2ni IS INITIAL.
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
