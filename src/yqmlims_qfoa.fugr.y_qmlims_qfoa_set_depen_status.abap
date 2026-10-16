FUNCTION y_qmlims_qfoa_set_depen_status.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_QALS) LIKE  QALS STRUCTURE  QALS
*"     REFERENCE(I_QAVE) LIKE  QAVE STRUCTURE  QAVE
*"  EXPORTING
*"     VALUE(E_SUBRC) LIKE  SY-SUBRC
*"  TABLES
*"      E_PROTOCOL STRUCTURE  RQEVP OPTIONAL
*"----------------------------------------------------------------------

  DATA: ls_protocol         TYPE rqevp,
        ls_vbap_faksp       TYPE yqm_vbap_faksp_t,
        ls_order_header_inx TYPE bapisdh1x.

  DATA: lt_item   TYPE TABLE OF bapisditm,
        lt_itemx  TYPE TABLE OF bapisditmx,
        ls_return TYPE bapiret2,
        lt_return TYPE TABLE OF bapiret2.

  e_subrc = 0.

* Wenn zum IH Auftrag ein Kundenauftrag existiert wird dort die Fakturasperre gesetzt.
* Bei Verwendung von Servicaufträgen ist das nicht relevant

  " Nichts zu tun, wenn kein Auftrag vorhanden
  IF i_qals-aufnr IS INITIAL.
    RETURN.
  ENDIF.

  " Kundenauftrag / Position zum Service-/Prüflos-Auftrag lesen
  SELECT SINGLE kdauf, kdpos
    FROM aufk
    WHERE aufnr = @i_qals-aufnr
    INTO @DATA(ls_aufk).

  IF sy-subrc <> 0 OR ls_aufk-kdauf IS INITIAL OR ls_aufk-kdpos IS INITIAL.
    " Keine Zuordnung gefunden -> kein Fehler, aber nichts zu tun
    RETURN.
  ENDIF.

  " Auftrag sperren
  CALL FUNCTION 'ENQUEUE_EVVBAKE'
    EXPORTING
      mode_vbak = 'E'
      vbeln     = ls_aufk-kdauf
    EXCEPTIONS
      OTHERS    = 3.

  IF sy-subrc <> 0.
    " Sperre nicht möglich -> protokollieren + in Logtabelle schreiben
    e_subrc = sy-subrc.

    CLEAR ls_vbap_faksp.
    ls_vbap_faksp-vbeln    = ls_aufk-kdauf.
    ls_vbap_faksp-posnr    = ls_aufk-kdpos.
    ls_vbap_faksp-prueflos = i_qals-prueflos.
    ls_vbap_faksp-datum    = sy-datum.
    ls_vbap_faksp-uzeit    = sy-uzeit.
    ls_vbap_faksp-subrc    = e_subrc.

    MODIFY yqm_vbap_faksp_t FROM @ls_vbap_faksp.

    IF sy-subrc = 0.
      CLEAR ls_protocol.
      ls_protocol-prot_zeile = TEXT-001.
      ls_protocol-prot_zeile = TEXT-001.
      MOVE-CORRESPONDING sy TO ls_protocol.
      APPEND ls_protocol TO e_protocol.
    ENDIF.

    RETURN.
  ENDIF.

  " Ab hier: gesperrt -> am Ende zwingend entsperren
  " Fakturasperre in Kundenauftragsposition zurücknehmen
  SELECT SINGLE vbeln, posnr, faksp
    FROM vbap
    WHERE vbeln = @ls_aufk-kdauf
      AND posnr = @ls_aufk-kdpos
    INTO @DATA(ls_vbap).

  IF sy-subrc = 0.

    " Nur updaten, wenn tatsächlich gesetzt (reduziert DB-Last + ATC-Hinweise)
    IF ls_vbap-faksp IS NOT INITIAL.

      APPEND VALUE #( itm_number = ls_vbap-posnr
                      bill_block = space ) TO lt_item.

      APPEND VALUE #( itm_number = ls_vbap-posnr
                      updateflag = 'U'
                      bill_block = 'X' ) TO lt_itemx.

* prepare BAPI call - update order
      CLEAR ls_order_header_inx.
      ls_order_header_inx-updateflag = 'U'.

      CALL FUNCTION 'BAPI_SALESORDER_CHANGE'
        EXPORTING
          salesdocument    = ls_vbap-vbeln
          order_header_inx = ls_order_header_inx
        TABLES
          order_item_in    = lt_item
          order_item_inx   = lt_itemx
          return           = lt_return.

      " ... BAPI_SALESORDER_CHANGE wurde aufgerufen und lt_return gefüllt ...

      " Fehler erkennen: Abbruch/Fehler (ggf. X, je nach Systemkonvention)
      DATA(lv_has_error) = abap_false.

      LOOP AT lt_return INTO ls_return
        WHERE type = 'E'
           OR type = 'A'
           OR type = 'X'.
        lv_has_error = abap_true.
        EXIT.
      ENDLOOP.

      IF lv_has_error = abap_false.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = abap_true.

      ELSE.
        e_subrc = 8.

        "Optional: Rollback, falls vorher schon was im LUW „hängt“
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

        CLEAR ls_protocol.
        ls_protocol-prot_zeile = TEXT-001.
        ls_protocol-prot_zeile = TEXT-001.
        MOVE-CORRESPONDING sy TO ls_protocol.
        APPEND ls_protocol TO e_protocol.

        "Protokoll schreiben: 1..n Zeilen (je Return-Eintrag mit Fehler)
        LOOP AT lt_return INTO ls_return
          WHERE type = 'E'
             OR type = 'A'
             OR type = 'X'.

          CLEAR ls_protocol.
          ls_protocol-prot_zeile = |{ TEXT-001 } { ls_return-message }|.

          " Pflichtfelder / SD-üblich
          ls_protocol-msgty = ls_return-type.
          ls_protocol-msgid = ls_return-id.
          ls_protocol-msgno = ls_return-number.
          ls_protocol-msgv1 = ls_return-message_v1.
          ls_protocol-msgv2 = ls_return-message_v2.
          ls_protocol-msgv3 = ls_return-message_v3.
          ls_protocol-msgv4 = ls_return-message_v4.

          APPEND ls_protocol TO e_protocol.

        ENDLOOP.

      ENDIF.

    ENDIF.
  ENDIF.

  CALL FUNCTION 'DEQUEUE_EVVBAKE'
    EXPORTING
      vbeln = ls_aufk-kdauf.

ENDFUNCTION.
