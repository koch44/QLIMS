*&---------------------------------------------------------------------*
*& Include          ZXQPLU04
*&---------------------------------------------------------------------*

* I_QALS-Daten in Hilfsstruktur zur Anzeige uebernehmen
* Achtung: Nur beim ersten Aufruf!
IF gs_qals IS INITIAL.
  MOVE-CORRESPONDING i_qals TO gs_qals.
ENDIF.

*-----------------------------------------------------------------------
* Ermittlung des Technischen Platzes --> Speichern in globale Variable
* Dieser ist entweder schon in I_QALS bei freigegeben Prueflos oder
* muss ueber QAPP ermittelt werden
IF gs_qals-yqm_tplnr IS INITIAL.
  SELECT * FROM qapp INTO gs_qapp
    WHERE prueflos EQ gs_qals-prueflos.
    gv_tplnr_tmp = gs_qapp-tplnr.
    EXIT.
  ENDSELECT.
  IF sy-subrc <> 0.
* Umformatierung Technischer Platz fuer Ausgabe auf Dynpro
    WRITE gv_tplnr_tmp TO gs_qals-yqm_tplnr.
  ENDIF.
ENDIF.

* Ermittlung Kurztext fuer Technischen Platz aus I_QALS
* (steht schon standardmaessig bereit)
* --> Speichern in globale Variable
*gv_tplnr_ktext = gs_qals-ktextmat.

*-----------------------------------------------------------------------
* Ermittlung des Dauerauftrages aus Technischen Platz
* --> Speichern in globale Variable
*SELECT SINGLE * FROM iflo
*  WHERE tplnr EQ gs_qals-yqm_tplnr
*    AND spras EQ sy-langu.
*IF sy-subrc EQ 0.
*  gv_aufnr = iflo-daufn.
*ENDIF.

* Ermittlung von Technischen Platz Informationen
* --> Speichern in globale Variable
SELECT SINGLE * FROM iflot
  INTO gs_iflot
  WHERE tplnr EQ gs_qals-yqm_tplnr.
IF sy-subrc NE 0.
  CLEAR gs_iflot.
ENDIF.

*-----------------------------------------------------------------------
* Ermittlung der Kundennummer(n) --> Speichern in globale Variable
* Diese sind entweder schon in I_QALS bei freigegeben Prueflos oder
* muessen ueber AFIH ermittelt werden
* (Achtung: 2 Kunden moeglich - Partnerrolle AG und ZL)
* Wenn kein ZL, dann Uebernahme AG in ZL (nur fuer Dynproanzeige)
CLEAR gv_objnr.

CONCATENATE gc_objnrart gs_qals-aufnr INTO gv_objnr.

*1.) partnerrolle ag
IF NOT ( gs_qals-kunnr IS INITIAL ).
  gv_kunnrag = gs_qals-kunnr.
ELSE.
  SELECT SINGLE * FROM ihpa INTO gs_ihpa
                  WHERE objnr = gv_objnr
                  AND   parvw = 'AG'.
  IF sy-subrc EQ 0 AND NOT ( gs_ihpa-parnr IS INITIAL ).
    gv_kunnrag = gs_ihpa-parnr.
  ENDIF.
ENDIF.

*2.) partnerrolle zl
IF NOT ( gs_qals-yqm_kunnrzl IS INITIAL ).
  gv_kunnrzl = gs_qals-yqm_kunnrzl.
  gv_rolle   = 'ZL'.
ELSE.
  SELECT SINGLE * FROM ihpa INTO gs_ihpa
                  WHERE objnr = gv_objnr
                  AND   parvw = 'ZL'.
  IF sy-subrc EQ 0 AND NOT ( gs_ihpa-parnr IS INITIAL ).
    gv_kunnrzl = gs_ihpa-parnr.
    gv_rolle   = 'ZL'.
  ELSE.
    gv_kunnrzl = gv_kunnrag.
    gv_rolle   = 'AG'.
  ENDIF.
ENDIF.

