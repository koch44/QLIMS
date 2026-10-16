*&---------------------------------------------------------------------*
*&      Form  START_OF_PROGRAM
*&---------------------------------------------------------------------*
*       This form is only processed once at start of program.
*----------------------------------------------------------------------*
FORM START_OF_PROGRAM.

  G_PS_BEGIN = 1.
  G_RESULTS_LEFT_COL = 0.
  CON_RESULTS-LEFT_COL = 0.

  PERFORM CREATE_CELLS.
  PERFORM CHECK_AUTHORITIES_AND_ACTIVITY.
  PERFORM CREATE_SCREEN.

ENDFORM.                               " START_OF_PROGRAM

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_TITLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DISPLAY_TITLES
       TABLES   G_TITLE STRUCTURE QETBCELLS
          USING P_FIELD_NAME LIKE QETBCELLS-REF_FIELD.

  DATA: L_OUTPUT_FORM(60) TYPE C.
  DATA: L_COL_NUMC(2) TYPE N.
  DATA: L_COL_NO TYPE I.
  DATA: TABLE_NAME(40) TYPE C.
  DATA: FIELD_NAME(40) TYPE C.
  FIELD-SYMBOLS: <TABLE>, <FIELD>.

* Titles
  L_COL_NO = G_PS_BEGIN.
  LOOP AT G_TITLE.

*   fixed columns
    IF G_TITLE-COL_NO <= G_PS_FIX_COLS.
      L_COL_NO = G_TITLE-COL_NO.

*   scrollable area
    ELSE.
      L_COL_NO = G_TITLE-COL_NO - G_PS_BEGIN + 1.
      IF L_COL_NO <= G_PS_FIX_COLS.
        L_COL_NO = G_MAX_COLUMN + 1.   " invalid value
      ENDIF.
    ENDIF.

    IF L_COL_NO >= 1 AND L_COL_NO <= G_MAX_COLUMN.

*     dynamic field name
      L_COL_NUMC = L_COL_NO.
      CONCATENATE P_FIELD_NAME '-COLUMN' L_COL_NUMC         "#EC NOTEXT
                   INTO G_TITLE-FIELD_NAME.

*     dynpro field
      SPLIT G_TITLE-FIELD_NAME AT '-' INTO TABLE_NAME FIELD_NAME.
      ASSIGN (TABLE_NAME) TO <TABLE>.
      ASSIGN COMPONENT FIELD_NAME OF STRUCTURE <TABLE> TO <FIELD>.

*     transport data
      CONCATENATE 'CLASS_' G_TITLE-FIELD_TYPE '_OUTPUT'     "#EC NOTEXT
                  INTO L_OUTPUT_FORM.
      PERFORM (L_OUTPUT_FORM) IN PROGRAM (G_SCREEN_MANAGER)
                 CHANGING G_TITLE <FIELD>.
      MODIFY G_TITLE.
    ENDIF.
  ENDLOOP.

ENDFORM.                               " DISPLAY_TITLES

*&---------------------------------------------------------------------*
*&      Form  COLUM_WIDTH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM COLUMN_WIDTH USING AUTOSIZE
                        MAXSIZE.

  DATA: L_LEN TYPE I.
  DATA: L_LEN_MAX TYPE I.
  DATA: G_LEN     LIKE USPARAM-PARVA.
  DATA: G_LEN_MAX TYPE I.
  DATA: TABLE_NAME(40) TYPE C.
  DATA: FIELD_NAME(40) TYPE C.
  DATA: L_FIELD_NAME_COMPLETE(80) TYPE C.
  FIELD-SYMBOLS: <TABLE>, <FIELD>.
  DATA: L_COL_NUMC(2) TYPE N.
  DATA: L_COL_NO TYPE I.
  DATA: WA_RESULTS LIKE LINE OF CON_RESULTS-COLS.

  IF NOT MAXSIZE IS INITIAL.
    GET PARAMETER ID 'YQMLIMS_MAXLENGTH' FIELD G_LEN.
    IF   SY-SUBRC = 0
    AND G_LEN CO '0123456789 '.
      IF  G_LEN > 0
      AND G_LEN < 100.
        G_LEN_MAX = G_LEN.
      ENDIF.
    ELSE.
      CLEAR G_LEN.
      SET PARAMETER ID 'YQMLIMS_MAXLENGTH' FIELD G_LEN.
    ENDIF.
  ENDIF.

