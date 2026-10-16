*----------------------------------------------------------------------*
***INCLUDE LYQMLIMS_VIEWSO01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  READ_QPMK_TEXT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_qpmk_text OUTPUT.

  IF  NOT yqm_spez_pmk_t-qpmk_zaehl IS INITIAL
  AND NOT yqm_spez_pmk_t-verwmerkm  IS INITIAL.

    READ TABLE gt_qpmt INTO gs_qpmt WITH KEY
                zaehler = yqm_spez_pmk_t-qpmk_zaehl
                mkmnr   = yqm_spez_pmk_t-verwmerkm.
    IF sy-subrc <> 0.
      SELECT zaehler mkmnr sprache kurztext FROM qpmt
        INTO TABLE gt_qpmt_h
             UP TO 1 ROWS
             WHERE zaehler = yqm_spez_pmk_t-qpmk_zaehl
             AND   mkmnr   = yqm_spez_pmk_t-verwmerkm
             AND   sprache = sy-langu
             ORDER BY version DESCENDING.
      IF sy-subrc = 0.
        READ TABLE gt_qpmt_h INTO gs_qpmt INDEX 1.
        IF sy-subrc = 0.
          APPEND gs_qpmt TO gt_qpmt.
        ENDIF.
      ELSE.
        CLEAR gs_qpmt.
      ENDIF.
    ENDIF.
  ELSE.
    CLEAR gs_qpmt.
  ENDIF.

ENDMODULE.                 " READ_QPMK_TEXT  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  READ_QMTT_TEXT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_qmtt_text OUTPUT.

  IF  NOT yqm_spez_pmk_t-qpmk_zaehl IS INITIAL
  AND NOT yqm_spez_pmk_t-pmethode   IS INITIAL.

    READ TABLE gt_qmtt INTO gs_qmtt WITH KEY
                werks = yqm_spez_pmk_t-qpmk_zaehl
                pmtnr = yqm_spez_pmk_t-pmethode.
    IF sy-subrc <> 0.
      SELECT werks pmtnr sprache kurztext FROM qmtt
        INTO TABLE gt_qmtt_h
             UP TO 1 ROWS
             WHERE werks   = yqm_spez_pmk_t-qpmk_zaehl
             AND   pmtnr   = yqm_spez_pmk_t-pmethode
             AND   sprache = sy-langu
             ORDER BY version DESCENDING.
      IF sy-subrc = 0.
        READ TABLE gt_qmtt_h INTO gs_qmtt INDEX 1.
        IF sy-subrc = 0.
          APPEND gs_qmtt TO gt_qmtt.
        ENDIF.
      ELSE.
        CLEAR gs_qmtt.
      ENDIF.
    ENDIF.
  ELSE.
    CLEAR gs_qmtt.
  ENDIF.

ENDMODULE.                 " READ_QMTT_TEXT  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  FLTP_CHAR_CONV_A  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE fltp_char_conv_a OUTPUT.

*  move extract to YQM_SIGTYP_GW.
  yqm_sigtyp_gw_t = <vim_extract_struc>.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_sigtyp_gw_t-grenzeu
                c_kreuz
                c_stellen
       CHANGING qfltp-qrkfpar1.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_sigtyp_gw_t-grenzeo
                c_kreuz
                c_stellen
       CHANGING qfltp-qrkfpar2.