*-----------------------------------------------------------------------
* Ermittlung der Anschriftsdaten fuer Partner ZL (wenn vorhanden,
* sonst AG (steht dann aber auch in ZKUNNRZL)) plus der
* Kommunikationsdaten
SELECT SINGLE * FROM kna1 INTO gs_kna1
  WHERE kunnr EQ gs_qals-kunnr.
IF sy-subrc = 0.
* Telefon und Fax umspeichern zwecks einheitlicher Ausgabe
  WRITE gs_kna1-telf1 TO gv_telnr.
  WRITE gs_kna1-telfx TO gv_faxnr.
ENDIF.
*
**-----------------------------------------------------------------------
** Vertragsdaten
** 1.) Ermitteln Plankurztext fuer Ermittlung Rabattdaten
*CLEAR zplantext.
*SELECT * FROM plko
*  WHERE plnty EQ gs_qals-plnty
*    AND plnnr EQ gs_qals-plnnr
*    AND plnal EQ gs_qals-plnal.
*  zplantext = plko-ktext.
*  EXIT.
*ENDSELECT.
*
** 2.) Ermittlung der Rabattdaten
*SELECT * FROM zqmrabatt
*  WHERE zzrabattjahr  EQ sy-datum+0(4)
*    AND zzkunnr       EQ zkunnrzl
*    AND ( zzrabattaktiv EQ 'X' OR zzrabattzaehler GT 0 ).
*  IF zqmrabatt-zzplanendung IS INITIAL. "Kundenrabatt
*    zrabattkunde = zqmrabatt-zzrabattkunde.
*    zzahlweise   = zqmrabatt-zzzahlweise.
*    CASE zzahlweise.
*      WHEN 'M'.    zzweisetxt = 'monatlich'.
*      WHEN 'Q'.    zzweisetxt = 'quartalsweise'.
*      WHEN 'J'.    zzweisetxt = 'jährlich'.
*      WHEN OTHERS. zzweisetxt = 'undefiniert'.
*    ENDCASE.
*  ELSE.                              "eventuell Planrabatt
**   Kuerzel in Text vorhanden
*    TRANSLATE zplantext TO UPPER CASE.
*    IF zplantext+31(9) EQ zqmrabatt-zzplanendung.
*      zrabattplan = zqmrabatt-zzrabattplan.
*    ENDIF.
*  ENDIF.
*ENDSELECT.
*
**-----------------------------------------------------------------------
** Nebenkosten
*
** Wenn Leistungsarten initial --> Default setzen
** IF gs_qals-zzlstarfs IS INITIAL. gs_qals-zzlstarfs  = 'WGH3'. ENDIF.
** IF gs_qals-zzlstarmat IS INITIAL. gs_qals-zzlstarmat = 'WCMY'. ENDIF
**IF gs_qals-zzlstarkm  IS INITIAL. gs_qals-zzlstarkm  = 'WCMY'. ENDIF.         " Gme 28.1.15 AOG -> NSG
*IF gs_qals-zzlstarkm  IS INITIAL. gs_qals-zzlstarkm  = 'QBYZ'. ENDIF.          " Gme 28.1.15 AOG -> NSG
** Wo020106 - Neuer Vorschlagswert Leistungsart ab 1.1.2007
**IF gs_qals-zzlstarst  IS INITIAL. gs_qals-zzlstarst  = 'WGH3'. ENDIF.
**IF gs_qals-zzlstarst  IS INITIAL. gs_qals-zzlstarst  = 'WEN3'. ENDIF.         " Gme 28.1.15 AOG -> NSG
**IF gs_qals-zzlstarst  IS INITIAL. gs_qals-zzlstarst  = 'QEN3'. ENDIF.          " Gme 28.1.15 AOG -> NSG, Gme 17.12.18
**IF gs_qals-zzlstarst  IS INITIAL. gs_qals-zzlstarst  = 'QBYV'. ENDIF.          " Gme 17.12.18
*IF gs_qals-zzlstarst  IS INITIAL. gs_qals-zzlstarst  = 'YBYV'. ENDIF.          " Gme 27.1.20
* Wo020106