* loop over columns
  L_COL_NO = 1.
  WHILE L_COL_NO <= G_MAX_COLUMN.

    L_COL_NUMC = L_COL_NO.
    CONCATENATE 'COLUMN' L_COL_NUMC INTO FIELD_NAME.        "#EC NOTEXT
    L_LEN_MAX = 0.                     " minimum column width

*   Title row results
    ASSIGN COMPONENT FIELD_NAME OF STRUCTURE TITLE_R TO <FIELD>.
    L_LEN = STRLEN( <FIELD> ).
    IF L_LEN > L_LEN_MAX.
      L_LEN_MAX = L_LEN.
    ENDIF.

*   Results tab
    TABLE_NAME = 'CONSHOW'.                                 "#EC NOTEXT
    ASSIGN (TABLE_NAME) TO <TABLE>.
    ASSIGN COMPONENT FIELD_NAME OF STRUCTURE <TABLE> TO <FIELD>.

    LOOP AT RESULTSTAB.
      MOVE RESULTSTAB TO CONSHOW.

*     ignore cells without data
      CHECK <FIELD> NE G_ICON_NO_DATA.

*     Icons
      IF <FIELD> CA '@'.
        SHIFT <FIELD> LEFT BY 1 PLACES.
        SHIFT <FIELD> UP TO '@'.
        SHIFT <FIELD> RIGHT BY 2 PLACES.
      ENDIF.

      L_LEN = STRLEN( <FIELD> ).
      IF L_LEN > L_LEN_MAX.
        L_LEN_MAX = L_LEN.
      ENDIF.
    ENDLOOP.

*   maximum column width
    IF L_LEN_MAX > G_LEN_MAX.
      IF G_LEN_MAX > 0.
        L_LEN_MAX = G_LEN_MAX.
      ENDIF.
    ENDIF.

*   results control
    CONCATENATE 'CONSHOW-' FIELD_NAME                       "#EC NOTEXT
                 INTO L_FIELD_NAME_COMPLETE.
    LOOP AT CON_RESULTS-COLS INTO WA_RESULTS
        WHERE SCREEN-NAME = L_FIELD_NAME_COMPLETE.
      IF L_LEN_MAX = 0.
        WA_RESULTS-INVISIBLE = C_SET.
      ELSE.
        CLEAR WA_RESULTS-INVISIBLE.
      ENDIF.
      IF   NOT AUTOSIZE     IS INITIAL
      OR   NOT MAXSIZE      IS INITIAL
      AND  WA_RESULTS-INDEX GT CON_RESULTS-FIXED_COLS.
        WA_RESULTS-VISLENGTH = L_LEN_MAX + 1.
      ENDIF.
      MODIFY CON_RESULTS-COLS FROM WA_RESULTS.
    ENDLOOP.

    L_COL_NO = L_COL_NO + 1.
  ENDWHILE.

ENDFORM.                               " COLUMN_WIDTH

*---------------------------------------------------------------------*
*       FORM CREATE_CELLS                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM CREATE_CELLS.

  REFRESH G_TITLE_R.
  REFRESH G_RESULTS.

  PERFORM CREATE_CELLS IN PROGRAM (G_SCREEN_MANAGER)
      TABLES G_TITLE_R
             G_TITLE_R
             G_RESULTS
             G_RESULTS
    CHANGING G_PS_FIX_COLS.

ENDFORM.                               " CREATE_TITLES

*&---------------------------------------------------------------------*
*&      Form  CREATE_SCREEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CREATE_SCREEN.

  DATA: L_OLD_ROW TYPE I.
  DATA: L_OUTPUT_FORM(60) TYPE C.
  DATA: L_COL_NUMC(2) TYPE N.
  DATA: L_LAST_COL TYPE I.
  DATA: L_COL_NO TYPE I.
  DATA: TABLE_NAME(40) TYPE C.
  DATA: FIELD_NAME(40) TYPE C.
  FIELD-SYMBOLS: <TABLE>, <FIELD>.
  DATA: L_LINES TYPE I.

  CLEAR TITLE_R.
  REFRESH RESULTSTAB.
  CLEAR RESULTSTAB.

