*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       Check, if screen will be left
*----------------------------------------------------------------------*
MODULE EXIT INPUT.

  PERFORM EXIT.

ENDMODULE.                             " EXIT  INPUT

*&---------------------------------------------------------------------*
*&      Module  OK-CODE  INPUT
*&---------------------------------------------------------------------*
*       In dependence of the OK-CODE further functions will be processed
*----------------------------------------------------------------------*
MODULE OK-CODE INPUT.

* Save Ok-Code
  MOVE OK-CODE TO OLD_OK_CODE.
  CLEAR OK-CODE.

  PERFORM OK_CODE TABLES G_RESULTS
                         G_RESULTS
                   USING OLD_OK_CODE
                         G_ROW_NO
                         G_COL_NO
                         CURSOR_AREA
                         G_SCREEN_MANAGER.

  IF OLD_OK_CODE EQ 'SAVE'             "#EC NOTEXT
     OR OLD_OK_CODE EQ 'QETBJPRRC'      "#EC NOTEXT
     OR OLD_OK_CODE EQ 'QETBCLOSE'.    "#EC NOTEXT
    PERFORM CREATE_CELLS.
    PERFORM CREATE_SCREEN.
  ENDIF.

ENDMODULE.                             " OK-CODE  INPUT

*&---------------------------------------------------------------------*
*&      Module  GET_LINE_RESULTSTAB  INPUT
*&---------------------------------------------------------------------*
*       Get actual line number of RESULTSTAB
*----------------------------------------------------------------------*
MODULE GET_LINE_RESULTSTAB INPUT.

  TABIX_RESULTSTAB = G_PAGEBEGIN_CHAR + SY-STEPL - 1.

ENDMODULE.                             " GET_LINE_RESULTSTAB  INPUT

*&---------------------------------------------------------------------*
*&      Module  CURSOR_READ  INPUT
*&---------------------------------------------------------------------*
*       Module for reading information about the cursor
*----------------------------------------------------------------------*
MODULE CURSOR_READ INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.

* row number
  CLEAR G_ROW_NO.
  IF CURSOR_AREA = 'CON_RESULTS'.      "#EC NOTEXT
    G_ROW_NO = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  ENDIF.

* extract column number from field name
  PERFORM GET_COL_NO USING CURSOR_FIELD CHANGING G_COL_NO.

* Store scroll positions for first time
  IF  G_RESULTS_LEFT_COL EQ 0.
* offset 2! = 1. column to mark, 2. column = current
    G_RESULTS_LEFT_COL = CON_RESULTS-FIXED_COLS + 2.
  ENDIF.

ENDMODULE.                             " CURSOR_READ  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB01  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB01 INPUT.
  G_COL_NO = 1.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB01  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB02  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB02 INPUT.
  G_COL_NO = 2.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB02  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB03  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB03 INPUT.
  G_COL_NO = 3.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB03  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB04  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB04 INPUT.
  G_COL_NO = 4.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB04  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB05  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB05 INPUT.
  G_COL_NO = 5.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB05  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB06  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB06 INPUT.
  G_COL_NO = 6.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB06  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB07  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB07 INPUT.
  G_COL_NO = 7.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB07  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB08  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB08 INPUT.
  G_COL_NO = 8.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB08  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB09  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB09 INPUT.
  G_COL_NO = 9.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB09  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB10  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB10 INPUT.
  G_COL_NO = 10.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB10  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB11  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB11 INPUT.
  G_COL_NO = 11.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB11  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB12  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB12 INPUT.
  G_COL_NO = 12.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB12  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB13  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB13 INPUT.
  G_COL_NO = 13.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB13  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB14  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB14 INPUT.
  G_COL_NO = 14.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB14  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB15  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB15 INPUT.
  G_COL_NO = 15.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB15  INPUT


*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB16  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB16 INPUT.
  G_COL_NO = 16.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB16  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB17  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB17 INPUT.
  G_COL_NO = 17.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB17  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB18  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB18 INPUT.
  G_COL_NO = 18.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB18  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB19  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB19 INPUT.
  G_COL_NO = 19.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB19  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB20  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB20 INPUT.
  G_COL_NO = 20.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB20  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB21  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB21 INPUT.
  G_COL_NO = 21.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB21  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB22  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB22 INPUT.
  G_COL_NO = 22.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB22  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB23  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB23 INPUT.
  G_COL_NO = 23.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB23  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB24  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB24 INPUT.
  G_COL_NO = 24.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB24  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB25  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB25 INPUT.
  G_COL_NO = 25.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB25  INPUT


*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB26  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB26 INPUT.
  G_COL_NO = 26.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB26  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB27  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB27 INPUT.
  G_COL_NO = 27.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB27  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB28  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB28 INPUT.
  G_COL_NO = 28.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB28  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB29  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB29 INPUT.
  G_COL_NO = 29.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB29  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB30  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB30 INPUT.
  G_COL_NO = 30.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB30  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB31 INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB31 INPUT.
  G_COL_NO = 31.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB31  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB32  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB32 INPUT.
  G_COL_NO = 32.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB32  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB33  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB33 INPUT.
  G_COL_NO = 33.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB33  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB34  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB34 INPUT.
  G_COL_NO = 34.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB34  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB35  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB35 INPUT.
  G_COL_NO = 35.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB35  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB36  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB36 INPUT.
  G_COL_NO = 36.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB36  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB37  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB37 INPUT.
  G_COL_NO = 37.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB37  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB38  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB38 INPUT.
  G_COL_NO = 38.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB38  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB39  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB39 INPUT.
  G_COL_NO = 39.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB39  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB40  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB40 INPUT.
  G_COL_NO = 40.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB40  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB41  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB41 INPUT.
  G_COL_NO = 41.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB41  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB42  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB42 INPUT.
  G_COL_NO = 42.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB42  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB43  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB43 INPUT.
  G_COL_NO = 43.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB43  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB44  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB44 INPUT.
  G_COL_NO = 44.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB44  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB45  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB45 INPUT.
  G_COL_NO = 45.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB45  INPUT


