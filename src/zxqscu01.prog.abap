*&---------------------------------------------------------------------*
*& Include          ZXQSCU01
*&---------------------------------------------------------------------*
* Es darf keine Leistungsart (Infofeld-1) eingetragen werden
IF NOT ( i_qmtb-dummy10 IS INITIAL ).
  MESSAGE i723(yqmlims).
ENDIF.

* Es darf keine Parameter-Nr. (Infofeld-2) eingetragen werden
IF NOT ( i_qmtb-dummy20 IS INITIAL ).
  MESSAGE i724(yqmlims).
ENDIF.

* Es darf keine KZ Grafik Prüfbericht (Infofeld-3) eingetragen werden
IF NOT ( i_qmtb-dummy40 IS INITIAL ).
  MESSAGE i748(yqmlims).
ENDIF.


* Achtung:
* das Feld e_dummy10 (Leistungsart) darf nicht gesetzt werden
* das Feld e_dummy20 (Parameter-Nr.) darf nicht gesetzt werden
* das Feld e_dummy40 (Grafik Pruefbericht) darf nicht gesetzt werden
* Grund: Diese Felder werden nur zum Pruefmerkmal hinterlegt; ein
* Eintrag zur Pruefmethode wuerde die Uebernahme in den Pruefplan
* uebersteuern
