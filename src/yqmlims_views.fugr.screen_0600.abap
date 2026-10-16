PROCESS BEFORE OUTPUT.
  MODULE liste_initialisieren.
  LOOP AT extract WITH CONTROL
   tctrl_yqm_matn_excl_t CURSOR nextline.
    MODULE liste_show_liste.
    MODULE read_material_text.
  ENDLOOP.
*
PROCESS AFTER INPUT.
  MODULE liste_exit_command AT EXIT-COMMAND.
  MODULE liste_before_loop.
  LOOP AT extract.
    MODULE liste_init_workarea.
    CHAIN.
      FIELD yqm_matn_excl_t-matnr .
      FIELD yqm_matn_excl_t-generic .
      FIELD yqm_matn_excl_t-ersteller .
      FIELD yqm_matn_excl_t-erstelldat .
      MODULE set_ersteller_3 ON CHAIN-REQUEST.
      MODULE set_update_flag ON CHAIN-REQUEST.
    ENDCHAIN.
    FIELD vim_marked MODULE liste_mark_checkbox.
    CHAIN.
      FIELD yqm_matn_excl_t-matnr .
      MODULE liste_update_liste.
    ENDCHAIN.
  ENDLOOP.
  MODULE liste_after_loop.
