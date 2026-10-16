*&---------------------------------------------------------------------*
*& Report YQMLIMS_DISPLAY_PB_LOG
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT yqmlims_display_pb_log.

TABLES: yqm_arpblg_t.

*DATA  gs_arpblg TYPE yqm_arpblg_t.
DATA  gt_data   TYPE TABLE OF yqm_arpblg_t.

* Eventhandler
CLASS lcl_handle_events DEFINITION DEFERRED.
DATA  gr_events_handler TYPE REF TO lcl_handle_events.

* ALV Listklasse
DATA  gr_table TYPE REF TO cl_salv_table.

SELECT-OPTIONS s_los    FOR yqm_arpblg_t-prueflos.
SELECT-OPTIONS s_datum  FOR yqm_arpblg_t-erdat.
SELECT-OPTIONS s_uzeit  FOR yqm_arpblg_t-erzeit.

*----------------------------------------------------------------------*
*       CLASS lcl_data_access DEFINITION
*----------------------------------------------------------------------*
CLASS lcl_data_access DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS: select.
ENDCLASS.                    "lcl_data_access DEFINITION

*----------------------------------------------------------------------*
*       CLASS lcl_data_access IMPLEMENTATION
*----------------------------------------------------------------------*
CLASS lcl_data_access IMPLEMENTATION.
  METHOD select.

* Daten einlesen gemäß Selektionen
    SELECT * FROM yqm_arpblg_t
      INTO TABLE gt_data
      WHERE prueflos IN s_los
      AND   erdat    IN s_datum
      AND   erzeit   IN s_uzeit.
    IF sy-subrc <> 0.
      CLEAR gt_data.
    ENDIF.

  ENDMETHOD.                    "select
ENDCLASS.                    "lcl_data_access IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS lcl_handle_events DEFINITION
*----------------------------------------------------------------------*
CLASS lcl_handle_events DEFINITION.
  PUBLIC SECTION.
    METHODS: on_user_command
      FOR EVENT added_function OF cl_salv_events
      IMPORTING e_salv_function.

  PRIVATE SECTION.
    METHODS: handle_user_command
      IMPORTING iv_ucomm TYPE c.
*      open_object.
ENDCLASS.                    "lcl_handle_events DEFINITION

*---------------------------------------------------------------------*
*       CLASS lcl_sorders_handle_events IMPLEMENTATION
*---------------------------------------------------------------------*
CLASS lcl_handle_events IMPLEMENTATION.
  METHOD on_user_command.
    handle_user_command( e_salv_function ).
  ENDMETHOD.                    "on_user_command

  METHOD handle_user_command.
*    CASE p_ucomm.
*      when 'DISP'.
*        open_object( ).
*    ENDCASE.

*   Hinzugefügte Änderungen in Anzeige übernehmen
    gr_table->refresh( ).
  ENDMETHOD.                    "handle_user_command

*  METHOD open_object.
*    DATA lr_selections    TYPE REF TO cl_salv_selections.
*    DATA lv_selected_rows TYPE salv_t_row.

*    DATA lv_row  TYPE i.
*    DATA ls_data LIKE LINE OF gt_data.

*    DATA lv_content TYPE xstring.

*   Ermitteln der selektierten Zeilen
*    lr_selections = gr_table->get_selections( ).
*    lv_selected_rows = lr_selections->get_selected_rows( ).

*   Show XML for selekted objects
*    loop at li_selected_rows into l_row.
*      read table gi_data
*           into lwa_data
*           index l_row.
*      if sy-subrc is initial.
*
*        call function 'DISPLAY_XML_STRING'
*          exporting
*            xml_string      = l_content
*          exceptions
*            no_xml_document = 0.
*
*      endif.
*    endloop.
*  ENDMETHOD.

ENDCLASS.                    "lcl_handle_events IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS main DEFINITION
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
CLASS lcl_main DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS: start.

  PRIVATE SECTION.
    CLASS-METHODS  create_and_start_alv.
ENDCLASS.                    "lcl_main DEFINITION

*----------------------------------------------------------------------*
*       CLASS main IMPLEMENTATION
*----------------------------------------------------------------------*
CLASS lcl_main IMPLEMENTATION.
  METHOD start.
    lcl_data_access=>select( ).
    create_and_start_alv( ).
  ENDMETHOD.                    "start

  METHOD create_and_start_alv.
    DATA lr_dispset    TYPE REF TO cl_salv_display_settings.
    DATA lr_selections TYPE REF TO cl_salv_selections.

    DATA lr_columns    TYPE REF TO cl_salv_columns_table.
    DATA lr_events     TYPE REF TO cl_salv_events_table.

    TRY.
* Erzeuge ALV Listobjekt
        CALL METHOD cl_salv_table=>factory
          IMPORTING
            r_salv_table = gr_table
          CHANGING
            t_table      = gt_data.

* Events registrieren -> hier UserCommand
        lr_events = gr_table->get_event( ).
        CREATE OBJECT gr_events_handler.
        SET HANDLER gr_events_handler->on_user_command FOR lr_events.

* Anwenderstatus setzen
        CALL METHOD gr_table->set_screen_status
          EXPORTING
            report        = sy-cprog
            pfstatus      = 'MAIN'
            set_functions = cl_salv_table=>c_functions_all.

* titlebar information
        SET TITLEBAR 'T01'.

* Layouteinstellungen
        lr_dispset = gr_table->get_display_settings( ).
        lr_dispset->set_striped_pattern( abap_true ).

*       Selektionseinstellungen
        lr_selections = gr_table->get_selections( ).
        lr_selections->set_selection_mode( cl_salv_selections=>single ).

*       Spezielle Spalteneingenschaften
        lr_columns = gr_table->get_columns( ).
        lr_columns->set_key_fixation( abap_true ).
        lr_columns->set_optimize( abap_true ).

*       Ab in die Anzeige
        gr_table->display( ).

      CATCH cx_root.
*       do nothing
        EXIT.
    ENDTRY.
  ENDMETHOD.                    "create_and_start_alv
ENDCLASS.                    "lcl_main IMPLEMENTATION

START-OF-SELECTION.
  lcl_main=>start( ).
