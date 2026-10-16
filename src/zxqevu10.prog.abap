*----------------------------------------------------------------------*
*   INCLUDE ZXQEVU10                                                   *
*----------------------------------------------------------------------*
* Verwendungsentscheid zurücknehmen

  CHECK i_qals-art  EQ 'YQM_TP'.

  e_exit_active = 'X'.

*-- Verwendungsentscheid zurücknehmen durch Betriebswirtschaftlichen
*   Vorgang QM68.
  CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
    EXPORTING
*     I_DIALOG             = 'X'
      i_objnr              = i_qals-objnr
      i_vorgang            = 'QM68'
    EXCEPTIONS
      not_allowed          = 1
      activity_not_allowed = 2
      OTHERS               = 3.
   IF sy-subrc <> 0.
    message i118(yqmlims) with i_qals-prueflos.
  ENDIF.
