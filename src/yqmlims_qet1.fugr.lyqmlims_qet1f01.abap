*----------------------------------------------------------------------*
***INCLUDE LQET1F01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  SAVE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SAVE.

  DATA:
    L_E_MSG_COUNTER LIKE SY-TABIX,
    L_W_MSG_COUNTER LIKE SY-TABIX,
    L_I_MSG_COUNTER LIKE SY-TABIX.

  CALL FUNCTION 'QET4_OK_CODE_SAVE'
       IMPORTING
            E_MSG_COUNTER = L_E_MSG_COUNTER
            W_MSG_COUNTER = L_W_MSG_COUNTER
            I_MSG_COUNTER = L_I_MSG_COUNTER.

  IF L_E_MSG_COUNTER = 0.
    IF  L_W_MSG_COUNTER > 0
     OR L_I_MSG_COUNTER > 0.
      MESSAGE S004 WITH L_E_MSG_COUNTER
                        L_W_MSG_COUNTER
                        L_I_MSG_COUNTER.
* Protokoll enthält & Fehler-, & Warn- und & Infomeldungen
    ENDIF.
  ELSE.
    CALL FUNCTION 'QET4_OK_CODE_SHOW_PROTOCOL'.
  ENDIF.

  CALL FUNCTION 'Y_QMLIMS_QET5_SAVE_DATA'.  "<<<< INSERT CF

ENDFORM.                               " SAVE
*&---------------------------------------------------------------------*
*&      Form  SELECT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SELECT TABLES T_SPECSTAB STRUCTURE QETBCELLS
                   T_RESULTSTAB  STRUCTURE QETBCELLS.

  CALL FUNCTION 'Y_QMLIMS_QET1_OPEN_CHAR'
       EXPORTING
            I_ROW_NO  = G_ROW_NO
            I_COL_NO  = G_COL_NO
            I_AREA    = G_AREA
            I_OK_CODE = G_OK_CODE
       TABLES
            T_SPECS   = T_SPECSTAB
            T_RESULTS = T_RESULTSTAB.

ENDFORM.                               " SELECT

*&---------------------------------------------------------------------*
*&      Form  SHOW_PROTOCOL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SHOW_PROTOCOL.

  CALL FUNCTION 'QET4_OK_CODE_SHOW_PROTOCOL'.

ENDFORM.                               " SHOW_PROTOCOL
*&---------------------------------------------------------------------*
*&      Form  REMARK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM REMARK TABLES T_SPECSTAB   STRUCTURE QETBCELLS
                   T_RESULTSTAB STRUCTURE QETBCELLS.

  CALL FUNCTION 'Y_QMLIMS_QET1_REMARK'
       EXPORTING
            I_ROW_NO  = G_ROW_NO
            I_COL_NO  = G_COL_NO
            I_AREA    = G_AREA
       TABLES
            T_SPECS   = T_SPECSTAB
            T_RESULTS = T_RESULTSTAB.

ENDFORM.                               " REMARK
*&---------------------------------------------------------------------*
*&      Form  JUMP_RESULTRECORDING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM JUMP_RESULTRECORDING TABLES T_SPECSTAB STRUCTURE QETBCELLS
                                 T_RESULTSTAB STRUCTURE QETBCELLS.

  CALL FUNCTION 'Y_QMLIMS_QET1_JUMP_RESULTREC'
       EXPORTING
            I_ROW_NO    = G_ROW_NO
            I_COL_NO    = G_COL_NO
            I_AREA      = G_AREA
            I_OK_CODE   = G_OK_CODE
       TABLES
            T_SPECS     = T_SPECSTAB
            T_RESULTS   = T_RESULTSTAB
       EXCEPTIONS
            NO_JUMP_RR  = 1
            NO_LOT_OPER = 2
            NO_IP       = 3
            OTHERS      = 4.

  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO.
  ENDIF.

ENDFORM.                               " JUMP_RESULTRECORDING

