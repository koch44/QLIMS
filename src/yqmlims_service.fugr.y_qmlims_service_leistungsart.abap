FUNCTION y_qmlims_service_leistungsart.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IV_SEARCH_GEN)
*"     REFERENCE(IV_WERKS) TYPE  QPMK-WERKS
*"     REFERENCE(IV_DUMMY10) TYPE  QPMK-DUMMY10
*"  EXPORTING
*"     REFERENCE(EV_DUMMY10) TYPE  QPMK-DUMMY10
*"----------------------------------------------------------------------


* Hilfsvariable fuer Dummy10
  DATA: lv_dummy10_tmp TYPE qpmk-dummy10.

* Dummy10-Wert uebernehmen
  lv_dummy10_tmp = iv_dummy10.

* Nur etwas tun, wenn Info-Feld 1 nicht neu mit initial belegt
  IF lv_dummy10_tmp IS INITIAL.
    EXIT.
  ENDIF.

* Konvertierung in Grossbuchstaben
  TRANSLATE lv_dummy10_tmp TO UPPER CASE.

* Kostenrechnungskreis ermitteln (ueber BUKRS und Bewertungskreis/Werk)
* 1.) Buchungskreis ermitteln
  SELECT SINGLE bukrs FROM t001k
    INTO @DATA(lv_bukrs)
    WHERE bwkey = @iv_werks.
* Buchungskreis nicht gefunden
  IF sy-subrc <> 0.
    MESSAGE e720(yqmlims).
  ENDIF.
* 2.) Kostenrechnungskreis ermitteln
  SELECT kokrs FROM tka02
    INTO @DATA(lv_kokrs)
    WHERE bukrs EQ @lv_bukrs.
    EXIT.                          "beim ersten gefundenen Satz aufhoeren
  ENDSELECT.
* Kostenrechnungskreis nicht gefunden
  IF sy-subrc = 0.
    gv_kokrs = lv_kokrs.
  ELSE.
    CLEAR gv_kokrs.
    MESSAGE e721(yqmlims).
  ENDIF.

  IF lv_dummy10_tmp NA '*'.               "Kein * im Eingabefeld
* Check, ob eingegebene Leistungsart vorhanden (nein --> Fehlermeldung)
    SELECT COUNT(*) FROM csla
*      INTO @DATA(ls_csla)
      WHERE kokrs EQ @gv_kokrs
        AND lstar EQ @lv_dummy10_tmp
        AND datbi GE @sy-datum
        AND sprkz NE 'X'.              "nicht gesperrt
*      EXIT.                          "beim ersten gefundenen Satz aufhoeren
*    ENDSELECT.
* Leistungsart nicht gefunden
    IF sy-subrc NE 0.
      MESSAGE e722(yqmlims) WITH lv_dummy10_tmp gv_kokrs.
    ENDIF.
  ELSE.                             "Generische Suche nach Leistungsart
* Generische Suche nicht erwuenscht (Importparameter Funktionsbaustein)
    IF iv_search_gen NE 'X'.
      MESSAGE e722(yqmlims) WITH lv_dummy10_tmp gv_kokrs.
    ENDIF.
* Aufruf Dnypro zur Angabe Kostenstelle zwecks Tarifermittlung
    CALL SCREEN 0050 STARTING AT 20 11.
    IF NOT gv_kostl IS INITIAL.
* Moegliche Leistungsarten suchen und Liste ausgeben
      PERFORM get_activities_and_list USING lv_dummy10_tmp.
      lv_dummy10_tmp = gv_sel_lstar.
    ENDIF.
  ENDIF.

* Leistungsart ok.
  ev_dummy10 = lv_dummy10_tmp.

ENDFUNCTION.
