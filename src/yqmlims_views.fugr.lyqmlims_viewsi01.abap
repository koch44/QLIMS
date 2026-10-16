*----------------------------------------------------------------------*
***INCLUDE LYQMLIMS_VIEWSI01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  F4_PMETHODE_101  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_pmethode_101 INPUT.

  DATA: ls_qpmz           TYPE qpmz.
  DATA: lv_line           TYPE sy-loopc.
  DATA: ls_extract        TYPE text256.

  GET CURSOR LINE lv_line.

  READ TABLE extract INTO ls_extract INDEX lv_line.
  IF sy-subrc = 0.
    yqm_spez_pmk_t-qpmk_zaehl = ls_extract+11(4).
    yqm_spez_pmk_t-verwmerkm  = ls_extract+15(8).

    CALL FUNCTION 'QPSD_FEATURE_VALID_READ'
      EXPORTING
        kz_aufloesung    = 'X'
        merkmal          = yqm_spez_pmk_t-verwmerkm
        werk             = yqm_spez_pmk_t-qpmk_zaehl
      IMPORTING
        qpmz_exp         = ls_qpmz
      EXCEPTIONS
        no_feature       = 1
        no_valid         = 2
        no_authorization = 3
        OTHERS           = 4.
    IF sy-subrc = 0.
      yqm_spez_pmk_t-qmtb_werks = ls_qpmz-werkpm.
      yqm_spez_pmk_t-pmethode   = ls_qpmz-pmethode.
*    yqm_spez_pmk_t-pmtversion = ls_qpmz-verspm.
    ENDIF.
  ENDIF.
ENDMODULE.                 " F4_PMETHODE_101  INPUT
*&---------------------------------------------------------------------*
*&      Module  F4_PMETHODE_102  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_pmethode_102 INPUT.

  CALL FUNCTION 'QPSD_FEATURE_VALID_READ'
    EXPORTING
      kz_aufloesung    = 'X'
      merkmal          = yqm_spez_pmk_t-verwmerkm
      werk             = yqm_spez_pmk_t-qpmk_zaehl
    IMPORTING
      qpmz_exp         = ls_qpmz
    EXCEPTIONS
      no_feature       = 1
      no_valid         = 2
      no_authorization = 3
      OTHERS           = 4.
  IF sy-subrc = 0.
    yqm_spez_pmk_t-qmtb_werks = ls_qpmz-werkpm.
    yqm_spez_pmk_t-pmethode   = ls_qpmz-pmethode.
*    yqm_spez_pmk_t-pmtversion = ls_qpmz-verspm.
  ENDIF.

ENDMODULE.                 " F4_PMETHODE_102  INPUT
*&---------------------------------------------------------------------*
*&      Module  SET_ERSTELLER  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_ersteller INPUT.

  IF NOT yqm_plty_excl_t-verwmerkm IS INITIAL
     AND yqm_plty_excl_t-ersteller IS INITIAL.
    yqm_plty_excl_t-ersteller  = sy-uname.
    yqm_plty_excl_t-erstelldat = sy-datlo.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  CALC_NEW_LIMITS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE calc_new_limits INPUT.

  DATA: ls_vektor       TYPE LINE OF tvst_ftab.
  DATA: lt_vektor       TYPE tvst_ftab.

  CLEAR lt_vektor[].

  IF NOT yqm_plty_limit_t-messwert01ni IS INITIAL.
    ls_vektor-flt = yqm_plty_limit_t-messwert01.
    APPEND ls_vektor TO lt_vektor.
  ENDIF.
  IF NOT yqm_plty_limit_t-messwert02ni IS INITIAL.
    ls_vektor-flt = yqm_plty_limit_t-messwert02.
    APPEND ls_vektor TO lt_vektor.
  ENDIF.
  IF NOT yqm_plty_limit_t-messwert03ni IS INITIAL.
    ls_vektor-flt = yqm_plty_limit_t-messwert03.
    APPEND ls_vektor TO lt_vektor.
  ENDIF.
  IF NOT yqm_plty_limit_t-messwert04ni IS INITIAL.
    ls_vektor-flt = yqm_plty_limit_t-messwert04.
    APPEND ls_vektor TO lt_vektor.
  ENDIF.
  IF NOT yqm_plty_limit_t-messwert05ni IS INITIAL.
    ls_vektor-flt = yqm_plty_limit_t-messwert05.
    APPEND ls_vektor TO lt_vektor.
  ENDIF.
  IF NOT yqm_plty_limit_t-messwert06ni IS INITIAL.
    ls_vektor-flt = yqm_plty_limit_t-messwert06.
    APPEND ls_vektor TO lt_vektor.
  ENDIF.
  IF NOT yqm_plty_limit_t-messwert07ni IS INITIAL.
    ls_vektor-flt = yqm_plty_limit_t-messwert07.
    APPEND ls_vektor TO lt_vektor.
  ENDIF.
  IF NOT yqm_plty_limit_t-messwert08ni IS INITIAL.
    ls_vektor-flt = yqm_plty_limit_t-messwert08.
    APPEND ls_vektor TO lt_vektor.
  ENDIF.
  IF NOT yqm_plty_limit_t-messwert09ni IS INITIAL.
    ls_vektor-flt = yqm_plty_limit_t-messwert09.
    APPEND ls_vektor TO lt_vektor.
  ENDIF.
  IF NOT yqm_plty_limit_t-messwert10ni IS INITIAL.
    ls_vektor-flt = yqm_plty_limit_t-messwert10.
    APPEND ls_vektor TO lt_vektor.
  ENDIF.

  CALL FUNCTION 'TV_VOLA_CALC'
    IMPORTING
      sigma                   = yqm_plty_limit_t-stdaw
      my                      = yqm_plty_limit_t-mittelwert
    TABLES
      vektor                  = lt_vektor
    EXCEPTIONS
      no_entries_in_table     = 1
      only_one_entry_in_table = 2
      OTHERS                  = 3.
  IF sy-subrc = 0.
* Implement suitable error handling here
    yqm_plty_limit_t-mittelwni    = 'X'.
    yqm_plty_limit_t-plausiunte   = yqm_plty_limit_t-mittelwert
                                - ( 2 * yqm_plty_limit_t-stdaw ).
*    yqm_plty_limit_t-plausiunni   = 'X'.

    yqm_plty_limit_t-plausioben   = yqm_plty_limit_t-mittelwert
                                + ( 2 * yqm_plty_limit_t-stdaw ).
*    yqm_plty_limit_t-plausiobni   = 'X'.
  ELSE.
    CLEAR yqm_plty_limit_t-mittelwert.
    CLEAR yqm_plty_limit_t-mittelwni.
    CLEAR yqm_plty_limit_t-stdaw.
    CLEAR yqm_plty_limit_t-plausiunte.
    CLEAR yqm_plty_limit_t-plausiunni.
    CLEAR yqm_plty_limit_t-plausioben.
    CLEAR yqm_plty_limit_t-plausiobni.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  SET_ERSTELLER_2  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_ersteller_2 INPUT.

  IF NOT yqm_tpln_excl_t-tplnr IS INITIAL.
    yqm_tpln_excl_t-ersteller  = sy-uname.
    yqm_tpln_excl_t-erstelldat = sy-datlo.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  SET_ERSTELLER_3  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_ersteller_3 INPUT.

  IF NOT yqm_matn_excl_t-matnr IS INITIAL.
    yqm_matn_excl_t-ersteller  = sy-uname.
    yqm_matn_excl_t-erstelldat = sy-datlo.
  ENDIF.

ENDMODULE.
