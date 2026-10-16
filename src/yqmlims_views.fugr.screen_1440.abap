PROCESS BEFORE OUTPUT.
  MODULE liste_initialisieren.
  LOOP AT extract WITH CONTROL
   tctrl_yqm_kosten4_t CURSOR nextline.
    MODULE liste_show_liste.
    MODULE read_material_text_1440.
  ENDLOOP.
*
PROCESS AFTER INPUT.
  MODULE liste_exit_command AT EXIT-COMMAND.
  MODULE liste_before_loop.
  LOOP AT extract.
    MODULE liste_init_workarea.
    CHAIN.
      FIELD yqm_kosten4_t-matnr .
      FIELD yqm_kosten4_t-kunnr .
      FIELD yqm_kosten4_t-tplnr .
      FIELD yqm_kosten4_t-lstar .
      FIELD yqm_kosten4_t-aktiv .
      FIELD yqm_kosten4_t-ktext .
      FIELD yqm_kosten4_t-menge .
      FIELD yqm_kosten4_t-meins .
      FIELD yqm_kosten4_t-stumf .
      FIELD yqm_kosten4_t-var_menge_flag .
      FIELD yqm_kosten4_t-alt_lstar .
      MODULE set_update_flag ON CHAIN-REQUEST.
    ENDCHAIN.
    FIELD vim_marked MODULE liste_mark_checkbox.
    CHAIN.
      FIELD yqm_kosten4_t-matnr .
      FIELD yqm_kosten4_t-kunnr .
      FIELD yqm_kosten4_t-tplnr .
      MODULE liste_update_liste.
    ENDCHAIN.
  ENDLOOP.
  MODULE liste_after_loop.