*&---------------------------------------------------------------------*
*&      Form  CHECK_CURSOR_ON_RESULTS_FIELD
*&---------------------------------------------------------------------*
*       Überprüft, ob der Cursor in einem Ergebnisfeld steht
*----------------------------------------------------------------------*
*      -->P_T_RESULTS  text
*      -->P_I_ROW_NO  text
*      -->P_I_COL_NO  text
*      -->P_I_AREA  text
*----------------------------------------------------------------------*
FORM CHECK_CURSOR_ON_RESULTS_FIELD
             TABLES   T_RESULTS STRUCTURE QETBCELLS
             USING    I_ROW_NO     LIKE      SY-CUROW
                      I_COL_NO     LIKE      SY-CUCOL
                      I_AREA       LIKE      SY-TNAME
             CHANGING E_SUBRC      LIKE      SY-SUBRC.

  DATA: L_REQUIREMENTS TYPE BAPI2045D1.
  DATA: L_CELLS TYPE QETBCELLS.

* check cursor area
  E_SUBRC = 1.
  IF NOT I_AREA = 'CON_RESULTS'.
    MESSAGE S013.
    EXIT.
  ENDIF.

* read resultstab
  E_SUBRC = 2.
  READ TABLE T_RESULTS INTO L_CELLS
           WITH KEY ROW_NO = I_ROW_NO
                    COL_NO = I_COL_NO.

  IF SY-SUBRC <> 0.
    MESSAGE S012.
    EXIT.
  ENDIF.

* read requirements for characteristic
  E_SUBRC = 3.
  CALL FUNCTION 'QET4_GET_CHAR_REQUIREMENTS'
       EXPORTING
            I_INSPLOT      = L_CELLS-INSPLOT
            I_INSPOPER     = L_CELLS-INSPOPER
            I_INSPCHAR     = L_CELLS-INSPCHAR
       IMPORTING
            E_REQUIREMENTS = L_REQUIREMENTS
       EXCEPTIONS
            NOT_FOUND      = 1
            OTHERS         = 2.
  IF SY-SUBRC <> 0.
    MESSAGE S013.
    EXIT.
  ENDIF.

* samples required
  E_SUBRC = 4.
  IF NOT L_REQUIREMENTS-SAMPLE_RES IS INITIAL
     AND NOT L_REQUIREMENTS-INSP_POINT IS INITIAL.
    IF L_CELLS-INSPSAMPLE IS INITIAL.
      MESSAGE S013.
      EXIT.
    ENDIF.
  ENDIF.

* cursor position is valid
  CLEAR E_SUBRC.

ENDFORM.                               " CHECK_CURSOR_ON_RESULTS_FIELD

*&---------------------------------------------------------------------*
*&      Form  CLOSE_AND_SAVE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CLOSE_AND_SAVE TABLES T_SPECSTAB STRUCTURE QETBCELLS
                           T_RESULTSTAB STRUCTURE QETBCELLS.

  CALL FUNCTION 'QET4_OK_CODE_CLOSE'
       EXPORTING
            I_ROW_NO  = G_ROW_NO
            I_COL_NO  = G_COL_NO
            I_AREA    = G_AREA
            I_OK_CODE = G_OK_CODE
       TABLES
            T_SPECS   = T_SPECSTAB
            T_RESULTS = T_RESULTSTAB.

* Save changes
  PERFORM SAVE.

ENDFORM.                               " CLOSE_AND_SAVE

*&---------------------------------------------------------------------*
*&      Form  PAGE_UP_OR_DOWN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM PAGE_UP_OR_DOWN.

  CALL FUNCTION 'Y_QMLIMS_QET5_PAGE_UP_OR_DOWN'
       EXPORTING
            I_AREA       = G_AREA
            I_OK_CODE    = G_OK_CODE
       EXCEPTIONS
            NO_SCROLLING = 1
            OTHERS       = 2.

  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO.
  ENDIF.

ENDFORM.                               " PAGE_UP_OR_DOWN

