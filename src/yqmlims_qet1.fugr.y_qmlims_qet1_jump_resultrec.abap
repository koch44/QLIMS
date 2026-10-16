FUNCTION Y_QMLIMS_QET1_JUMP_RESULTREC.
*"--------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_ROW_NO) LIKE  SY-CUROW
*"     VALUE(I_COL_NO) LIKE  SY-CUCOL
*"     VALUE(I_AREA) LIKE  SY-TNAME
*"     VALUE(I_OK_CODE) LIKE  T185-FCODE
*"  TABLES
*"      T_SPECS STRUCTURE  QETBCELLS
*"      T_RESULTS STRUCTURE  QETBCELLS
*"  EXCEPTIONS
*"      NO_JUMP_RR
*"      NO_LOT_OPER
*"      NO_IP
*"--------------------------------------------------------------------
  DATA:
    L_INSP_POINT_DATA     LIKE BAPI2045L4,
    L_REQUIREMENTS_CHAR   LIKE BAPI2045D1,
    L_REQUIREMENTS_IP     LIKE BAPI2045D5,
    L_INSPSAMPLE          LIKE T_RESULTS-INSPSAMPLE,
    L_IP_EXIST            TYPE C,
    L_QAPP                LIKE QAPP,
    L_VORGLFNR            LIKE QAPP-VORGLFNR,
    L_ACTIVITY            LIKE QAQEE-AKTIVITAET,
    L_ISBLOCKED           TYPE XFELD.

  IF I_AREA NE 'CON_RESULTS'.          "#EC NOTEXT
    MESSAGE S013 RAISING NO_JUMP_RR.
* Den Cursor auf ein Ergebnisfeld positionieren
  ENDIF.

  READ TABLE T_RESULTS WITH KEY
                        ROW_NO = I_ROW_NO
                        COL_NO = I_COL_NO.

  IF NOT SY-SUBRC IS INITIAL.
    MESSAGE S012 RAISING NO_JUMP_RR.
* Es sind keine Daten vorhanden
  ENDIF.

  IF  T_RESULTS-INSPLOT  IS INITIAL
   OR T_RESULTS-INSPOPER IS INITIAL
   OR T_RESULTS-INSPCHAR IS INITIAL.
    MESSAGE S013 RAISING NO_LOT_OPER.
* Den Cursor auf ein Ergebnisfeld positionieren
  ENDIF.

  IF I_OK_CODE EQ 'QETBJPRRC'.         "#EC NOTEXT
* Changes
    L_ACTIVITY = 'C'.
  ELSEIF I_OK_CODE EQ 'QETBJPRRD'.     "#EC NOTEXT
* Display
    L_ACTIVITY = 'D'.
  ENDIF.

* Status
  IF L_ACTIVITY = 'C'.
    CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
         EXPORTING
              I_CELLS     = T_RESULTS
         IMPORTING
              E_ISBLOCKED = L_ISBLOCKED.
    IF NOT L_ISBLOCKED IS INITIAL.
      MESSAGE S035 RAISING NO_JUMP_RR.
    ENDIF.
  ENDIF.

* Check if results exists, only when display individually
  IF L_ACTIVITY = 'D'
   AND T_RESULTS-INSPSAMPLE <> '000000'.

    CALL FUNCTION 'QET4_GET_SAMPLE_RESULTS'
         EXPORTING
              I_INSPLOT    = T_RESULTS-INSPLOT
              I_INSPOPER   = T_RESULTS-INSPOPER
              I_INSPCHAR   = T_RESULTS-INSPCHAR
              I_INSPSAMPLE = T_RESULTS-INSPSAMPLE
         EXCEPTIONS
              NOT_FOUND    = 1
              OTHERS       = 2.

    IF SY-SUBRC <> 0.
      MESSAGE S026 RAISING NO_JUMP_RR.
* Es ist kein Einzelergebnis vorhanden
    ENDIF.
  ENDIF.

* Alten Wert des Kennzeichens "Rückmeldenummer verwenden" lesen
  GET PARAMETER ID 'QRV' FIELD G_SPA_QRV.
  IF NOT SY-SUBRC IS INITIAL.
    CLEAR G_SPA_QRV.
  ENDIF.

* Liefert die Vorgaben zum Merkmal
  CALL FUNCTION 'QET4_GET_CHAR_REQUIREMENTS'
       EXPORTING
            I_INSPLOT      = T_RESULTS-INSPLOT
            I_INSPOPER     = T_RESULTS-INSPOPER
            I_INSPCHAR     = T_RESULTS-INSPCHAR
       IMPORTING
            E_REQUIREMENTS = L_REQUIREMENTS_CHAR.

