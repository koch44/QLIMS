*----------------------------------------------------------------------*
***INCLUDE ZXQPLTOP.
*----------------------------------------------------------------------*
TABLES:
  yqm_prggstd_t.

DATA:
  gv_dynnr TYPE sy-dynnr,
  gs_qapp  TYPE qapp,
  gs_ihpa  TYPE ihpa,
  gs_iflot TYPE iflot,
  gs_kna1  TYPE kna1.

CONTROLS: gv_subscreen TYPE TABSTRIP.

* Hilfskonstante
CONSTANTS:
      gc_objnrart(2) TYPE c VALUE 'OR'.  "Art der Objektnr (OR = ORDER)

* Globale Struktur fuer die Anzeige in Dynpro
DATA: gs_qals TYPE qals.

* Weitere Hilfsfelder zur Anzeige in Dynpro bzw zur Aufbereitung, die
* nicht aus QALS kommen
* Subscreen Auftraggeber
DATA:
  gv_tplnr_tmp TYPE qapp-tplnr,    "Technischer Platz temporaer
  gv_aufnr     TYPE iloa-aufnr,    "Abrechnungsauftragsnummer
  gv_kunnrag   TYPE qals-kunnr,    "Kundennummer AG
  gv_kunnrzl   TYPE qals-kunnr,    "Kundennummer ZL
  gv_rolle(2)  TYPE c,             "Partnerrolle AG oder ZL
  gv_objnr     TYPE ihpa-objnr,    "Objektnummer des CS-Auftrag
  gv_telnr     TYPE adrc-tel_number,  "Telefonnummer
  gv_faxnr     TYPE adrc-fax_number.  "Faxnummer