*&---------------------------------------------------------------------*
*&      Form  PAGE_LEFT_OR_RIGHT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM PAGE_LEFT_OR_RIGHT.

  CALL FUNCTION 'Y_QMLIMS_QET5_PAGE_LEFT_RIGHT'
       EXPORTING
            I_OK_CODE = G_OK_CODE.

ENDFORM.                               " PAGE_LEFT_OR_RIGHT

*&---------------------------------------------------------------------*
*&      Form  JUMP_CONTROL_CHART
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_SPECS  text
*      -->P_T_RESULTS  text
*----------------------------------------------------------------------*
FORM JUMP_CONTROL_CHART TABLES T_SPECSTAB STRUCTURE QETBCELLS
                               T_RESULTS  STRUCTURE QETBCELLS.

  DATA:
    L_REQUIREMENTS LIKE BAPI2045D1,
    L_CC_NO LIKE BAPI2045D1-CC_NO,
    L_VORGLFNR LIKE QAPO-VORGLFNR,
    L_SUBRC LIKE SY-SUBRC.

  PERFORM CHECK_RIGHT_FIELD TABLES    T_SPECSTAB
                                      T_RESULTS
                            CHANGING  L_SUBRC.

  IF NOT L_SUBRC IS INITIAL.
    EXIT.
  ENDIF.

  CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
       EXPORTING
            I_CELLS             = T_RESULTS
       IMPORTING
            E_CHAR_REQUIREMENTS = L_REQUIREMENTS.

* Control chart on characteristic level
  L_CC_NO = L_REQUIREMENTS-CC_NO.

* Control chart on sample level?
  IF L_CC_NO < 1 AND NOT T_RESULTS-INSPSAMPLE IS INITIAL.

*   Get internal operation number
    CALL FUNCTION 'QIBP_GET_VORGLFNR'
         EXPORTING
              I_INSP_LOT = T_RESULTS-INSPLOT
              I_OPER_NO  = T_RESULTS-INSPOPER
         IMPORTING
              E_VORGLFNR = L_VORGLFNR.

*   Read sample requirements
    SELECT SINGLE * FROM QASV
     WHERE PRUEFLOS = T_RESULTS-INSPLOT
       AND VORGLFNR = L_VORGLFNR
       AND MERKNR   = T_RESULTS-INSPCHAR
       AND PROBENR  = T_RESULTS-INSPSAMPLE.

    IF SY-SUBRC IS INITIAL.
      L_CC_NO = QASV-QRKNR.
    ENDIF.
  ENDIF.

* No control chart found
  IF L_CC_NO < 1.
    MESSAGE S008.
    EXIT.
  ENDIF.

  CALL FUNCTION 'QRKD_CONTROL_CHART'
       EXPORTING
            I_QRKNR           = L_CC_NO
            I_DISPLAY_MODE    = 'X'
            I_OLD_GRAPHICS    = 'X'
       IMPORTING
            E_CONTROL_CHART_ACTIVE = G_CLOSE_GRAPHICS
       EXCEPTIONS
            NO_ENTRY_IN_QASH  = 1
            NO_ENTRY_IN_QAST  = 2
            NO_ENTRY_IN_QPSH  = 3
            NO_ENTRY_IN_QPST  = 4
            INVALID_STRUCTURE = 5
            PROGRAMMING_ERROR = 6
            FOREIGN_LOCK      = 7
            NO_AUTHORIZATION  = 8
            OTHERS            = 9.
  IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                               " JUMP_CONTROL_CHART

*&---------------------------------------------------------------------*
*&      Form  USER_OK_CODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_SPECS  text
*      -->P_T_RESULTS  text
*----------------------------------------------------------------------*
FORM USER_OK_CODE TABLES   P_SPECSTAB   STRUCTURE QETBCELLS
                           P_RESULTSTAB STRUCTURE QETBCELLS.
  PERFORM USER_OK_CODE IN PROGRAM (G_SCREEN_MANAGER)
          TABLES   P_SPECSTAB P_RESULTSTAB
          CHANGING G_ROW_NO G_COL_NO G_AREA G_OK_CODE.

