"&---------------------------------------------------------------------"
"& Include          YQM_KUNDE_EXCEL_ALV
"&---------------------------------------------------------------------"

FORM display_alv.

  DATA: lt_fieldcat TYPE lvc_t_fcat,
        ls_fieldcat TYPE lvc_s_fcat.

  CREATE OBJECT go_alv
    EXPORTING
      i_parent = cl_gui_container=>screen0.

  CASE 'X'.

    WHEN pa_tab1.

      go_alv->set_table_for_first_display(
        EXPORTING
          i_structure_name = 'YQM_K_E'
          is_variant       = gs_variant
          is_layout        = gs_layout
          i_save           = 'U'
        CHANGING
          it_outtab        = gt_it ).

    WHEN pa_tab2.

      CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name       = 'YQM_K_E2'
        CHANGING
          ct_fieldcat            = lt_fieldcat
        EXCEPTIONS
          inconsistent_interface = 1
          program_error          = 2
          OTHERS                 = 3.

      IF sy-subrc <> 0.
        MESSAGE 'Fehler beim Aufbau Feldkatalog' TYPE 'W'.
      ENDIF.

      LOOP AT lt_fieldcat INTO ls_fieldcat.
        CASE ls_fieldcat-fieldname.
          WHEN 'YQM_KUNNRZL'.  ls_fieldcat-coltext = 'Kunde'.
          WHEN 'PRUEFLOS'.     ls_fieldcat-coltext = 'Prüflosnummer'.
          WHEN 'MITTELWERT'.   ls_fieldcat-coltext = 'Prüfergebnis'.
          WHEN 'PARAMID'.      ls_fieldcat-coltext = 'Parameter_ID'.
        ENDCASE.
        MODIFY lt_fieldcat FROM ls_fieldcat.
      ENDLOOP.

      go_alv->set_table_for_first_display(
        EXPORTING
          is_variant      = gs_variant
          is_layout       = gs_layout
        CHANGING
          it_outtab       = gt_it2
          it_fieldcatalog = lt_fieldcat ).

    WHEN pa_tab3.

      go_alv->set_table_for_first_display(
        EXPORTING
          i_structure_name = 'YQM_K_E3'
        CHANGING
          it_outtab        = gt_it3 ).

  ENDCASE.

ENDFORM.