* count columns
  G_MAX_COL_NO = 1.
  LOOP AT G_RESULTS.
    IF G_RESULTS-COL_NO > G_MAX_COL_NO.
      G_MAX_COL_NO = G_RESULTS-COL_NO.
    ENDIF.
  ENDLOOP.

* Scroll left
  L_LAST_COL = G_MAX_COLUMN - G_PS_BEGIN + 1.

* Titles
  PERFORM DISPLAY_TITLES TABLES G_TITLE_R USING 'TITLE_R'.

******************************************************
* Results
******************************************************
  L_OLD_ROW = 1.
  L_COL_NO = G_PS_BEGIN.

  PERFORM INITIALIZE_RESULTS_ROW CHANGING RESULTSTAB.
  SORT G_RESULTS BY ROW_NO COL_NO.
  LOOP AT G_RESULTS.

*   New line
    IF G_RESULTS-ROW_NO NE L_OLD_ROW.
      APPEND RESULTSTAB.
      PERFORM INITIALIZE_RESULTS_ROW CHANGING RESULTSTAB.
    ENDIF.

*   fixed columns
    IF G_RESULTS-COL_NO <= G_PS_FIX_COLS.
      L_COL_NO = G_RESULTS-COL_NO.

*   scrollable area
    ELSE.
      L_COL_NO = G_RESULTS-COL_NO - G_PS_BEGIN + 1.
      IF L_COL_NO <= G_PS_FIX_COLS.
        L_COL_NO = G_MAX_COLUMN + 1.   " invalid value
      ENDIF.

    ENDIF.
    IF L_COL_NO >= 1 AND L_COL_NO <= G_MAX_COLUMN.

      L_COL_NUMC = L_COL_NO.
      CONCATENATE 'RESULTSTAB-COLUMN' L_COL_NUMC            "#EC NOTEXT
               INTO G_RESULTS-FIELD_NAME.

*     dynpro field
      SPLIT G_RESULTS-FIELD_NAME AT '-' INTO TABLE_NAME FIELD_NAME.
      ASSIGN (TABLE_NAME) TO <TABLE>.
      ASSIGN COMPONENT FIELD_NAME OF STRUCTURE <TABLE> TO <FIELD>.

      CONCATENATE 'CLASS_' G_RESULTS-FIELD_TYPE '_OUTPUT'   "#EC NOTEXT
               INTO L_OUTPUT_FORM.
      PERFORM (L_OUTPUT_FORM) IN PROGRAM (G_SCREEN_MANAGER)
                 CHANGING G_RESULTS <FIELD>.

      G_RESULTS-INVALID_FLG = C_SET.
      MODIFY G_RESULTS.
    ENDIF.

    L_OLD_ROW = G_RESULTS-ROW_NO.

  ENDLOOP.
  APPEND RESULTSTAB.
  DESCRIBE TABLE RESULTSTAB LINES CON_RESULTS-LINES.

ENDFORM.                               " CREATE_SCREEN

*&---------------------------------------------------------------------*
*&      Form  TRANSPORT_TO_TOOLBOX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TABIX_RESULTSTAB  text
*      -->P_CURSOR_FIELD  text
*----------------------------------------------------------------------*
FORM TRANSPORT_TO_TOOLBOX USING P_ROW_NO LIKE QETBCELLS-ROW_NO
                                P_COL_NO TYPE QETBCELLS-COL_NO.

  DATA: L_INPUT_FORM(60) TYPE C.
  DATA: TABLE_NAME(40) TYPE C.
  DATA: FIELD_NAME(40) TYPE C.
  FIELD-SYMBOLS: <TABLE>, <FIELD>.

* update dynpro table
  MODIFY RESULTSTAB INDEX P_ROW_NO.

* read modified cell
  READ TABLE G_RESULTS WITH KEY
      ROW_NO = P_ROW_NO
      COL_NO = P_COL_NO.

* transport for valid cells only
  CHECK SY-SUBRC IS INITIAL.

  CHECK NOT G_RESULTS-REF_FIELD IS INITIAL.