ENDMODULE.                 " FLTP_CHAR_CONV_A  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  READ_QPMK_TEXT_2  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_qpmk_text_2 OUTPUT.

  IF  NOT yqm_plty_excl_t-werks      IS INITIAL
  AND NOT yqm_plty_excl_t-verwmerkm  IS INITIAL.

    READ TABLE gt_qpmt INTO gs_qpmt WITH KEY
                zaehler = yqm_plty_excl_t-werks
                mkmnr   = yqm_plty_excl_t-verwmerkm.
    IF sy-subrc <> 0.
      SELECT zaehler mkmnr sprache kurztext FROM qpmt
        INTO TABLE gt_qpmt_h
             UP TO 1 ROWS
             WHERE zaehler = yqm_plty_excl_t-werks
             AND   mkmnr   = yqm_plty_excl_t-verwmerkm
             AND   sprache = sy-langu
             ORDER BY version DESCENDING.
      IF sy-subrc = 0.
        READ TABLE gt_qpmt_h INTO gs_qpmt INDEX 1.
        IF sy-subrc = 0.
          APPEND gs_qpmt TO gt_qpmt.
        ENDIF.
      ELSE.
        CLEAR gs_qpmt.
      ENDIF.
    ENDIF.
  ELSE.
    CLEAR gs_qpmt.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  READ_QPMK_TEXT_3  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_qpmk_text_3 OUTPUT.

  IF  NOT yqm_plty_limit_t-werks      IS INITIAL
  AND NOT yqm_plty_limit_t-verwmerkm  IS INITIAL.

    READ TABLE gt_qpmt INTO gs_qpmt WITH KEY
                zaehler = yqm_plty_limit_t-werks
                mkmnr   = yqm_plty_limit_t-verwmerkm.
    IF sy-subrc <> 0.
      SELECT zaehler mkmnr sprache kurztext FROM qpmt
        INTO TABLE gt_qpmt_h
             UP TO 1 ROWS
             WHERE zaehler = yqm_plty_limit_t-werks
             AND   mkmnr   = yqm_plty_limit_t-verwmerkm
             AND   sprache = sy-langu
             ORDER BY version DESCENDING.
      IF sy-subrc = 0.
        READ TABLE gt_qpmt_h INTO gs_qpmt INDEX 1.
        IF sy-subrc = 0.
          APPEND gs_qpmt TO gt_qpmt.
        ENDIF.
      ELSE.
        CLEAR gs_qpmt.
      ENDIF.
    ENDIF.
  ELSE.
    CLEAR gs_qpmt.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  FLTP_CHAR_CONV_400  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE fltp_char_conv_400 OUTPUT.

  yqm_plty_limit_t = <vim_extract_struc>.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-mittelwert
                yqm_plty_limit_t-mittelwni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-mittelwert.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-stdaw
                'X'
                c_stellen
       CHANGING yqm_plty_limits_display-stdaw.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-plausiunte
                'X' "yqm_plty_limit-plausiunni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-plausiunte.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-plausioben
                'X' "yqm_plty_limit-plausiobni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-plausioben.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-messwert01
                yqm_plty_limit_t-messwert01ni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-messwert01.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-messwert02
                yqm_plty_limit_t-messwert02ni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-messwert02.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-messwert03
                yqm_plty_limit_t-messwert03ni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-messwert03.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-messwert04
                yqm_plty_limit_t-messwert04ni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-messwert04.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-messwert05
                yqm_plty_limit_t-messwert05ni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-messwert05.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-messwert06
                yqm_plty_limit_t-messwert06ni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-messwert06.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-messwert07
                yqm_plty_limit_t-messwert07ni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-messwert07.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-messwert08
                yqm_plty_limit_t-messwert08ni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-messwert08.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-messwert09
                yqm_plty_limit_t-messwert09ni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-messwert09.

  PERFORM fltp_char_conversion IN PROGRAM sapfq00a
          USING yqm_plty_limit_t-messwert10
                yqm_plty_limit_t-messwert10ni
                yqm_plty_limit_t-stellen
       CHANGING yqm_plty_limits_display-messwert10.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  READ_IFLOT_TEXT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_iflot_text OUTPUT.

  DATA: lv_tplnr TYPE tplnr.

  IF  NOT yqm_tpln_excl_t-tplnr      IS INITIAL.
    lv_tplnr = yqm_tpln_excl_t-tplnr.
  ELSEIF NOT yqm_vnltkt_t-tplnr IS INITIAL.
    lv_tplnr = yqm_vnltkt_t-tplnr.
  ELSE.
    CLEAR lv_tplnr.
  ENDIF.

  IF NOT lv_tplnr IS INITIAL.

    READ TABLE gt_iflotx INTO gs_iflotx WITH KEY
                tplnr = lv_tplnr.
    IF sy-subrc <> 0.
      SELECT SINGLE tplnr spras pltxt FROM iflotx
        INTO CORRESPONDING FIELDS OF gs_iflotx
             WHERE tplnr = lv_tplnr
             AND   spras = sy-langu.
      IF sy-subrc = 0.
        APPEND gs_iflotx TO gt_iflotx.
      ELSE.
        CLEAR gs_iflotx-pltxt.
        APPEND gs_iflotx TO gt_iflotx.
      ENDIF.
    ENDIF.
  ELSE.
    CLEAR gs_iflotx.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  READ_MATERIAL_TEXT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_material_text OUTPUT.

  DATA: lv_matnr TYPE matnr.

  IF  NOT yqm_matn_excl_t-matnr      IS INITIAL.
    lv_matnr = yqm_matn_excl_t-matnr.
  ELSEIF NOT yqm_matn_tx_t-matnr IS INITIAL.
    lv_matnr = yqm_matn_tx_t-matnr .
  ELSE.
    CLEAR lv_matnr.
  ENDIF.

  IF NOT lv_matnr IS INITIAL.
    READ TABLE gt_makt INTO gs_makt WITH KEY
                matnr = lv_matnr.
    IF sy-subrc <> 0.
      SELECT SINGLE matnr spras maktx FROM makt
        INTO CORRESPONDING FIELDS OF gs_makt
             WHERE matnr = lv_matnr
             AND   spras = sy-langu.
      IF sy-subrc = 0.
        APPEND gs_makt TO gt_makt.
      ELSE.
        CLEAR gs_makt-maktx.
        APPEND gs_makt TO gt_makt.
      ENDIF.
    ENDIF.
  ELSE.
    CLEAR gs_makt.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module LESE_QPMK OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE lese_qpmk OUTPUT.

  DATA lt_qpmk TYPE STANDARD TABLE OF qpmk-sortfeld WITH EMPTY KEY.

  CLEAR qpmk-sortfeld.

  SELECT sortfeld
    FROM qpmk
    WHERE zaehler = '1011'
      AND mkmnr   = @yqm_matn_mk_t-merkmal
    ORDER BY version DESCENDING
    INTO TABLE @lt_qpmk
    UP TO 1 ROWS.
  IF sy-subrc <> 0.
    CLEAR lt_qpmk.
  ENDIF.

  READ TABLE lt_qpmk INTO qpmk-sortfeld INDEX 1.
  IF sy-subrc <> 0.
    CLEAR qpmk-sortfeld.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module READ_MATERIAL_TEXT_1440 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE read_material_text_1440 OUTPUT.

  CLEAR gs_makt.

  IF  NOT yqm_kosten4_t-matnr      IS INITIAL.
    lv_matnr = yqm_kosten4_t-matnr.
  ELSEIF NOT yqm_kosten4_t-matnr IS INITIAL.
    lv_matnr = yqm_kosten4_t-matnr .
  ELSE.
    CLEAR lv_matnr.
  ENDIF.

  IF NOT lv_matnr IS INITIAL.
    READ TABLE gt_makt INTO gs_makt WITH KEY
                matnr = lv_matnr.
    IF sy-subrc <> 0.
      SELECT SINGLE matnr spras maktx FROM makt
        INTO CORRESPONDING FIELDS OF gs_makt
             WHERE matnr = lv_matnr
             AND   spras = sy-langu.
      IF sy-subrc = 0.
        APPEND gs_makt TO gt_makt.
      ELSE.
        CLEAR gs_makt-maktx.
        APPEND gs_makt TO gt_makt.
      ENDIF.
    ENDIF.
  ELSE.
    CLEAR gs_makt.
  ENDIF.

  yqm_kosten4_t-ktext = gs_makt-maktx.

ENDMODULE.