ENDFORM.                               " USER_OK_CODE

*&---------------------------------------------------------------------*
*&      Form  CALL_STI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_SPECS  text
*      -->P_T_RESULTS  text
*----------------------------------------------------------------------*
FORM CALL_STI TABLES   P_SPECSTAB STRUCTURE QETBCELLS
                       P_RESULTS  STRUCTURE QETBCELLS.

  DATA:
    L_REQUIREMENTS     LIKE BAPI2045D1,
    L_SAMPLE_RESULTS   LIKE BAPI2045D3,
    L_CHAR_RESULTS     LIKE BAPI2045D2,
    L_QASVTAB          LIKE QASV OCCURS 0 WITH HEADER LINE,
    L_QASV_KEYS        LIKE QASV OCCURS 0 WITH HEADER LINE,
    L_FOUND            TYPE C,
    L_VORGLFNR         LIKE QASV-VORGLFNR,
    L_SUBRC            LIKE SY-SUBRC.

  PERFORM CHECK_RIGHT_FIELD TABLES    P_SPECSTAB
                                      P_RESULTS
                            CHANGING  L_SUBRC.

  IF NOT L_SUBRC IS INITIAL.
    EXIT.
  ENDIF.

  CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
       EXPORTING
            I_CELLS             = P_RESULTS
       IMPORTING
            E_CHAR_REQUIREMENTS = L_REQUIREMENTS.

  IF L_REQUIREMENTS-CHAR_TYPE NE '01'.
    MESSAGE S022.
    EXIT.
  ENDIF.

  IF L_REQUIREMENTS-SINGLE_RES NE 'X'.
    MESSAGE S023.
    EXIT.
  ENDIF.

* interne Vorgangsnummer ermitteln
  CALL FUNCTION 'QIBP_GET_VORGLFNR'
       EXPORTING
            I_INSP_LOT = L_REQUIREMENTS-INSPLOT
            I_OPER_NO  = L_REQUIREMENTS-INSPOPER
       IMPORTING
            E_VORGLFNR = L_VORGLFNR.

* Probenergebnisse
  IF    NOT L_REQUIREMENTS-SAMPLES IS INITIAL
     OR NOT L_REQUIREMENTS-INSP_POINT IS INITIAL.

*   Schleife über alle Proben
    L_FOUND = 'X'.
    WHILE NOT L_FOUND IS INITIAL.

      CALL FUNCTION 'QET4_GET_SAMPLE_RESULTS'
           EXPORTING
                I_NUMBER         = SY-INDEX
           IMPORTING
                E_SAMPLE_RESULTS = L_SAMPLE_RESULTS
           EXCEPTIONS
                OTHERS           = 1.
      IF NOT SY-SUBRC IS INITIAL.
        CLEAR L_FOUND.
        EXIT.
      ENDIF.

*     Proben dieses Merkmales übernehmen
      CHECK L_SAMPLE_RESULTS-INSPLOT  = L_REQUIREMENTS-INSPLOT.
      CHECK L_SAMPLE_RESULTS-INSPOPER = L_REQUIREMENTS-INSPOPER.
      CHECK L_SAMPLE_RESULTS-INSPCHAR = L_REQUIREMENTS-INSPCHAR.

      L_QASV_KEYS-PRUEFLOS = L_SAMPLE_RESULTS-INSPLOT.
      L_QASV_KEYS-VORGLFNR = L_VORGLFNR.
      L_QASV_KEYS-MERKNR   = L_SAMPLE_RESULTS-INSPCHAR.
      L_QASV_KEYS-PROBENR  = L_SAMPLE_RESULTS-INSPSAMPLE.
      APPEND  L_QASV_KEYS.

    ENDWHILE.

