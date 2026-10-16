MODULE user_command_0200 INPUT.

  gv_save_ok_code = gv_ok_code.
  CLEAR gv_ok_code.

  CASE gv_save_ok_code.

    WHEN 'ENT1'.
      " Beurteilung als Langtext zum Verwendungsentscheid wegschreiben
      IF gv_no_editor <> 'X'.
        PERFORM receive_text_from_ocx USING 'X'.
      ENDIF.

      PERFORM free_screen_200_controls.

      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'BEURTEILEN'.
     " Bereits erzeugte Beurteilung lesen
      IF gv_no_editor <> 'X'.
        PERFORM receive_text_from_ocx USING space.
      ENDIF.

      PERFORM beurteilung_generieren.

    WHEN 'ABBR'.
      PERFORM free_screen_200_controls.

      gv_subrc = 4.
      SET SCREEN 0.
      LEAVE SCREEN.

  ENDCASE.

ENDMODULE.