* Liefert die Vorgaben für Prüfpunkte
  CALL FUNCTION 'QET4_GET_IP_REQUIREMENTS'
       EXPORTING
            I_INSPLOT      = T_RESULTS-INSPLOT
            I_INSPOPER     = T_RESULTS-INSPOPER
       IMPORTING
            E_REQUIREMENTS = L_REQUIREMENTS_IP
       EXCEPTIONS
            NOT_FOUND      = 1
            OTHERS         = 2.

  IF SY-SUBRC IS INITIAL.
* Prüfpunktabwicklung
    MOVE KREUZ TO L_IP_EXIST.
  ENDIF.

  IF NOT L_IP_EXIST IS INITIAL.
* Aus Eingabezeile kann nicht in EE abgesprungen werden
    IF T_RESULTS-INSPSAMPLE = C_MAX_PPUNKT.
      MESSAGE S034 RAISING NO_IP.
    ENDIF.

* Liefert die Daten eines Prüfpunktes
    CALL FUNCTION 'QET4_GET_INSP_POINT'
         EXPORTING
              I_INSPLOT         = T_RESULTS-INSPLOT
              I_INSPOPER        = T_RESULTS-INSPOPER
              I_INSPPOINT       = T_RESULTS-INSPSAMPLE
         IMPORTING
              E_INSP_POINT_DATA = L_INSP_POINT_DATA
         EXCEPTIONS
              NOT_FOUND         = 1
              OTHERS            = 2.

    IF NOT SY-SUBRC IS INITIAL.
      MESSAGE S014 RAISING NO_IP.
* Der Cursor ist falsch positioniert (Prüfpunktidentifikation)
    ENDIF.

* Ermittlung der internen Vorgangsnummer
    CALL FUNCTION 'QIBP_GET_VORGLFNR'
         EXPORTING
              I_INSP_LOT = T_RESULTS-INSPLOT
              I_OPER_NO  = T_RESULTS-INSPOPER
         IMPORTING
              E_VORGLFNR = L_VORGLFNR.

  ENDIF.                               " IF NOT L_IP_EXIST IS INITIAL.

* Überprüfen, ob alles gesichert ist
  CALL FUNCTION 'QET4_CHECK_ALL_IS_SAVED'
       TABLES
            T_CELLS         = T_RESULTS
       EXCEPTIONS
            NOT_SAVED       = 1
            POSTING_RUNNING = 2
            OTHERS          = 3.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    EXIT.
  ENDIF.

* Alle Merkmale des Prüfloses entsperren, wegen der Funktion
* 'naechster Vorgang' in der Ergebniserfassung
* Nur wenn pflegen Ergebniserfassung
  IF L_ACTIVITY EQ 'C'.
    CALL FUNCTION 'QET4_UNLOCK_CHARS_OF_INSPLOT'
         EXPORTING
              I_ROW_NO     = I_ROW_NO
              I_COL_NO     = I_COL_NO
              I_AREA       = I_AREA
         TABLES
              T_SPECS      = T_SPECS
              T_RESULTS    = T_RESULTS
         EXCEPTIONS
              NOT_POSSIBLE = 1
              OTHERS       = 2.
    IF SY-SUBRC <> 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      EXIT.
    ENDIF.
  ENDIF.

* SPA für Ergebniserfassung
  SET PARAMETER ID 'QLS' FIELD T_RESULTS-INSPLOT.
  SET PARAMETER ID 'QVO' FIELD T_RESULTS-INSPOPER.
  SET PARAMETER ID 'QMO' FIELD '1'.
  SET PARAMETER ID 'QRU' FIELD L_REQUIREMENTS_CHAR-CONFIRM_NO.
  IF L_ACTIVITY EQ 'C'.
    CLEAR L_INSPSAMPLE.
    SET PARAMETER ID 'QPO' FIELD L_INSPSAMPLE.
  ELSE.
    SET PARAMETER ID 'QPO' FIELD T_RESULTS-INSPSAMPLE.
  ENDIF.

  IF NOT L_REQUIREMENTS_CHAR-CONFIRM_NO IS INITIAL
   AND L_ACTIVITY EQ 'C'.
* Kennzeichen "Rückmeldenummer verwenden" nur beim Erfassen
    SET PARAMETER ID 'QRV' FIELD 'X'.
  ELSE.
* Kennzeichen "Rückmeldenummer  n i c h t  verwenden"
    SET PARAMETER ID 'QRV' FIELD ' '.
  ENDIF.
* ---------------------------------------------------------------------
* Call resultrecording
  IF NOT L_IP_EXIST IS INITIAL.
* Erfassung zum Prüfpunkt
* L_QAPP füllen wegen der Memoryverwaltung
    SELECT SINGLE * FROM QAPP INTO L_QAPP
                   WHERE PRUEFLOS EQ T_RESULTS-INSPLOT
                     AND VORGLFNR EQ L_VORGLFNR
                     AND PROBENR  EQ T_RESULTS-INSPSAMPLE.

    CASE L_REQUIREMENTS_IP-IP_TYPE.
      WHEN ' '.
