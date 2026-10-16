*FORM lesen_center USING VALUE(f_kokrs) LIKE bapi0015id-kokrs
*                        VALUE(f_prctr) LIKE bapi0015id-prctr
*               CHANGING VALUE(f_abtei)
*                        VALUE(f_stras)
*                        VALUE(f_ltext).
*  DATA: l_detail  LIKE bapi0015_2,
*        l_address LIKE bapi0002_3,
*        l_return  LIKE bapireturn.
*  CALL FUNCTION 'BAPI_PROFITCENTER_GETDETAIL'
*    EXPORTING
*      profitcenter        = f_prctr
*      controllingarea     = f_kokrs
*    IMPORTING
*      profitcenter_detail = l_detail
*      address             = l_address
*      return              = l_return.
*  IF l_detail-department IS INITIAL.
*    f_abtei = 'AOG-UM-CH'.
*  ELSE.
*    f_abtei = l_detail-department.
*  ENDIF.
*  IF l_address-street IS INITIAL.
**    f_stras = 'Sandreuthstrasse 25'.                          "Wo220807
*    f_stras = 'Sandreuthstrasse 39'.                        "Wo220807
*  ELSE.
*    f_stras = l_address-street.
*  ENDIF.
*  f_ltext = l_detail-long_text.
*ENDFORM.                    "LESEN_CENTER
*
*FORM get_sample_result TABLES   it_qamv       TYPE qamvtab
*                                it_qasr       TYPE qasrtab
*                                it_qmtt       TYPE t_qmtt
*                                it_t006a      TYPE t_t006a
*                                it_cert_attr  TYPE t_cert_attr
*                       USING    is_qapp       TYPE qapp
*                                iv_merknr
*                       CHANGING ev_messwert   TYPE text40
*                                ev_grenzwert  TYPE text40
*                                ev_verfahren  TYPE text40.
*
*  DATA: lc_na          TYPE char5 VALUE '--'.
*
*  DATA: lv_stellen    TYPE cha_class_data-stellen.
*  DATA: lv_fltp_value TYPE cha_class_data-sollwert.
*  DATA: lv_char_value TYPE cha_class_view-sollwert.
*  DATA: lv_attribut   TYPE text20.
*
*  DATA: ls_qamv       TYPE qamv.
*  DATA: ls_qasr       TYPE qasr.
*  DATA: ls_qmtt       TYPE qmtt.
*  DATA: ls_t006a      TYPE t006a.
*  DATA: ls_cert_attr  TYPE yqm_cert_attr.
*
*  READ TABLE it_qamv INTO ls_qamv
*    WITH KEY verwmerkm = iv_merknr.
*  IF sy-subrc <> 0.
*    CLEAR ls_qamv.
*  ENDIF.
*
*  READ TABLE it_qasr INTO ls_qasr
*    WITH KEY prueflos = ls_qamv-prueflos
*             vorglfnr = ls_qamv-vorglfnr
*             merknr   = ls_qamv-merknr
*             probenr  = is_qapp-probenr.
*  IF sy-subrc <> 0.
*    CLEAR ls_qasr.
*    CLEAR ev_messwert.
*    ev_messwert = lc_na.
*  ENDIF.
*
*  IF NOT ls_qasr-attribut IS INITIAL.
*    READ TABLE it_cert_attr INTO ls_cert_attr
*      WITH KEY attribut  = ls_qasr-attribut
*               verwmerkm = ls_qamv-merknr.
*    IF sy-subrc <> 0.
*      READ TABLE it_cert_attr INTO ls_cert_attr
*        WITH KEY attribut  = ls_qasr-attribut
*                 verwmerkm = space.
*      IF sy-subrc <> 0.
*        CLEAR ls_cert_attr.
*      ENDIF.
*    ENDIF.
*  ELSE.
*    CLEAR ls_cert_attr.
*  ENDIF.
*
*  IF ls_qamv-steuerkz(1) IS INITIAL.
*    IF NOT ls_qasr-code1 IS INITIAL.
*      CALL FUNCTION 'QPK1_CODE_TEXT'
*        EXPORTING
*          i_katalogart      = ls_qasr-katalgart1
*          i_codegruppe      = ls_qasr-gruppe1
*          i_code            = ls_qasr-code1
**         I_SPRACHE         = SY-LANGU
*        IMPORTING
*          e_text            = ev_messwert
**         E_GROUPTEXT       =
*        EXCEPTIONS
*          no_match_in_range = 1
*          OTHERS            = 2.
*      IF sy-subrc <> 0.
*        CLEAR ev_messwert .
*      ENDIF.
*    ELSE.
*      ev_messwert = lc_na.
*    ENDIF.
*    ev_grenzwert = lc_na.
*  ELSE.
*    IF NOT ls_qamv-masseinhsw IS INITIAL.
*      READ TABLE it_t006a INTO ls_t006a
*        WITH KEY spras    = sy-langu
*                 msehi    = ls_qamv-masseinhsw.
*      IF sy-subrc <> 0.
*        CLEAR ls_t006a.
*      ENDIF.
*    ELSE.
*      CLEAR ls_t006a.
*    ENDIF.
*
*    lv_stellen    = ls_qamv-stellen.
*    lv_fltp_value = ls_qasr-mittelwert.
*
*    CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
*      EXPORTING
*        i_number_of_digits       = lv_stellen
*        i_fltp_value             = lv_fltp_value
*        i_value_not_initial_flag = ls_qasr-mittelwni
*      IMPORTING
*        e_char_field             = lv_char_value.
*
*    SHIFT lv_char_value LEFT DELETING LEADING space.
*
*    MOVE lv_char_value TO ev_messwert.
**    CONCATENATE ls_qasr-attribut
**                lv_char_value
**                INTO ev_messwert
**                SEPARATED BY space.
**
**    SHIFT ev_messwert LEFT DELETING LEADING space.
*
*    IF ev_messwert IS INITIAL.
*      ev_messwert = lc_na.
*    ENDIF.
*
*    lv_stellen    = ls_qamv-stellen.
*    lv_fltp_value = ls_qamv-toleranzob.
*
*    IF NOT ls_qamv-tolobni IS INITIAL.
*
*      CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
*        EXPORTING
*          i_number_of_digits       = lv_stellen
*          i_fltp_value             = lv_fltp_value
*          i_value_not_initial_flag = ls_qamv-tolobni
*        IMPORTING
*          e_char_field             = lv_char_value.
*
*      ev_grenzwert = lv_char_value.
*      SHIFT ev_grenzwert LEFT DELETING LEADING space.
*    ELSE.
*      ev_grenzwert = lc_na.
*    ENDIF.
*  ENDIF.
*
*  IF NOT ls_cert_attr IS INITIAL.
*    CASE ls_cert_attr-druck_attr.
*      WHEN 'T'.
*        MOVE ls_cert_attr-text_attr TO ev_messwert.
*      WHEN 'X'.
*        CONCATENATE ls_qasr-attribut
*                    ev_messwert
*                    INTO ev_messwert
*                    SEPARATED BY space.
*      WHEN space.
**      Es muss nichts getan werden,
**      nur der Messwert wird ausgegeben
*    ENDCASE.
*  ENDIF.
*
*
*  IF NOT ls_qamv-pmethode IS INITIAL.
*    READ TABLE it_qmtt INTO ls_qmtt
*      WITH KEY werks   = ls_qamv-qmtb_werks
*               pmtnr   = ls_qamv-pmethode
*               version = ls_qamv-pmtversion
*               sprache = sy-langu.
*    IF sy-subrc = 0.
*      ev_verfahren = ls_qmtt-kurztext.
*    ELSE.
*      ev_verfahren = lc_na.
*    ENDIF.
*  ELSE.
*    ev_verfahren = lc_na.
*  ENDIF.
*ENDFORM.
*
*
*
*
*
*
*
*
*
*
*
