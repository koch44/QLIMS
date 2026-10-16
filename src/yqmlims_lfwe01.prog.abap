*&---------------------------------------------------------------------*
*& Include          YQ_LFW1E01
*&---------------------------------------------------------------------*

INITIALIZATION.
  so_stat-low = pa_stat.
  DO pa_mal TIMES.
    so_stat-sign       = 'I'.
    so_stat-option     = 'EQ'.
    APPEND so_stat TO so_stat.
    so_stat-low+2(3) = so_stat-low+2(3) + 1.
  ENDDO.
  TRANSLATE pa_line TO UPPER CASE.

START-OF-SELECTION.

  DATA: gv_uname_i TYPE sy-uname,
        gs_t1      TYPE gty_t1,
        gv_subrc   TYPE sy-subrc,
        gv_tabname TYPE char4.

  IMPORT gv_uname_i FROM MEMORY ID 'YQLFW'.

  go_lfw = NEW lcl_lfw( iv_uname_i   = gv_uname_i
                        it_rng_datum = so_datum[]
                        it_rng_los   = so_los[]
                        it_rng_anl   = so_anl[]
                        it_rng_kunnr = so_kunnr[]
                        it_rng_ext   = so_ext[]
                        it_rng_stat  = so_stat[]
                        it_rng_txt   = so_txt[]
                        iv_down      = pa_down
                        iv_ausgabef  = p_ausgbf
                        iv_adr       = pa_adr
                        iv_url       = pa_url
                        iv_low       = pa_low
                        iv_pfad      = pa_pfad
                        it_rng_probe = ql_probe[] ).

* KORR 29.09.2026: Batchlauf ohne quittierte Lose -> LDB nicht lesen
  IF go_lfw->run( ) = abap_false.
    EXIT.
  ENDIF.

GET qals.

  CLEAR: gs_t1, gv_subrc.

  go_lfw->set_qals( qals ).
  gv_subrc = go_lfw->check_qals( ).
  CHECK gv_subrc <> 0.          "0 = Filter nicht erfüllt / Status aktiv

  CLEAR gv_subrc.
  gv_tabname = 'QALS'.
  go_lfw->set_t1( EXPORTING iv_tabname = gv_tabname
                  CHANGING  cs_t1      = gs_t1
                            cv_subrc   = gv_subrc ).
  CHECK gv_subrc = 0.

* KORR 01.10.2026: Techn. Platz / Amt / OKZ direkt je Prüflos ermitteln,
*                  unabhängig von der Lesereihenfolge der LDB (QAVE)
  gv_tabname = 'QAVE'.
  go_lfw->set_t1( EXPORTING iv_tabname = gv_tabname
                  CHANGING  cs_t1      = gs_t1
                            cv_subrc   = gv_subrc ).
  CHECK gv_subrc = 0.

* Protokoll zur Kontrolle (kann nach dem Test entfernt werden)
  WRITE: / 'Prüflos:', gs_t1-prueflos, 'TPLNR:', gs_t1-tplnr,
           'Amt:', gs_t1-yqm_wasserwirt(30), 'OKZ:', gs_t1-yqm_wasserwirtnr.

GET qave.

  go_lfw->set_qave( qave ).

GET qamv.

* KORR 01.10.2026: nur Merkmale des aktuell aufbereiteten Prüfloses
  CHECK gs_t1-prueflos = qamv-prueflos.

  go_lfw->set_qamv( qamv ).
  gv_tabname = 'QAMV'.
  go_lfw->set_t1( EXPORTING iv_tabname = gv_tabname
                  CHANGING  cs_t1      = gs_t1
                            cv_subrc   = gv_subrc ).

GET qasr.

* KORR 01.10.2026: nur Ergebnisse des aktuell aufbereiteten Prüfloses
  CHECK gs_t1-prueflos = qasr-prueflos.

  go_lfw->set_qasr( qasr ).
  gv_tabname = 'QASR'.
  go_lfw->set_t1( EXPORTING iv_tabname = gv_tabname
                  CHANGING  cs_t1      = gs_t1
                            cv_subrc   = gv_subrc ).

  IF gs_t1-yqm_wasserwirtnr IS NOT INITIAL.
    go_lfw->append_t1( gs_t1 ).
  ENDIF.

*GET qals.
*
** KORR 29.09.2026: Arbeitsbereich je Prüflos leeren (alt: CLEAR t1)
*  CLEAR: gs_t1, gv_subrc.
*
*  go_lfw->set_qals( qals ).
*  gv_subrc = go_lfw->check_qals( ).
*  CHECK gv_subrc <> 0.          "0 = Filter nicht erfüllt / Status aktiv
*
*  CLEAR gv_subrc.
*  gv_tabname = 'QALS'.
*  go_lfw->set_t1( EXPORTING iv_tabname = gv_tabname
*                  CHANGING  cs_t1      = gs_t1
*                            cv_subrc   = gv_subrc ).
*  CHECK gv_subrc = 0.
*
*GET qave.
*
** KORR 29.09.2026: Rückgabe der Extensionsprüfung auswerten
*  CLEAR gv_subrc.
*  go_lfw->set_qave( qave ).
*  gv_tabname = 'QAVE'.
*  go_lfw->set_t1( EXPORTING iv_tabname = gv_tabname
*                  CHANGING  cs_t1      = gs_t1
*                            cv_subrc   = gv_subrc ).
*  CHECK gv_subrc = 0.           "überspringt QAMV/QASR wie früher
*
*GET qamv.
*
*  go_lfw->set_qamv( qamv ).
*  gv_tabname = 'QAMV'.
*  go_lfw->set_t1( EXPORTING iv_tabname = gv_tabname
*                  CHANGING  cs_t1      = gs_t1
*                            cv_subrc   = gv_subrc ).
*
*GET qasr.
*
*  go_lfw->set_qasr( qasr ).
*  gv_tabname = 'QASR'.
*  go_lfw->set_t1( EXPORTING iv_tabname = gv_tabname
*                  CHANGING  cs_t1      = gs_t1
*                            cv_subrc   = gv_subrc ).
*
** KORR 29.09.2026: Extension wird bereits in GET qave geprüft
**                  (so_ext hier würde im Batch fälschlich auf WVA filtern)
*  IF gs_t1-yqm_wasserwirtnr IS NOT INITIAL.
*    go_lfw->append_t1( gs_t1 ).
*  ENDIF.

END-OF-SELECTION.

  go_lfw->error2file( ).
  go_lfw->write_prot( ).