* dynpro field
  SPLIT G_RESULTS-FIELD_NAME AT '-' INTO TABLE_NAME FIELD_NAME.
  ASSIGN (TABLE_NAME) TO <TABLE>.
  ASSIGN COMPONENT FIELD_NAME OF STRUCTURE <TABLE> TO <FIELD>.

* Field contains code
  IF G_RESULTS-REF_FIELD CS 'CODE'.                         "#EC NOTEXT

*   call field specific input routine
    CONCATENATE 'CLASS_' G_RESULTS-FIELD_TYPE '_INPUT'      "#EC NOTEXT
            INTO L_INPUT_FORM.
    PERFORM (L_INPUT_FORM) IN PROGRAM (G_SCREEN_MANAGER)
               TABLES G_RESULTS
               USING G_RESULTS <FIELD> ''.

  ELSE.

* call field specific input routine
    CONCATENATE 'CLASS_' G_RESULTS-FIELD_TYPE '_INPUT'      "#EC NOTEXT
            INTO L_INPUT_FORM.
    PERFORM (L_INPUT_FORM) IN PROGRAM (G_SCREEN_MANAGER)
               TABLES G_RESULTS
               USING G_RESULTS <FIELD>.
  ENDIF.
ENDFORM.                               " TRANSPORT_TO_TOOLBOX


*&---------------------------------------------------------------------*
*&      Form  OK_CODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM OK_CODE TABLES P_SPECS   STRUCTURE QETBCELLS
                    P_RESULTS STRUCTURE QETBCELLS
              USING P_OK_CODE LIKE OK-CODE
                    P_ROW_NO  LIKE QETBCELLS-ROW_NO
                    P_COL_NO  LIKE QETBCELLS-COL_NO
                    P_AREA    LIKE SY-TNAME
                    P_SCREEN_MANAGER LIKE SY-CPROG.

  CALL FUNCTION 'Y_QMLIMS_QET1_OK_CODE_PROC'
    EXPORTING
      I_ROW_NO         = P_ROW_NO
      I_COL_NO         = P_COL_NO
      I_AREA           = P_AREA
      I_OK_CODE        = P_OK_CODE
      I_SCREEN_MANAGER = P_SCREEN_MANAGER
    TABLES
      T_SPECS          = P_SPECS
      T_RESULTS        = P_RESULTS.

ENDFORM.                               " OK_CODE

*&---------------------------------------------------------------------*
*&      Form  VALIDATE_RESULTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATE_RESULTS.

  DATA: L_OUTPUT_FORM(60) TYPE C.
  DATA: L_INDX_RESULTSTAB LIKE SY-TABIX.
  DATA: L_INDX_RESULTS    LIKE SY-TABIX.
  DATA: L_COL_NO TYPE I.
  DATA: L_COL_NUMC(2) TYPE N.
  DATA: TABLE_NAME(40) TYPE C.
  DATA: FIELD_NAME(40) TYPE C.
  FIELD-SYMBOLS: <TABLE>, <FIELD>.

  LOOP AT G_RESULTS WHERE INVALID_FLG = C_SET.
    L_INDX_RESULTS = SY-TABIX.

    READ TABLE RESULTSTAB INDEX G_RESULTS-ROW_NO.
    L_INDX_RESULTSTAB = SY-TABIX.

*   fixed columns
    IF G_RESULTS-COL_NO <= G_PS_FIX_COLS.
      L_COL_NO = G_RESULTS-COL_NO.

*   scrollable area
    ELSE.
      L_COL_NO = G_RESULTS-COL_NO - G_PS_BEGIN + 1.
      IF L_COL_NO <= G_PS_FIX_COLS.
        L_COL_NO = G_MAX_COLUMN + 1.   " invalid value
      ENDIF.
    ENDIF.

    IF L_COL_NO >= 1 AND L_COL_NO <= G_MAX_COLUMN.

      L_COL_NUMC = L_COL_NO.
      CONCATENATE 'RESULTSTAB-COLUMN' L_COL_NUMC            "#EC NOTEXT
                                INTO G_RESULTS-FIELD_NAME.

