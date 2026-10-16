FUNCTION y_qmlims_service_event_lot_cre.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(OBJTYPE) TYPE  SWETYPECOU-OBJTYPE
*"     VALUE(OBJKEY) TYPE  SWEINSTCOU-OBJKEY
*"     VALUE(EVENT) TYPE  SWEINSTCOU-EVENT
*"     VALUE(RECTYPE) TYPE  SWETYPECOU-RECTYPE
*"  TABLES
*"      EVENT_CONTAINER STRUCTURE  SWCONT
*"----------------------------------------------------------------------

  DATA: ls_qals            TYPE qals,
        lt_qals            TYPE TABLE OF qals,
        ls_event_container TYPE swcont,
        lv_event           TYPE swcont-value,
        lv_objid           TYPE cdobjectv,
        lv_error           TYPE string,
        lv_valid           TYPE c,
        lv_prueflos        TYPE qplos.

  DATA: ls_pr_qpmk_data TYPE yqm03_pr_qpmk_data.
  DATA: lt_pr_qpmk_data TYPE TABLE OF yqm03_pr_qpmk_data.
  DATA: lv_pn            TYPE yqm_probenehmer03.
  DATA: lv_pn_datum      TYPE yqm_probenahmedatum.
  DATA: lv_pn_zeit       TYPE yqm_probenahmezeit.
  DATA: lv_pn_temperatur TYPE yqm_temperatur_pn.

  REFRESH lt_qals.

  LOOP AT event_container INTO ls_event_container.
    CASE ls_event_container-element.
      WHEN gc_elem_evt_name.
        lv_event         = ls_event_container-value.
      WHEN gc_elem_evt_objkey.
        lv_prueflos      = ls_event_container-value.
      WHEN OTHERS.
        CONTINUE.
    ENDCASE.
  ENDLOOP.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = lv_prueflos
    IMPORTING
      output = lv_prueflos.

** Only Status changes are relevant for this function module to be executed
** Field CHANGENR is NOT filled in case of Status Change
*  CHECK lv_cd_changenr IS INITIAL.

* Fetch object number and Status Profile for respective Inspection Lot Number
  SELECT SINGLE * FROM qals INTO ls_qals
                WHERE prueflos EQ lv_prueflos.
  IF sy-subrc <> 0.
    CLEAR ls_qals.
    RAISE read_failed.
  ENDIF.

* enn das Prüflos aus der Probeneeingangsregistrierung erzeugt wurde, sollen
* die Messwerte aus dr Konfiguration hier nicht ins Prüflos weitergeschrieben werden
* --> Dies passiert in diesem Fall im Rahmen der Transaktion YQM03_06
  CHECK ls_qals-yqm_art_le NE 'P'.

*check ls_qals-YQM_QPHYSPRNR is INITIAL.
* Darüber kann abgegrenz werden, ob das Prüflos manuell aus dem Kundenauftrag angelegt wird

  CASE lv_event.
    WHEN gc_event_created.

      CALL FUNCTION 'Y_QMLIMS_SERVICE_GET_CONF_VALS'
        EXPORTING
          i_cuobj            = ls_qals-yqm_cuobj
        IMPORTING
          ev_probenehmer03   = lv_pn
          ev_probenahmedatum = lv_pn_datum
          ev_probenahmezeit  = lv_pn_zeit
          ev_temperatur_pn   = lv_pn_temperatur.

      IF NOT lv_pn_temperatur IS INITIAL.

        SELECT * FROM yqm03_pe_qpmk INTO CORRESPONDING FIELDS OF TABLE lt_pr_qpmk_data
          WHERE asnum = ls_qals-matnr
          AND   atnam = 'LAB_TEMPERATUR_PN'.
        IF sy-subrc = 0.
          LOOP AT lt_pr_qpmk_data INTO ls_pr_qpmk_data.
            ls_pr_qpmk_data-messwert = lv_pn_temperatur.
            MODIFY lt_pr_qpmk_data FROM ls_pr_qpmk_data.
          ENDLOOP.
        ENDIF.

        IF NOT lt_pr_qpmk_data[] IS INITIAL.
          CALL FUNCTION 'Y_QMLIMS_SERVICE_RECORD_RESULT'
            EXPORTING
              iv_prueflos  = ls_qals-prueflos
              iv_pn        = lv_pn
              iv_pn_datum  = lv_pn_datum
              iv_pn_zeit   = lv_pn_zeit
            TABLES
              it_qpmk_data = lt_pr_qpmk_data.
        ENDIF.
      ENDIF.

      IF sy-subrc = 0.
        COMMIT WORK.
      ENDIF.

    WHEN OTHERS.
      EXIT.
  ENDCASE.

ENDFUNCTION.
