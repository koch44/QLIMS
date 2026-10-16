*&---------------------------------------------------------------------*
*& Include          YQ_LFW1TOP
*&---------------------------------------------------------------------*
CLASS lcl_lfw DEFINITION DEFERRED.

TABLES: qals, qave, qapo, qamv, qamr, qapp, plko, kna1, qpcd,
        iflot, qasr, qpmk,  qmtt, qpmt, iloa, adrc, yqm_code_t,
        yqm_anlass_t, stxh, jest, yqm_0100form_t, tapl.


TYPES: BEGIN OF gty_adr6,
         addrnumber TYPE adr6-addrnumber,
         persnumber TYPE adr6-persnumber,
         smtp_addr  TYPE adr6-smtp_addr,
       END OF gty_adr6,
       BEGIN OF gty_t1,
         mandant          TYPE sy-mandt,
         yqm_extension    TYPE iflot-yqm_extension,
         kunnr            TYPE kna1-kunnr,
         yqm_wasserwirt   TYPE iflot-yqm_wasserwirt,
         yqm_anlass       TYPE qals-yqm_anlass,
         strno            TYPE iflos-strno,
         merknr(8),
         yqm_wasserwirtnr TYPE iflot-yqm_wasserwirtnr,
         yqm_bestellnr    TYPE iflot-yqm_bestellnr,
         yqm_medium       TYPE iflot-yqm_medium,
         kurztext         TYPE qpmt-kurztext,
         pltxt            TYPE iflo-pltxt,
         name1            TYPE kna1-name1,
         prueflos         TYPE qals-prueflos,
         ktextlos         TYPE qals-ktextlos,
         slwbez           TYPE qals-slwbez,
         phynr            TYPE qapp-phynr,
         ktextphynr       TYPE qprs-ktext,
         datum            TYPE qals-yqm_probedatum,
         tplnr            TYPE iflos-tplnr,
         mittelwert(10),
         attribut         TYPE qasr-attribut,
         steuerkz         TYPE qamv-steuerkz,
         eqfnr            TYPE iloa-eqfnr,
         iloan            TYPE iloa-iloan,
         yqm_ueberwachung TYPE qals-yqm_ueberwachung,
         dummy20          TYPE qpmk-dummy20,
         betreiber        TYPE iflot-yqm_betreiber,
         bez              TYPE iflot-yqm_bezeichnung,
         probezeit        TYPE qals-yqm_probezeit,
         objnr            TYPE qals-objnr,
         probgew          TYPE qals-yqm_probengewinnung,    "CF20191115
         exkuwwanpl(70),
       END OF gty_t1.


DATA: go_lfw       TYPE REF TO lcl_lfw,
*      gt_ya   TYPE STANDARD TABLE OF yqamtsbez WITH HEADER LINE ##NEEDED.
      gs_ya        TYPE yqm_amtsbez_t,
      gs_qals      TYPE qals,
      gs_zqmanlass TYPE yqm_anlass_t,
      gs_iflot     TYPE iflot,
      gs_jest      TYPE jest.