*     dynpro field
      SPLIT G_RESULTS-FIELD_NAME AT '-' INTO TABLE_NAME FIELD_NAME.
      ASSIGN (TABLE_NAME) TO <TABLE>.
      ASSIGN COMPONENT FIELD_NAME OF STRUCTURE <TABLE> TO <FIELD>.

      CONCATENATE 'CLASS_' G_RESULTS-FIELD_TYPE '_OUTPUT'   "#EC NOTEXT
               INTO L_OUTPUT_FORM.
      PERFORM (L_OUTPUT_FORM) IN PROGRAM (G_SCREEN_MANAGER)
                 CHANGING G_RESULTS <FIELD>.

      MODIFY RESULTSTAB INDEX L_INDX_RESULTSTAB.

      CLEAR G_RESULTS-INVALID_FLG.
      MODIFY G_RESULTS INDEX L_INDX_RESULTS.
    ENDIF.

  ENDLOOP.

ENDFORM.                               " VALIDATE_RESULTS

*&---------------------------------------------------------------------*
*&      Form  ON_VALUE_REQUEST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CURSOR_LINE  text
*      -->P_5      text
*----------------------------------------------------------------------*
FORM ON_VALUE_REQUEST USING I_ROW_NO           LIKE SY-STEPL
                            I_COL_NO           TYPE I
                            I_CURSOR_FIELD     LIKE CURSOR_FIELD.

  DATA: L_CODE TYPE QCODE.
  DATA: L_CODE_GRP TYPE QCODEGRP.
  DATA: L_CODE_TEXT TYPE QCODETEXT.
  DATA: L_INPUT_FORM(60) TYPE C.
  FIELD-SYMBOLS: <TABLE>, <FIELD>.
  DATA: TABLE_NAME(40) TYPE C.
  DATA: FIELD_NAME(40) TYPE C.
  DATA: L_REQUIREMENTS    LIKE BAPI2045D1.
  DATA: L_IP_REQUIREMENTS LIKE BAPI2045D5.

* Select cell
  READ TABLE G_RESULTS WITH KEY
      ROW_NO = I_ROW_NO
      COL_NO = I_COL_NO.
  CHECK SY-SUBRC IS INITIAL.
  G_RESULTS-INVALID_FLG = C_SET.
  MODIFY  G_RESULTS INDEX SY-TABIX.

* Read Char Requirements
  CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
    EXPORTING
      I_CELLS                   = G_RESULTS
    IMPORTING
      E_CHAR_REQUIREMENTS       = L_REQUIREMENTS
      E_INSP_POINT_REQUIREMENTS = L_IP_REQUIREMENTS.

  IF G_RESULTS-REF_FIELD EQ 'G_INSP_POINTS-CODE'.           "#EC NOTEXT

*   Call Popup to select code
    CALL FUNCTION 'QET4_SELECT_CODE'
      EXPORTING
        I_CAT_TYPE  = L_IP_REQUIREMENTS-CAT_TYPE
        I_PSEL_SET  = L_IP_REQUIREMENTS-PSEL_SET
        I_SEL_SET   = L_IP_REQUIREMENTS-SEL_SET
      IMPORTING
        E_CODE      = L_CODE
        E_CODE_GRP  = L_CODE_GRP
        E_CODE_TEXT = L_CODE_TEXT
      EXCEPTIONS
        ABORTED     = 1.
  ELSE.
*   Call Popup to select code
    CALL FUNCTION 'QET4_SELECT_CODE'
      EXPORTING
        I_CAT_TYPE  = L_REQUIREMENTS-CAT_TYPE1
        I_PSEL_SET  = L_REQUIREMENTS-PSEL_SET1
        I_SEL_SET   = L_REQUIREMENTS-SEL_SET1
      IMPORTING
        E_CODE      = L_CODE
        E_CODE_GRP  = L_CODE_GRP
        E_CODE_TEXT = L_CODE_TEXT
      EXCEPTIONS
        ABORTED     = 1.
  ENDIF.

  CHECK SY-SUBRC IS INITIAL.

* Write code into screen field
  SPLIT I_CURSOR_FIELD AT '-' INTO TABLE_NAME FIELD_NAME.
  ASSIGN (TABLE_NAME) TO <TABLE>.
  ASSIGN COMPONENT FIELD_NAME OF STRUCTURE <TABLE> TO <FIELD>.
  CONCATENATE L_CODE L_CODE_TEXT INTO <FIELD> SEPARATED BY SPACE.

  IF G_RESULTS-REF_FIELD CS 'CODE'.                         "#EC NOTEXT

