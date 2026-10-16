FUNCTION-POOL YQMLIMS_QET5 MESSAGE-ID QETB.

*include <icon>.

CONTROLS:
* Table Control for results
  CON_RESULTS TYPE TABLEVIEW USING SCREEN 0100.
*-
TABLES:
* Structure for displaying on screen
  QPRS,
  CONSHOW,
  *CONSHOW.
*-
DATA:
* Screen tables
  TITLE_R    LIKE CONSHOW,
  RESULTSTAB LIKE CONSHOW OCCURS 0 WITH HEADER LINE.
*-
DATA:
* Information about the cursor
  CURSOR_FIELD           LIKE SY-TNAME,
  CURSOR_LINE            LIKE SY-STEPL,
  CURSOR_AREA            LIKE SY-TNAME,
  SAVE_FLAG              TYPE QKZ,
  G_PAGEBEGIN_CHAR       LIKE SY-TABIX       VALUE 1,
  G_ROW_NO               LIKE SY-CUROW,
  G_COL_NO               LIKE SY-CUCOL,
  G_MAX_COLUMN           TYPE I  VALUE 50,       " max. Anzahl Spalten in CONSHOW
  G_MAX_COL_NO           TYPE I,            " Anzahl der Spalten inkl. fester Sp.
  G_PS_BEGIN             TYPE I  VALUE  1,       " Nr. der ersten bewegl. Spalte
  G_PS_FIX_COLS          TYPE I VALUE  3,       " Anzahl der festen Spalten

* Scroll positions of table controls
  G_RESULTS_LEFT_COL     LIKE CON_RESULTS-LEFT_COL,

* Position in tables
  TABIX_RESULTSTAB       LIKE SY-TABIX,
  LOOP_INKREMENT_RESULTS LIKE SY-LOOPC,

* Code for further processing
  OK-CODE                LIKE T185-FCODE,
  OLD_OK_CODE            LIKE OK-CODE.

DATA:
* various flags
  G_FIRST_RUN_FINISH    TYPE C      VALUE 'X'.

DATA:
  G_TITLE_R LIKE QETBCELLS OCCURS 0 WITH HEADER LINE,
  G_RESULTS LIKE QETBCELLS OCCURS 0 WITH HEADER LINE,
  G_ROWS    LIKE QETBCELLS OCCURS 0 WITH HEADER LINE.

DATA: G_WORKLIST       LIKE SY-CPROG.
DATA: G_SCREEN_MANAGER LIKE SY-CPROG.

DATA: G_GUI_TITLE      LIKE RSMPE-TITTEXT.

DATA: G_PGMID_SUBPOR     LIKE SY-REPID.
DATA: G_DYNNR_SUBPOR     LIKE SY-DYNNR.

DATA: C_SET              TYPE C VALUE 'X'.
DATA  G_ICON_NO_DATA(60) TYPE C.
DATA: G_LEN_MAX          TYPE I.

DATA: US_QAMV            LIKE QAMV.
DATA: UT_QAMV            TYPE TABLE OF QAMV.

DATA: US_QASR            LIKE QASR.
DATA: UT_QASR            TYPE TABLE OF QASR.