* Merkmalsergebnisse
  ELSE.

    L_FOUND = 'X'.
    WHILE NOT L_FOUND IS INITIAL.
      CALL FUNCTION 'QET4_GET_CHAR_RESULTS'
           EXPORTING
                I_NUMBER       = SY-INDEX
           IMPORTING
                E_CHAR_RESULTS = L_CHAR_RESULTS
           EXCEPTIONS
                OTHERS         = 1.
      IF NOT SY-SUBRC IS INITIAL.
        CLEAR L_FOUND.
        EXIT.
      ENDIF.

*     Proben dieses Merkmales übernehmen
      CHECK L_CHAR_RESULTS-INSPLOT  = L_REQUIREMENTS-INSPLOT.
      CHECK L_CHAR_RESULTS-INSPOPER = L_REQUIREMENTS-INSPOPER.
      CHECK L_CHAR_RESULTS-INSPCHAR = L_REQUIREMENTS-INSPCHAR.

      L_QASV_KEYS-PRUEFLOS = L_CHAR_RESULTS-INSPLOT.
      L_QASV_KEYS-VORGLFNR = L_VORGLFNR.
      L_QASV_KEYS-MERKNR = L_CHAR_RESULTS-INSPCHAR.
      L_QASV_KEYS-PROBENR = 0.
      APPEND  L_QASV_KEYS.

    ENDWHILE.

  ENDIF.

* QASV-Sätze von der Datenbank lesen
  DESCRIBE TABLE L_QASV_KEYS LINES SY-TABIX.
  IF SY-TABIX > 0.
    SELECT * FROM QASV
        INTO TABLE L_QASVTAB
        FOR ALL ENTRIES IN L_QASV_KEYS
        WHERE PRUEFLOS = L_QASV_KEYS-PRUEFLOS
          AND VORGLFNR = L_QASV_KEYS-VORGLFNR
          AND MERKNR   = L_QASV_KEYS-MERKNR
          AND PROBENR  = L_QASV_KEYS-PROBENR.
  ENDIF.

* STI-Schnittstelle aufrufen
  CALL FUNCTION 'QIST_CALL_QM_STI'
*    EXPORTING
*         I_TITLE           =
*         I_SUBTITLE        =
*         I_LABEL_X         =
*         I_LABEL_Y         =
*         I_NO_DIALOG       =
       TABLES
            I_QASVTAB         = L_QASVTAB
       EXCEPTIONS
            RFCDEST_NOT_EXIST = 1
            RFCDEST_NOT_VALID = 2
            METHOD_NOT_EXIST  = 3
            METHOD_NOT_ACTIVE = 4
            NO_METHOD         = 5
            NO_RFCDEST        = 6
            NO_DATA           = 7
            OTHERS            = 8.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                               " CALL_STI

*&---------------------------------------------------------------------*
*&      Form  CALL_HISTORIE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_SPECS  text
*      -->P_T_RESULTS  text
*----------------------------------------------------------------------*
FORM CALL_HISTORIE TABLES   P_SPECSTAB STRUCTURE QETBCELLS
                            P_RESULTS  STRUCTURE QETBCELLS.
  DATA:
    L_CHARG LIKE QALS-CHARG,
    L_QALS  LIKE QALS,
    L_QAPO  LIKE QAPO,
    L_QAMV  LIKE QAMV,
    L_QAPP  LIKE QAPP,
    L_SUBRC LIKE SY-SUBRC.

  PERFORM CHECK_RIGHT_FIELD TABLES   P_SPECSTAB
                                     P_RESULTS
                            CHANGING L_SUBRC.

  IF NOT L_SUBRC IS INITIAL.
    EXIT.
  ENDIF.

* Prüflos lesen
  CALL FUNCTION 'QPSE_LOT_READ'
       EXPORTING
            I_PRUEFLOS = P_RESULTS-INSPLOT
       IMPORTING
            E_QALS     = L_QALS.

* Vorgang lesen
  CALL FUNCTION 'QIBP_GET_OPERATION'
       EXPORTING
            I_INSP_LOT           = P_RESULTS-INSPLOT
            I_INSP_LOT_OPERATION = P_RESULTS-INSPOPER
       IMPORTING
            E_QAPO               = L_QAPO.

