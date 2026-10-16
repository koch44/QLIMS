*----------------------------------------------------------------------*
***INCLUDE LYQMLIMS_CERTF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  LESE_IHPA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GS_QALS_AUFNR  text
*      <--P_LV_PARNR  text
*      <--P_SY_SUBRC  text
*----------------------------------------------------------------------*
FORM lese_ihpa  USING    iv_aufnr
                CHANGING cv_parnr
                         cv_subrc.

  DATA: lv_objnr TYPE aufk-objnr.
*        lv_parnr TYPE ihpa-parnr.

  CLEAR: cv_subrc, cv_parnr.

  lv_objnr   = 'OR'.
  lv_objnr+2 = iv_aufnr.

* Instandhaltungspartner
  READ TABLE gt_ihpa INTO gs_ihpa WITH KEY objnr = lv_objnr.
  IF sy-subrc <> 0.
* ermitteln partner aus Instandhaltung Partner Tabelle
    SELECT SINGLE * FROM ihpa INTO CORRESPONDING FIELDS OF gs_ihpa
      WHERE objnr = lv_objnr
        AND parvw = 'ZL'.
    IF sy-subrc = 0.
      APPEND gs_ihpa TO gt_ihpa.
    ENDIF.
  ENDIF.
  cv_subrc = sy-subrc.
  CHECK sy-subrc = 0.
  cv_parnr = gs_ihpa-parnr.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  LESE_SDAUFTRAG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GS_QALS_KDAUF  text
*      <--P_LV_PARNR  text
*      <--P_SY_SUBRC  text
*      <--P_LV_ADRNR  text
*----------------------------------------------------------------------*
FORM lese_sdauftrag  USING    iv_kdauf
                     CHANGING cv_parnr
                              cv_subrc
                              cv_adrnr.
  DATA: lv_vbpa TYPE vbpa.

  STATICS: lv_it_vbpa TYPE TABLE OF vbpa.
  CLEAR: cv_parnr, cv_subrc, cv_adrnr.
  READ TABLE lv_it_vbpa INTO lv_vbpa WITH KEY vbeln = iv_kdauf.
  IF sy-subrc <> 0.
    SELECT SINGLE * INTO lv_vbpa
       FROM vbpa WHERE vbeln = iv_kdauf
                   AND posnr = '000000'
                   AND parvw = 'WE'.
    IF sy-subrc = 0.
      APPEND lv_vbpa TO lv_it_vbpa.
    ENDIF.
  ENDIF.
  cv_subrc = sy-subrc.
  cv_parnr = lv_vbpa-kunnr.
  cv_adrnr = lv_vbpa-adrnr.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  LESE_DEBITOR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LV_KUNNR  text
*      -->P_LV_ADRNR  text
*      <--P_GS_ADRC  text
*----------------------------------------------------------------------*
FORM lese_debitor USING iv_kunnr
                        iv_adrnr
               CHANGING cs_adrc TYPE adrc.

  DATA: lv_adrnr TYPE kna1-adrnr.
  DATA: ls_kna1  TYPE kna1.

  SELECT SINGLE * FROM kna1 INTO ls_kna1 WHERE kunnr = iv_kunnr.
  IF sy-subrc = 0.
    IF iv_adrnr IS INITIAL.
      lv_adrnr = ls_kna1-adrnr.
    ELSE.
      lv_adrnr = iv_adrnr.
    ENDIF.

    SELECT SINGLE * FROM adrc INTO cs_adrc
       WHERE addrnumber = lv_adrnr.
    IF sy-subrc = 0.
      CONCATENATE cs_adrc-street cs_adrc-house_num1 INTO cs_adrc-street
        SEPARATED BY space.
    ENDIF.
  ELSE.
    CLEAR lv_adrnr.
  ENDIF.


ENDFORM.