*   call field specific input routine
    CONCATENATE 'CLASS_' G_RESULTS-FIELD_TYPE '_INPUT'      "#EC NOTEXT
            INTO L_INPUT_FORM.
    PERFORM (L_INPUT_FORM) IN PROGRAM (G_SCREEN_MANAGER)
               TABLES G_RESULTS
               USING G_RESULTS <FIELD> L_CODE_GRP.

  ELSE.

* call field specific input routine
    CONCATENATE 'CLASS_' G_RESULTS-FIELD_TYPE '_INPUT'      "#EC NOTEXT
            INTO L_INPUT_FORM.
    PERFORM (L_INPUT_FORM) IN PROGRAM (G_SCREEN_MANAGER)
               TABLES G_RESULTS
               USING G_RESULTS <FIELD>.
  ENDIF.
ENDFORM.                               " ON_VALUE_REQUEST

*&---------------------------------------------------------------------*
*&      Form  CHECK_POSTING_READY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_POSTING_READY.

  CALL FUNCTION 'QET4_CHECK_POSTING_READY'
    EXCEPTIONS
      POSTING_READY      = 1
      POSTING_RUNNING    = 2
      NO_POSTING_RUNNING = 3.

* Posting just finished
  IF SY-SUBRC = 1.
    CALL FUNCTION 'QET4_UPD_MULTIPLE_SAMPLES'
      EXPORTING
        I_POSTED_SAMPLES = 'X'
      TABLES
        T_CELLS          = G_RESULTS.
  ENDIF.

ENDFORM.                               " CHECK_POSTING_READY

*&---------------------------------------------------------------------*
*&      Form  GET_COL_NO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CURSOR_FIELD  text
*      <--P_G_COL_NO  text
*----------------------------------------------------------------------*
FORM GET_COL_NO USING    P_CURSOR_FIELD LIKE CURSOR_FIELD
                CHANGING P_COL_NO LIKE QETBCELLS-COL_NO.

  DATA: L_NUMC(2) TYPE N.

* In L_NUMC sind die Ziffern, die im Feldnamen stehen
* Die Spalten müssen deshalb aufsteigend durchnummeriert sein.
  L_NUMC = CURSOR_FIELD.
  P_COL_NO = L_NUMC.

* Anpassung wegen scrollen
  IF P_COL_NO > G_PS_FIX_COLS.
    P_COL_NO = P_COL_NO + G_PS_BEGIN - 1.
  ENDIF.

ENDFORM.                               " GET_COL_NO
*&---------------------------------------------------------------------*
*&      Form  EXIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM EXIT.

  DATA:
    L_ANSWER TYPE C,
    L_SUBRC  LIKE SY-SUBRC.

* Save Ok-Code
  MOVE OK-CODE TO OLD_OK_CODE.
  CLEAR OK-CODE.

  CASE OLD_OK_CODE.
    WHEN 'BACK'                                             "#EC NOTEXT
      OR 'END'                                              "#EC NOTEXT
      OR 'QETBNEXTOP'.                                      "#EC NOTEXT
      CALL FUNCTION 'QET4_CHECK_ALL_IS_SAVED'
        TABLES
          T_CELLS         = G_RESULTS
        EXCEPTIONS
          NOT_SAVED       = 1
          POSTING_RUNNING = 2.

      L_SUBRC = SY-SUBRC.

      IF       L_SUBRC IS INITIAL
       AND NOT SY-DATAR IS INITIAL.
        L_SUBRC = '1'.
      ENDIF.

      CASE L_SUBRC.
        WHEN '0'.
          SET SCREEN 0.
          LEAVE SCREEN.
        WHEN '1'.
          CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
            EXPORTING
              TEXTLINE1 = TEXT-101
              TITEL     = TEXT-100
            IMPORTING
              ANSWER    = L_ANSWER.

          CASE L_ANSWER.
            WHEN 'J'.                                       "#EC NOTEXT
              MOVE OLD_OK_CODE TO OK-CODE.
            WHEN 'N'.                                       "#EC NOTEXT
              SET SCREEN 0.
              LEAVE SCREEN.
            WHEN OTHERS.
