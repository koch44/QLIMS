PROCESS BEFORE OUTPUT.
  MODULE liste_initialisieren.
  LOOP AT extract WITH CONTROL
   tctrl_yqm_matn_mk_t CURSOR nextline.
    MODULE liste_show_liste.
    MODULE lese_qpmk.
  ENDLOOP.
*
PROCESS AFTER INPUT.
  MODULE liste_exit_command AT EXIT-COMMAND.
  MODULE liste_before_loop.
  LOOP AT extract.
    MODULE liste_init_workarea.
    CHAIN.
      FIELD yqm_matn_mk_t-matnr .
      FIELD yqm_matn_mk_t-zaehler .
      FIELD yqm_matn_mk_t-merkmal .
      FIELD yqm_matn_mk_t-kennzeichen .
      FIELD yqm_matn_mk_t-text .
      FIELD yqm_matn_mk_t-gruppe .
      FIELD yqm_matn_mk_t-regel .
      FIELD yqm_matn_mk_t-text_io .
      FIELD yqm_matn_mk_t-text_nio .
      FIELD yqm_matn_mk_t-stumf .
      MODULE set_update_flag ON CHAIN-REQUEST.
    ENDCHAIN.
    FIELD vim_marked MODULE liste_mark_checkbox.
    CHAIN.
      FIELD yqm_matn_mk_t-matnr .
      FIELD yqm_matn_mk_t-zaehler .
      MODULE liste_update_liste.
    ENDCHAIN.
  ENDLOOP.
  MODULE liste_after_loop.
