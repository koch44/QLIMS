*&---------------------------------------------------------------------*
*&  Include           LYQMLIMS_QFOACL1
*&---------------------------------------------------------------------*

* lokale Klasse für Datentransport
CLASS lcl_dragdropobj DEFINITION.
  PUBLIC SECTION.
    DATA: gs_results   TYPE yqm_results_display,
          gv_index     TYPE i,
          gv_fieldname TYPE text30.
ENDCLASS.                    "lcl_dragdropobj DEFINITION

*---------------------------------------------------------------------*
*       CLASS LCL_APPLICATION DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
* Methoden für Reaktion auf Drag-Drop Ereignisse
* 3 reichen wenn nur eine Richtung erlaubt

CLASS lcl_application DEFINITION.

  PUBLIC SECTION.

    METHODS:
      handle_alv_drag
        FOR EVENT ondrag
        OF cl_gui_alv_grid
        IMPORTING e_row e_column e_dragdropobj,
      handle_edit_drop
        FOR EVENT on_drop
        OF cl_gui_textedit
        IMPORTING index line pos dragdrop_object,
      handle_alv_drop_complete
        FOR EVENT ondropcomplete
        OF cl_gui_alv_grid
        IMPORTING e_row e_column e_dragdropobj.

ENDCLASS.                    "lcl_application DEFINITION

*---------------------------------------------------------------------*
*       CLASS LCL_APPLICATION IMPLEMENTATION
*---------------------------------------------------------------------*
*       Gme 13.1.12 neu gen.                                          *
*---------------------------------------------------------------------*
CLASS lcl_application IMPLEMENTATION.
*-------------------------------------------------------------------
*Drag: Aufnehmen der ALV-Grid Zeile in lokales DragDropObjekt
  METHOD handle_alv_drag.
    DATA: lv_dataobj TYPE REF TO lcl_dragdropobj,
          ls_results TYPE yqm_results_display.

    READ TABLE gt_results INDEX e_row-index INTO ls_results.
*
    CREATE OBJECT lv_dataobj.
    lv_dataobj->gs_results = ls_results.
*
    lv_dataobj->gv_index      = e_row-index.
    lv_dataobj->gv_fieldname  = e_column-fieldname.

    e_dragdropobj->object = lv_dataobj.

  ENDMETHOD.                    "handle_alv_drag
*--------------------------------------------------------------------
* Ereignishandler für Drop: Einfüllen der Zeile in Editor
  METHOD handle_edit_drop.

    TYPES:
      ty_textline TYPE c LENGTH 255,
      ty_texttab  TYPE STANDARD TABLE OF ty_textline
                      WITH DEFAULT KEY.

    DATA:
      lo_dataobj   TYPE REF TO lcl_dragdropobj,
      lv_textline  TYPE ty_textline,
      lv_textline1 TYPE string,
      lv_textline2 TYPE string,
      lv_text      TYPE string,
      lt_texttable TYPE ty_texttab,
      ls_results   TYPE yqm_results_display,

      lv_line      TYPE i,
      lv_offset    TYPE i,
      lv_name      TYPE text30.

    FIELD-SYMBOLS:
      <lv_field> TYPE any.

    TRY.
        lo_dataobj ?= dragdrop_object->object.
      CATCH cx_sy_move_cast_error.
        dragdrop_object->abort( ).
        RETURN.
    ENDTRY.

    CALL METHOD gv_edit->get_text_as_r3table
      IMPORTING
        table                  = lt_texttable
      EXCEPTIONS
        error_dp               = 1
        error_cntl_call_method = 2
        error_dp_create        = 3
        potential_data_loss    = 4
        OTHERS                 = 5.

    cl_gui_cfw=>flush( ).

    IF sy-subrc <> 0 AND sy-subrc <> 4.
      dragdrop_object->abort( ).
      RETURN.
    ENDIF.

    ls_results = lo_dataobj->gs_results.

    lv_name = |LS_RESULTS-{ lo_dataobj->gv_fieldname }|.

    ASSIGN (lv_name) TO <lv_field>.
    IF <lv_field> IS NOT ASSIGNED.
      dragdrop_object->abort( ).
      RETURN.
    ENDIF.

    lv_text = CONV string( <lv_field> ).

    "Nur führende Leerzeichen entfernen, wenn fachlich gewünscht
    SHIFT lv_text LEFT DELETING LEADING space.

    lv_line = line.

    READ TABLE lt_texttable INTO lv_textline INDEX lv_line.

    IF sy-subrc = 0.

      "Die Drop-Position in einen String-Offset umwandeln.
      "Je nach Control-Ereignis kann pos bereits null- oder einsbasiert sein.
      lv_offset = pos - 1.

      IF lv_offset < 0.
        lv_offset = 0.
      ENDIF.

      IF lv_offset > strlen( lv_textline ).
        lv_offset = strlen( lv_textline ).
      ENDIF.

      lv_textline1 = substring(
        val = lv_textline
        off = 0
        len = lv_offset ).

      lv_textline2 = substring(
        val = lv_textline
        off = lv_offset ).

      lv_textline =
          lv_textline1
        && lv_text
        && lv_textline2.

      MODIFY lt_texttable FROM lv_textline INDEX lv_line.

    ELSE.

      "Bei ungültiger Zeile besser anhängen, nicht immer an Position 1 einfügen
      APPEND lv_text TO lt_texttable.

    ENDIF.

    CALL METHOD gv_edit->set_text_as_r3table
      EXPORTING
        table           = lt_texttable
      EXCEPTIONS
        error_dp        = 1
        error_dp_create = 2
        OTHERS          = 3.

    IF sy-subrc <> 0.
      dragdrop_object->abort( ).
      RETURN.
    ENDIF.

    cl_gui_cfw=>flush( ).



  ENDMETHOD.
*-------------------------------------------------------------------
* Ereignishandler wenn Drop komplett hier als Beispiel Löschen der Zeile
* aus ALV-Grid

  METHOD handle_alv_drop_complete.
*    DATA lv_dataobj TYPE REF TO lcl_dragdropobj.
*
*    TRY.
*        lv_dataobj ?= e_dragdropobj->object.
*
*        IF e_dragdropobj->effect = cl_dragdrop=>move.
*          DELETE gt_results INDEX lv_dataobj->gv_index.
*          IF sy-subrc = 0.
*            gv_alv->refresh_table_display( ).
*          ENDIF.
*        ENDIF.
*
*      CATCH cx_sy_move_cast_error.
*        e_dragdropobj->abort( ).
*    ENDTRY.
  ENDMETHOD.


ENDCLASS.                    "lcl_application IMPLEMENTATION