* Merkmal lesen
  SELECT SINGLE * FROM QAMV INTO L_QAMV
     WHERE PRUEFLOS = L_QAPO-PRUEFLOS
       AND VORGLFNR = L_QAPO-VORGLFNR
       AND MERKNR   = P_RESULTS-INSPCHAR.

* Prüfpunkt lesen
  SELECT SINGLE * FROM QAPP INTO L_QAPP
     WHERE PRUEFLOS = L_QAPO-PRUEFLOS
       AND VORGLFNR = L_QAPO-VORGLFNR
       AND PROBENR = P_RESULTS-INSPSAMPLE.
  IF NOT SY-SUBRC IS INITIAL.
    CLEAR L_QAPP.
  ENDIF.

  IF NOT L_QALS-XCHPF IS INITIAL.
*/--Bei getrennter Bewertung steht im Feld Charge die Bewertungsart
    L_CHARG = L_QALS-CHARG.
  ELSE.
    CLEAR: L_CHARG.
  ENDIF.

  CALL FUNCTION 'QGMK_INSPECTION_HISTORY_SHOW'
       EXPORTING
            I_PRUEFLOS              = L_QALS-PRUEFLOS
            I_HERKUNFT              = L_QALS-HERKUNFT
            I_MATNR                 = L_QALS-MATNR
            I_WERK                  = L_QALS-WERK
            I_PLNTY                 = L_QAPO-PLNTY
            I_PLNNR                 = L_QAPO-PLNNR
            I_PLNAL                 = L_QAPO-PLNAL
            I_PLNFL                 = L_QAPO-PLNFL
            I_PPLNKN                = L_QAPO-PPLNKN
            I_VPLTY                 = L_QAPO-VPLTY
            I_VPLNR                 = L_QAPO-VPLNR
            I_VPLAL                 = L_QAPO-VPLAL
            I_VPLFL                 = L_QAPO-VPLFL
            I_VPLNKN                = L_QAPO-VPLNKN
            I_VORNR                 = L_QAPO-VORNR
            I_VORGLFNR              = L_QAMV-VORGLFNR
            I_MERKNR                = L_QAMV-MERKNR
            I_HERSTELLER            = L_QALS-HERSTELLER
            I_KUNNR                 = L_QALS-KUNNR
            I_LIFNR                 = L_QALS-LIFNR
            I_VIA_SELECTION_SCREEN  = 'X'
            I_QPMK_WERKS            = L_QAMV-QPMK_WERKS
            I_VERWMERKM             = L_QAMV-VERWMERKM
            I_MKVERSION             = L_QAMV-MKVERSION
            I_KURZTEXT              = L_QAMV-KURZTEXT
            I_VORKTXT               = L_QAPO-VORKTXT
            I_STAT07                = L_QALS-STAT07
            I_STAT13                = L_QALS-STAT13
            I_EQUNR                 = L_QAPP-EQUNR
            I_TPLNR                 = L_QAPP-TPLNR
            I_PHYNR                 = L_QAPP-PHYNR
            I_CHARG                 = L_CHARG
       EXCEPTIONS
            INCONSISTENT_PARAMETERS = 0
            INTERNAL_ERROR          = 0
            NO_DATA_FOUND           = 0
            OTHERS                  = 0.

ENDFORM.                               " CALL_HISTORIE
*&---------------------------------------------------------------------*
*&      Form  CHECK_RIGHT_FIELD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SPECSTAB  text
*      -->P_RESULTS  text
*      <->P_SUBRC    text
*----------------------------------------------------------------------*
FORM CHECK_RIGHT_FIELD TABLES  P_SPECSTAB STRUCTURE QETBCELLS
                               P_RESULTS  STRUCTURE QETBCELLS
                       CHANGING VALUE(P_SUBRC) LIKE SY-SUBRC.

  P_SUBRC = 2.

  IF G_AREA NE 'CON_RESULTS'.          "#EC NOTEXT
    MESSAGE S013.
    EXIT.
