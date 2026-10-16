*&---------------------------------------------------------------------*
*&      Module  STATUS  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS OUTPUT.

  PERFORM SET_TITLE  IN PROGRAM (G_SCREEN_MANAGER)
                  USING '0100_01'                           "#EC NOTEXT
                        G_SCREEN_MANAGER.

  PERFORM SET_STATUS IN PROGRAM (G_SCREEN_MANAGER)
                  USING '0100_01'                           "#EC NOTEXT
                        G_SCREEN_MANAGER.

ENDMODULE.                             " STATUS  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  START_OF_PROGRAM  OUTPUT
*&---------------------------------------------------------------------*
*       Prozessing at the beginning of program.
*----------------------------------------------------------------------*
MODULE START_OF_PROGRAM OUTPUT.

  CHECK G_FIRST_RUN_FINISH IS INITIAL.
* Perform 'START_OF_PROGRAM' was not run
  MOVE 'X' TO G_FIRST_RUN_FINISH.

  PERFORM START_OF_PROGRAM.

ENDMODULE.                             " START_OF_PROGRAM  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  ATTRIBUTES  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ATTRIBUTES_RESULTS OUTPUT.

  G_ROW_NO = CON_RESULTS-CURRENT_LINE.
  G_COL_NO = 0.

  CON_RESULTS-FIXED_COLS = G_PS_FIX_COLS.

  LOOP AT SCREEN.

    SCREEN-INVISIBLE = '0'.

*   add offset for scrollable area
    IF G_COL_NO = G_PS_FIX_COLS.
      G_COL_NO = G_COL_NO + G_PS_BEGIN - 1.
    ENDIF.

*   next column
    G_COL_NO = G_COL_NO + 1.

*   read cells for attributes
    READ TABLE G_RESULTS WITH KEY
        ROW_NO = G_ROW_NO
        COL_NO = G_COL_NO.
    IF NOT SY-SUBRC IS INITIAL.
*     screen-active = 0.
*     screen-input = 1.
*     screen-display_3d = 1.
      CLEAR G_RESULTS.
    ENDIF.

    IF G_RESULTS-INPUT_FLG IS INITIAL.
      SCREEN-INPUT = '0'.
    ELSE.
      SCREEN-INPUT = '1'.
    ENDIF.

    IF G_RESULTS-COLOR = 1.
      SCREEN-INTENSIFIED = '1'.
    ELSE.
      SCREEN-INTENSIFIED = '0'.
    ENDIF.

    IF G_RESULTS-REF_FIELD CS 'CODE'                        "#EC NOTEXT
      AND NOT G_RESULTS-INPUT_FLG IS INITIAL.
      SCREEN-VALUE_HELP = '1'.
    ELSE.
      SCREEN-VALUE_HELP = '0'.
    ENDIF.

    MODIFY SCREEN.

  ENDLOOP.

  MOVE SY-LOOPC TO LOOP_INKREMENT_RESULTS.

ENDMODULE.                             " ATTRIBUTES  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  VALIDATE_RESULTS  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE VALIDATE_RESULTS OUTPUT.

  PERFORM VALIDATE_RESULTS.

ENDMODULE.                             " VALIDATE_RESULTS  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  COLUMN_WIDTH  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE COLUMN_WIDTH OUTPUT.

  PERFORM COLUMN_WIDTH USING ' '
                             ' '.

ENDMODULE.                             " COLUMN_WIDTH  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  SET_CURSOR  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE SET_CURSOR OUTPUT.
  SET CURSOR FIELD CURSOR_FIELD LINE CURSOR_LINE.
ENDMODULE.                             " SET_CURSOR  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_POSTING_READY  OUTPUT
*&---------------------------------------------------------------------*
*       Überprüft, ob der Sicherungsvorgang abgeschlossen ist
*----------------------------------------------------------------------*
MODULE CHECK_POSTING_READY OUTPUT.
  PERFORM CHECK_POSTING_READY.
ENDMODULE.                             " CHECK_POSTING_READY  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_CHARS_UNLOCKED  OUTPUT
*&---------------------------------------------------------------------*
*       Überprüft, ob die extern gesperrten Merkmale mittlerweile
*       entsperrt sind.
*----------------------------------------------------------------------*
MODULE CHECK_CHARS_UNLOCKED OUTPUT.
  PERFORM CHECK_CHARS_UNLOCKED.
ENDMODULE.                             " CHECK_CHARS_UNLOCKED  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  INITIALIZE_PBO  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE INITIALIZE_PBO OUTPUT.

  G_PAGEBEGIN_CHAR = CON_RESULTS-TOP_LINE.

ENDMODULE.                             " INITIALIZE_PBO  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  status_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0200 OUTPUT.

  SET PF-STATUS '0200'.
  SET TITLEBAR  '0200'.

ENDMODULE.                 " status_0200  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0300 OUTPUT.

  SET PF-STATUS '0300'.
  SET TITLEBAR  '0300' WITH QPRS-PHYNR.

ENDMODULE.