* Not LEAVE SCREEN
          ENDCASE.

        WHEN '2'.
          MESSAGE I021.
* Sicherungsvorgang läuft. Funktion später wiederholen
      ENDCASE.

    WHEN 'EXIT'.                                            "#EC NOTEXT
      CALL FUNCTION 'POPUP_TO_CONFIRM_LOSS_OF_DATA'
        EXPORTING
          TEXTLINE1 = TEXT-104
          TEXTLINE2 = TEXT-105
          TITEL     = TEXT-103
        IMPORTING
          ANSWER    = L_ANSWER.

      IF L_ANSWER EQ 'J'.
        SET SCREEN 0.
        LEAVE SCREEN.
      ENDIF.

    WHEN OTHERS.
* No action
  ENDCASE.


ENDFORM.                               " EXIT

*&---------------------------------------------------------------------*
*&      Form  CORRECT_COL_NO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_COL_NO  text
*----------------------------------------------------------------------*
FORM CORRECT_COL_NO CHANGING P_COL_NO TYPE I.

  IF P_COL_NO > G_PS_FIX_COLS.
    P_COL_NO = P_COL_NO + G_PS_BEGIN - 1.
  ENDIF.

ENDFORM.                               " CORRECT_COL_NO

*&---------------------------------------------------------------------*
*&      Form  CHECK_CHARS_UNLOCKED
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_CHARS_UNLOCKED.

  CALL FUNCTION 'QET4_CHECK_CHARS_UNLOCKED'
    TABLES
      RESULTS                  = G_RESULTS
    EXCEPTIONS
      CHARS_JUST_UNLOCKED      = 1
      CHARS_EXTERNAL_LOCKED    = 2
      NO_CHARS_EXTERNAL_LOCKED = 3
      OTHERS                   = 4.

* Posting just finished
  IF SY-SUBRC = 1.
    CALL FUNCTION 'QET4_UPD_MULTIPLE_SAMPLES'
      EXPORTING
        I_LOCKED_SAMPLES = 'X'
      TABLES
        T_CELLS          = G_RESULTS.
  ENDIF.

ENDFORM.                               " CHECK_CHARS_UNLOCKED
*&---------------------------------------------------------------------*
*&      Form  INITIALIZE_RESULTS_ROW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_RESULTSTAB  text
*----------------------------------------------------------------------*
FORM INITIALIZE_RESULTS_ROW CHANGING RESULTSTAB LIKE CONSHOW.
  DATA: L_INFO  TYPE ICONQUICK.

  CLEAR RESULTSTAB.
  L_INFO = 'fehlt bei diesem Prüflos'(106).
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      NAME                  = 'ICON_SPACE'
*     TEXT                  = ' '
      INFO                  = L_INFO
*     ADD_STDINF            = 'X'
    IMPORTING
      RESULT                = G_ICON_NO_DATA
    EXCEPTIONS
      ICON_NOT_FOUND        = 1
      OUTPUTFIELD_TOO_SHORT = 2
      OTHERS                = 3.

  RESULTSTAB-COLUMN01 = G_ICON_NO_DATA.
  RESULTSTAB-COLUMN02 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN03 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN04 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN05 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN06 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN07 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN08 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN09 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN10 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN11 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN12 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN13 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN14 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN15 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN16 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN17 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN18 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN19 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN20 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN21 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN22 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN23 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN24 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN25 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN26 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN27 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN28 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN29 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN30 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN31 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN32 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN33 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN34 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN35 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN36 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN37 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN38 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN39 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN40 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN41 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN42 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN43 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN44 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN45 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN46 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN47 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN48 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN49 = RESULTSTAB-COLUMN01.
  RESULTSTAB-COLUMN50 = RESULTSTAB-COLUMN01.