* Den Cursor auf ein Ergebnisfeld positionieren
  ENDIF.

* aktuelle Zelle lesen
  READ TABLE P_RESULTS WITH KEY
                  ROW_NO = G_ROW_NO
                  COL_NO = G_COL_NO.

  IF NOT SY-SUBRC IS INITIAL.
    MESSAGE S012.
* Es sind keine Daten vorhanden
    EXIT.
  ENDIF.

  IF  P_RESULTS-INSPLOT  IS INITIAL
   OR P_RESULTS-INSPOPER IS INITIAL
   OR P_RESULTS-INSPCHAR IS INITIAL.
    MESSAGE S013.
* Den Cursor auf ein Ergebnisfeld positionieren
    EXIT.
  ENDIF.

  CLEAR P_SUBRC.

ENDFORM.                               " CHECK_RIGHT_FIELD
*&---------------------------------------------------------------------*
*&      Form  LOT_STATUS
*&---------------------------------------------------------------------*
*       Show lot status
*----------------------------------------------------------------------*
*      -->P_T_SPECS  text
*      -->P_T_RESULTS  text
*----------------------------------------------------------------------*
FORM LOT_STATUS TABLES   P_SPECSTAB STRUCTURE QETBCELLS
                         P_RESULTS  STRUCTURE QETBCELLS.

  DATA: L_IONR           LIKE IONR.
  DATA: L_OBJNR          LIKE QALS-OBJNR.

  READ TABLE P_RESULTS INDEX 1.
* Only possible for QE71. There exists only one inspection lot

  L_IONR-OBART = 'QL'.
  L_IONR-OBJID = P_RESULTS-INSPLOT.
  MOVE L_IONR TO L_OBJNR.

  CALL FUNCTION 'QAST_STATUS_MAINTAIN'
       EXPORTING
            I_DISPLAY_ONLY = 'X'
            I_OBJNR        = L_OBJNR.

ENDFORM.                               " LOT_STATUS
*&---------------------------------------------------------------------*
*&      Form  BACK_END
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM BACK_END.

  DATA:
    L_ANSWER        TYPE C,
    L_E_MSG_COUNTER LIKE SY-TABIX,
    L_W_MSG_COUNTER LIKE SY-TABIX,
    L_I_MSG_COUNTER LIKE SY-TABIX.

  CALL FUNCTION 'QET4_OK_CODE_SAVE'
       IMPORTING
            E_MSG_COUNTER = L_E_MSG_COUNTER
            W_MSG_COUNTER = L_W_MSG_COUNTER
            I_MSG_COUNTER = L_I_MSG_COUNTER.

  IF L_E_MSG_COUNTER = 0.
    IF  L_W_MSG_COUNTER > 0
     OR L_I_MSG_COUNTER > 0.

      CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
           EXPORTING
                TEXTLINE1 = TEXT-108
                TEXTLINE2 = TEXT-109
                TITEL     = TEXT-107
           IMPORTING
                ANSWER    = L_ANSWER.

      CASE L_ANSWER.
        WHEN 'J'.                      "#EC NOTEXT
          CALL FUNCTION 'QET4_OK_CODE_SHOW_PROTOCOL'.
        WHEN 'N'.                      "#EC NOTEXT
          SET SCREEN 0.
          LEAVE SCREEN.
        WHEN OTHERS.
* Not LEAVE SCREEN
      ENDCASE.

    ELSE.
* No E-, W- or I-Message
      CALL FUNCTION 'Y_QMLIMS_QET5_SAVE_DATA'.  "<<<< INSERT CF
      SET SCREEN 0.
      LEAVE SCREEN.
    ENDIF.
  ELSE.
* E-Message exist, not LEAVE SCREEN
    CALL FUNCTION 'QET4_OK_CODE_SHOW_PROTOCOL'.
  ENDIF.

ENDFORM.                               " BACK_END
