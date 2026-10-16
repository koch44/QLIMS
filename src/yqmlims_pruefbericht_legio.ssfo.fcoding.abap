FORM lesen_center USING VALUE(iv_kokrs) TYPE bapi0015id-kokrs
                        VALUE(iv_prctr) TYPE bapi0015id-prctr
               CHANGING VALUE(cv_abtei)
                        VALUE(cv_stras)
                        VALUE(cv_ltext).

  DATA: ls_detail  TYPE bapi0015_2,
        ls_address TYPE bapi0002_3.
*        ls_return  LIKE bapireturn.

  CALL FUNCTION 'BAPI_PROFITCENTER_GETDETAIL'
    EXPORTING
      profitcenter        = iv_prctr
      controllingarea     = iv_kokrs
    IMPORTING
      profitcenter_detail = ls_detail
      address             = ls_address.
*      return              = ls_return.

  IF ls_detail-department IS INITIAL.
    cv_abtei = 'AOG-UM-CH'.
  ELSE.
    cv_abtei = ls_detail-department.
  ENDIF.
  IF ls_address-street IS INITIAL.
*    cv_stras = 'Sandreuthstrasse 25'.                          "Wo220807
    cv_stras = 'Sandreuthstrasse 39'.                       "Wo220807
  ELSE.
    cv_stras = ls_address-street.
  ENDIF.
  cv_ltext = ls_detail-long_text.
ENDFORM.                    "LESEN_CENTER

FORM get_sample_result TABLES   t_qamv       TYPE qamvtab
                                t_qasr       TYPE qasrtab
                                t_qmtt       TYPE t_qmtt
                                t_t006a      TYPE t_t006a
                                t_cert_attr  TYPE t_cert_attr
                       USING    is_qapp      TYPE qapp
                                iv_merknr
                       CHANGING cv_messwert  TYPE text40
                                cv_grenzwert TYPE text40
                                cv_verfahren TYPE text40.

  DATA: lv_na	        TYPE char5 VALUE '--'.

  DATA: lv_stellen    TYPE cha_class_data-stellen.
  DATA: lv_fltp_value TYPE cha_class_data-sollwert.
  DATA: lv_char_value TYPE cha_class_view-sollwert.

  DATA: ls_qamv       TYPE qamv.
  DATA: ls_qasr       TYPE qasr.
  DATA: ls_qmtt       TYPE qmtt.
  DATA: ls_cert_attr  TYPE yqm_cert_attr_t.

  READ TABLE t_qamv INTO ls_qamv
    WITH KEY verwmerkm = iv_merknr.
  IF sy-subrc <> 0.
    CLEAR ls_qamv.
  ENDIF.

  READ TABLE t_qasr INTO ls_qasr
    WITH KEY prueflos = ls_qamv-prueflos
             vorglfnr = ls_qamv-vorglfnr
             merknr   = ls_qamv-merknr
             probenr  = is_qapp-probenr.
  IF sy-subrc <> 0.
    CLEAR ls_qasr.
    CLEAR cv_messwert.
    cv_messwert = lv_na.
  ENDIF.

  IF NOT ls_qasr-attribut IS INITIAL.
    READ TABLE t_cert_attr INTO ls_cert_attr
      WITH KEY attribut  = ls_qasr-attribut
               verwmerkm = ls_qamv-verwmerkm
               BINARY SEARCH.
    IF sy-subrc <> 0.
      READ TABLE t_cert_attr INTO ls_cert_attr
        WITH KEY attribut  = ls_qasr-attribut
                 verwmerkm = space
                 BINARY SEARCH.
      IF sy-subrc <> 0.
        CLEAR ls_cert_attr.
      ENDIF.
    ENDIF.
  ELSE.
    CLEAR ls_cert_attr.
  ENDIF.

  IF ls_qamv-steuerkz(1) IS INITIAL.
    IF NOT ls_qasr-code1 IS INITIAL.
      CALL FUNCTION 'QPK1_CODE_TEXT'
        EXPORTING
          i_katalogart      = ls_qasr-katalgart1
          i_codegruppe      = ls_qasr-gruppe1
          i_code            = ls_qasr-code1
*         I_SPRACHE         = SY-LANGU
        IMPORTING
          e_text            = cv_messwert
*         E_GROUPTEXT       =
        EXCEPTIONS
          no_match_in_range = 1
          OTHERS            = 2.
      IF sy-subrc <> 0.
        CLEAR cv_messwert .
      ENDIF.
    ELSE.
      cv_messwert = lv_na.
    ENDIF.
    cv_grenzwert = lv_na.
  ELSE.
*    IF NOT ls_qamv-masseinhsw IS INITIAL.
*      READ TABLE t_t006a INTO ls_t006a
*        WITH KEY spras    = sy-langu
*                 msehi    = ls_qamv-masseinhsw.
*      IF sy-subrc <> 0.
*        CLEAR ls_t006a.
*      ENDIF.
*    ELSE.
*      CLEAR ls_t006a.
*    ENDIF.

    lv_stellen    = ls_qamv-stellen.
    lv_fltp_value = ls_qasr-mittelwert.

    CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
      EXPORTING
        i_number_of_digits       = lv_stellen
        i_fltp_value             = lv_fltp_value
        i_value_not_initial_flag = ls_qasr-mittelwni
      IMPORTING
        e_char_field             = lv_char_value.

    SHIFT lv_char_value LEFT DELETING LEADING space.

    cv_messwert = lv_char_value.

    IF cv_messwert IS INITIAL.
      cv_messwert = lv_na.
    ENDIF.

    lv_stellen    = ls_qamv-stellen.
    lv_fltp_value = ls_qamv-toleranzob.

    IF NOT ls_qamv-tolobni IS INITIAL.

      CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
        EXPORTING
          i_number_of_digits       = lv_stellen
          i_fltp_value             = lv_fltp_value
          i_value_not_initial_flag = ls_qamv-tolobni
        IMPORTING
          e_char_field             = lv_char_value.

      cv_grenzwert = lv_char_value.
      SHIFT cv_grenzwert LEFT DELETING LEADING space.
    ELSE.
      cv_grenzwert = lv_na.
    ENDIF.
  ENDIF.

  IF NOT ls_cert_attr IS INITIAL.
    CASE ls_cert_attr-druck_attr.
      WHEN 'T'.
        cv_messwert = ls_cert_attr-text_attr.
      WHEN 'X'.
        CONCATENATE ls_qasr-attribut
                    cv_messwert
                    INTO cv_messwert
                    SEPARATED BY space.
    ENDCASE.
  ENDIF.


  IF NOT ls_qamv-pmethode IS INITIAL.
    READ TABLE t_qmtt INTO ls_qmtt
      WITH KEY werks   = ls_qamv-qmtb_werks
               pmtnr   = ls_qamv-pmethode
               version = ls_qamv-pmtversion
               sprache = sy-langu.
    IF sy-subrc = 0.
      cv_verfahren = ls_qmtt-kurztext.
    ELSE.
      cv_verfahren = lv_na.
    ENDIF.
  ELSE.
    cv_verfahren = lv_na.
  ENDIF.
ENDFORM.