*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB46  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB46 INPUT.
  G_COL_NO = 46.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB46  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB47  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB47 INPUT.
  G_COL_NO = 47.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB47  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB48  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB48 INPUT.
  G_COL_NO = 48.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB48  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB49  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB49 INPUT.
  G_COL_NO = 49.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB49  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB50  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB50 INPUT.
  G_COL_NO = 50.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM TRANSPORT_TO_TOOLBOX USING TABIX_RESULTSTAB G_COL_NO.
ENDMODULE.                             " CHANGES_RESULTSTAB50  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST01  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST01 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 1.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST01  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST02  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST02 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 2.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST02  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST03  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST03 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 3.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST03  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST04  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST04 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 4.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST04  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST05  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST05 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 5.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST05  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST06  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST06 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 6.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST06  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST07  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST07 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 7.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST07  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST08  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST08 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 8.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST08  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST09  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST09 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 9.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST09  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST10  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST10 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 10.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST10  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST11  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST11 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 11.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST11  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST12  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST12 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 12.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST12  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST13  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST13 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 13.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST13  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST14  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST14 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 14.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST14  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST15  INPUT
*&---------------------------------------------------------------------*
*       F4 auf Spalte 15
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST15 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 15.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST15  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST16  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST16 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 16.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST16  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST17  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST17 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 17.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST17  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST18  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST18 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 18.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST18  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST19  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST19 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 19.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST19  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST20  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST20 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 20.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST20  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST21  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST21 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 21.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST21  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST22  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST22 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 22.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST22  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST23  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST23 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 23.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST23  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST24  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST24 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 24.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST24  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST25  INPUT
*&---------------------------------------------------------------------*
*       F4 auf Spalte 25
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST25 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 25.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST25  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST26  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST26 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 26.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST26  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST27  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST27 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 27.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST27  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST28  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST28 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 28.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST28  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST29  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST29 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 29.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST29  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST30  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST30 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 30.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST30  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST31  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST31 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 31.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST31  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST32  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST32 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 32.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST32  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST33  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST33 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 33.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST33  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST34  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST34 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 34.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST34  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST35  INPUT
*&---------------------------------------------------------------------*
*       F4 auf Spalte 35
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST35 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 35.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST35  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST36  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST36 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 36.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST36  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST37  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST37 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 37.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST37  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST38  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST38 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 38.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST38  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST39  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST39 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 39.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST39  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST40  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST40 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 40.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST40  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST41  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST41 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 41.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST41  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST42  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST42 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 42.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST42  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST43  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST43 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 43.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST43  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST44  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST44 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 44.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST44  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST45  INPUT
*&---------------------------------------------------------------------*
*       F4 auf Spalte 45
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST45 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 45.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST45  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST46  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST46 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 46.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST46  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST47  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST47 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 47.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST47  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST48  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST48 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 48.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST48  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST49  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST49 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 49.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST49  INPUT

*&---------------------------------------------------------------------*
*&      Module  ON_VALUE_REQUEST50  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ON_VALUE_REQUEST50 INPUT.

  GET CURSOR FIELD CURSOR_FIELD
             LINE  CURSOR_LINE
             AREA  CURSOR_AREA.
  CURSOR_LINE = G_PAGEBEGIN_CHAR + CURSOR_LINE - 1.
  G_COL_NO = 50.
  PERFORM CORRECT_COL_NO CHANGING G_COL_NO.
  PERFORM ON_VALUE_REQUEST USING CURSOR_LINE G_COL_NO CURSOR_FIELD.

ENDMODULE.                             " ON_VALUE_REQUEST50  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGES_RESULTSTAB_ALL  INPUT
*&---------------------------------------------------------------------*
*       Changed fields in head of internal table RESULTSTAB
*----------------------------------------------------------------------*
MODULE CHANGES_RESULTSTAB_ALL INPUT.

* READ TABLE RESULTSTAB INDEX TABIX_RESULTSTAB.
  MOVE CONSHOW TO RESULTSTAB.

ENDMODULE.                             " CHANGES_RESULTSTAB_ALL  INPUT
*&---------------------------------------------------------------------*
*&      Module  user_command_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  CASE ok-code.
    WHEN 'ABBR'.
      LEAVE TO SCREEN 0.
    WHEN 'ENT1'.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.                 " user_command_0200  INPUT
*&---------------------------------------------------------------------*
*&      Module  user_command_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.

  CASE ok-code.
    WHEN 'ABBR'.
      RAISE action_cancelled.
*      LEAVE TO SCREEN 0.
    WHEN 'ENT1'.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.                 " user_command_0300  INPUT
