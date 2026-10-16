*&---------------------------------------------------------------------*
*& Include          ZXQQMU07
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
*   Datendefinitionen
*----------------------------------------------------------------------*
TABLES: equz.
*----------------------------------------------------------------------*
*   Verarbeitung
*----------------------------------------------------------------------*
gv_aktyp = i_aktyp.

CASE viqmel-qmart.
  WHEN 'H1' OR 'H2' OR 'H3'.
    IF NOT ( viqmel-equnr IS INITIAL ).
      SELECT tidnr FROM equz
            INTO CORRESPONDING FIELDS OF equz
            WHERE equnr = viqmel-equnr.
      ENDSELECT.
      IF sy-subrc IS NOT INITIAL.
        CLEAR equz-tidnr.
      ENDIF.
    ENDIF.
  WHEN 'I1' OR 'TS'.
**---------------------------------------------------------------------
** für YI0029 IW21-IPG Kundenerweiterungen-Wertegrenzen WBG (Me.art I1)
** (Meldungsart I1)
**---------------------------------------------------------------------
**   INCLUDE yiqqmu07_i1.                                    "KE20012008
*    IF ( NOT viqmel-tplnr IS INITIAL ) AND                  "KE20012008
*        viqmel-tplnr NE gv_tplnr_save.                      "KE20012008
**--------------------------------------Selektionsbed.für FUBA(T.P)füllen
*      gv_tplnr_save = viqmel-tplnr.                         "KE20012008
*      CLEAR: gs_tplnr,                                      "KE20012008
*             gt_tplnr,                                      "KE20012008
*             gt_gtpl_lber,                                  "KE20012008
*             gt_gauftrag.                                   "KE20012008
*      gs_tplnr-sign   = 'I'.                                "KE20012008
*      gs_tplnr-option = 'EQ'.                               "KE20012008
*      gs_tplnr-low    = viqmel-tplnr.                       "KE20012008
*      APPEND gs_tplnr TO gt_tplnr.                          "KE20012008
*      gv_grid = gc_on.                                      "KE20012008
*      PERFORM erzeugen_ausgabe                              "KE20012008
*              IN PROGRAM yi0029 IF FOUND                    "KE20012008
*              TABLES gt_tplnr                               "KE20012008
*                     gt_gtpl_lber                           "KE20012008
*                     gt_gauftrag                            "KE20012008
*              USING  ' '           "PAANZROT                "KE20012008
*                     'X'           "PAEINZEL                "KE20012008
*                     ' '           "PAUAUFT                 "KE20012008
*                     ' '           "PAVJAHR                 "KE16102009
*                     gv_grid.                               "KE20012008
*    ENDIF.                                                  "KE20012008
  WHEN OTHERS.
ENDCASE.
