*----------------------------------------------------------------------*
***INCLUDE ZXQPLO01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  SET_FIRST_SUBSCREEN  OUTPUT
*&---------------------------------------------------------------------*
MODULE set_first_subscreen OUTPUT.

* Erstes Dynpro setzen
  IF gv_dynnr IS INITIAL.
    gv_dynnr = '101'.
  ENDIF.

ENDMODULE.                             " SET_FIRST_SUBSCREEN  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  MODIFY_SCREEN  OUTPUT
*&---------------------------------------------------------------------*
MODULE modify_screen OUTPUT.

  IF sy-tcode = 'QA01' OR             "Prüflos anlegen
     sy-tcode = 'QA02'.               "Prüflos aendern
  ELSE.
    LOOP AT SCREEN.
      IF screen-group1 EQ 'USR'.
        screen-input = '0'.            "keine Eingabe
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDMODULE.                             " MODIFY_SCREEN  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  READ_PRGGSTD  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_prggstd OUTPUT.

  IF NOT gs_qals-yqm_prggstd IS INITIAL.
    SELECT SINGLE prggstd bez FROM yqm_prggstd_t
           INTO yqm_prggstd_t
           WHERE prggstd = gs_qals-yqm_prggstd.
    IF sy-subrc <> 0.
      CLEAR yqm_prggstd_t.
    ENDIF.
  ELSE.
    CLEAR yqm_prggstd_t.
  ENDIF.

ENDMODULE.