* Prüfpunkttyp Fertigung
        IF NOT L_REQUIREMENTS_IP-IDENT_KEY IS INITIAL.
          SET PARAMETER ID 'QBK' FIELD L_REQUIREMENTS_IP-IDENT_KEY.
        ENDIF.
        IF T_RESULTS-INSPSAMPLE <> C_MAX_PPUNKT.
          EXPORT QAPPD FROM L_QAPP TO MEMORY ID 'QAPPD'.
        ENDIF.
        IF L_ACTIVITY EQ 'C'.
          CALL TRANSACTION 'QE11' AND SKIP FIRST SCREEN.
        ELSE.
          CALL TRANSACTION 'QE09' AND SKIP FIRST SCREEN.
        ENDIF.
      WHEN '1'.
* Prüfpunkttyp Equipment
        IF NOT L_REQUIREMENTS_IP-IDENT_KEY IS INITIAL.
          SET PARAMETER ID 'QB1' FIELD L_REQUIREMENTS_IP-IDENT_KEY.
        ENDIF.
        IF T_RESULTS-INSPSAMPLE <> C_MAX_PPUNKT.
          EXPORT QAPPD FROM L_QAPP TO MEMORY ID 'QAPPD'.
        ENDIF.
        IF L_ACTIVITY EQ 'C'.
          CALL TRANSACTION 'QE17' AND SKIP FIRST SCREEN.
        ELSE.
          CALL TRANSACTION 'QE09' AND SKIP FIRST SCREEN.
        ENDIF.
      WHEN '2'.
* Prüfpunkttyp Technischer Platz
        IF NOT L_REQUIREMENTS_IP-IDENT_KEY IS INITIAL.
          SET PARAMETER ID 'QB2' FIELD L_REQUIREMENTS_IP-IDENT_KEY.
        ENDIF.
        IF T_RESULTS-INSPSAMPLE <> C_MAX_PPUNKT.
          EXPORT QAPPD FROM L_QAPP TO MEMORY ID 'QAPPD'.
        ENDIF.
        IF L_ACTIVITY EQ 'C'.
          CALL TRANSACTION 'QE20' AND SKIP FIRST SCREEN.
        ELSE.
          CALL TRANSACTION 'QE09' AND SKIP FIRST SCREEN.
        ENDIF.
      WHEN '3'.
* Prüfpunkttyp Physische Probe
        IF NOT L_REQUIREMENTS_IP-IDENT_KEY IS INITIAL.
          SET PARAMETER ID 'QB3' FIELD L_REQUIREMENTS_IP-IDENT_KEY.
        ENDIF.
        IF T_RESULTS-INSPSAMPLE <> C_MAX_PPUNKT.
          EXPORT QAPPD FROM L_QAPP TO MEMORY ID 'QAPPD'.
        ENDIF.
        IF L_ACTIVITY EQ 'C'.
          CALL TRANSACTION 'QE23' AND SKIP FIRST SCREEN.
        ELSE.
          CALL TRANSACTION 'QE09' AND SKIP FIRST SCREEN.
        ENDIF.
    ENDCASE.

    IF NOT l_requirements_ip-partlots IS INITIAL.
*     Delete Memory of update task of partial lots
      CALL FUNCTION 'QTLS_INITIALIZE'.
*     Wait until update task from QE11 is ready
      DO.
        CALL FUNCTION 'ENQUEUE_EQQAMV1'
          EXPORTING
            prueflos       = t_results-insplot
            vorglfnr       = l_vorglfnr
            _scope         = '3'
            _wait          = 'X'
          EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
        IF sy-subrc <> 1.
          EXIT.
        ENDIF.
      ENDDO.
      CALL FUNCTION 'DEQUEUE_EQQAMV1'
        EXPORTING
          prueflos = t_results-insplot
          vorglfnr = l_vorglfnr
          _scope   = '3'.
*         _SYNCHRON        = ' '
    ENDIF.

* Teillose im SD sind nicht unterstützt
* ELSEIF NOT L_LOS-LSINFO-STAT02 IS INITIAL.
* Erfassung zum Teillos und Vorgang

  ELSE.
* Erfassung zum Vorgang
    IF L_ACTIVITY EQ 'C'.
      CALL TRANSACTION 'QE01' AND SKIP FIRST SCREEN.

      CALL FUNCTION 'QEEA_INITIALIZE_LOT_BASETABS'. "note 1305355

    ELSE.
      CALL TRANSACTION 'QE09' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDIF.

* Parameter auf alten Wert oder ' ' setzen
  SET PARAMETER ID 'QRV' FIELD G_SPA_QRV.

ENDFUNCTION.