ENDFORM.                               " INITIALIZE_RESULTS_ROW
*&---------------------------------------------------------------------*
*&      Form  CHECK_AUTHORITIES_AND_ACTIVITY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_AUTHORITIES_AND_ACTIVITY.

  DATA: L_INSPLOT_DATA          LIKE BAPI2045D_IL0.
  DATA: L_OPERATION             LIKE BAPI2045L2.
  DATA: L_REQUIREMENTS          LIKE BAPI2045D1.
  DATA: L_QAPO                  LIKE QAPO.
  DATA: L_QAQEE                 LIKE QAQEE.
  DATA: L_INSPLOT               LIKE BAPI2045L2-INSPLOT.
  DATA: L_INSPOPER              LIKE BAPI2045L2-INSPOPER.
  DATA: L_SYNCHRONIZE_DATA_CALL TYPE C.
  DATA: L_QALS_NOT_ALLOWED TYPE C.

  LOOP AT G_RESULTS WHERE INPUT_FIELD = C_SET.

    IF  G_RESULTS-INSPLOT  NE L_INSPLOT
     OR G_RESULTS-INSPOPER NE L_INSPOPER.

      CLEAR L_QAQEE.
      CLEAR L_QAPO.

* Vorgang lesen
      CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
        EXPORTING
          I_CELLS             = G_RESULTS
        IMPORTING
          E_INSP_LOT          = L_INSPLOT_DATA
          E_OPERATION         = L_OPERATION
          E_CHAR_REQUIREMENTS = L_REQUIREMENTS.

      L_SYNCHRONIZE_DATA_CALL = 'X'.

      L_QAPO-PRPLATZ     = L_OPERATION-WORKCENTER.
      L_QAPO-PRPLATZWRK  = L_OPERATION-PLNT_WORKC.
      L_QAQEE-AKTIVITAET = 'E'.        "Erfassen

      IF G_RESULTS-INSPLOT NE L_INSPLOT.
        CLEAR L_QALS_NOT_ALLOWED.

* Status zum Objekt initialisieren
        CALL FUNCTION 'STATUS_BUFFER_REFRESH'.

* check objectnumber
        CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
          EXPORTING
            I_CHECK_ONLY         = 'X'
            I_DIALOG             = ' '
            I_OBJNR              = L_INSPLOT_DATA-OBJECT_NO
            I_VORGANG            = 'QM25'
          EXCEPTIONS
            NOT_ALLOWED          = 01
            ACTIVITY_NOT_ALLOWED = 02.

        IF NOT SY-SUBRC IS INITIAL.
          L_QALS_NOT_ALLOWED = 'X'.
* no entry allowed
          CLEAR G_RESULTS-INPUT_ALLOWED.
        ENDIF.
      ENDIF.

* Berechtigungsprüfung durchführen
      CALL FUNCTION 'QEEM_AUTHORITY_CHECK_CHAR'
        EXPORTING
          I_QAPO  = L_QAPO
          I_QAQEE = L_QAQEE
        IMPORTING
          E_QAQEE = L_QAQEE.

      L_INSPLOT   = G_RESULTS-INSPLOT.
      L_INSPOPER  = G_RESULTS-INSPOPER.

    ENDIF.

    IF L_QALS_NOT_ALLOWED IS INITIAL.
* entry allowed
      IF NOT L_SYNCHRONIZE_DATA_CALL IS INITIAL.
* Lesen des Vorgabenstatus, nur wenn noch nicht gelesen
        CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
          EXPORTING
            I_CELLS             = G_RESULTS
          IMPORTING
            E_CHAR_REQUIREMENTS = L_REQUIREMENTS.
      ENDIF.

      CLEAR L_SYNCHRONIZE_DATA_CALL.

      CASE L_REQUIREMENTS-STATUS.
        WHEN '0'.
          IF  L_QAQEE-QAUTH02 IS INITIAL.
* Keine Berechtigung, keine Eingabemöglichkeit
            CLEAR G_RESULTS-INPUT_ALLOWED.
          ENDIF.
        WHEN '1'.
          IF L_QAQEE-QAUTH12 IS INITIAL.
            CLEAR G_RESULTS-INPUT_ALLOWED.
          ENDIF.
        WHEN '4'.
          IF L_QAQEE-QAUTH42 IS INITIAL.
            CLEAR G_RESULTS-INPUT_ALLOWED.
          ENDIF.
        WHEN '6'.
          IF L_QAQEE-QAUTH62 IS INITIAL.
            CLEAR G_RESULTS-INPUT_ALLOWED.
          ENDIF.
      ENDCASE.
    ENDIF.
    MODIFY G_RESULTS.

  ENDLOOP.

ENDFORM.                               " CHECK_AUTHORITIES_AND_ACTIVITY
