*&---------------------------------------------------------------------*
*& Report YQMLIMS_CREATE_CERTIFICATE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT yqmlims_create_certificate LINE-SIZE 200 MESSAGE-ID yqmlims.
* Erstellung des Prüfberichts
*-----------------------------------------------------------------------
* Christian Fischer 23.01.2024 Komplette Überarbeitung des Druckprogramms
*                              Alte Version gesichert als YQ0100_ALT
* Christian Fischer 10.06.2026 Komplette Überarbeitung des Druckprogramms
*                              bei Übernahme aus PN1 nach S4 Hana
*-----------------------------------------------------------------------
TABLES:
  iflo,                "Technischer Platz View
  qals.                "Prüflossatz Kopf

SELECTION-SCREEN BEGIN OF BLOCK lose WITH FRAME TITLE TEXT-006.
  SELECT-OPTIONS so_los    FOR qals-prueflos.
  SELECT-OPTIONS so_kunnr  FOR qals-kunnr MATCHCODE OBJECT debi.
  SELECT-OPTIONS so_matnr  FOR qals-matnr.
  SELECT-OPTIONS so_tplnr  FOR qals-yqm_tplnr.
  SELECT-OPTIONS so_enstd  FOR qals-enstehdat.
  SELECT-OPTIONS so_pnahm  FOR qals-yqm_probedatum.
SELECTION-SCREEN END OF BLOCK lose.

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE TEXT-009.
  SELECTION-SCREEN BEGIN OF LINE.                           "CF20190228
    PARAMETERS: p_mail AS CHECKBOX.                         "CF20190228
    SELECTION-SCREEN COMMENT 4(75) FOR FIELD p_mail. "TEXT-011. "FOR FIELD p_email.  "CF20190228
  SELECTION-SCREEN END OF LINE.                             "CF20190228
  SELECTION-SCREEN BEGIN OF LINE.                           "GM130917
* wird zur Steuerung DAKKS Logo Ausgabe verwendet            GM130917
    PARAMETERS: p_kzdaks AS CHECKBOX.                       "GM130917
    SELECTION-SCREEN COMMENT 4(45) FOR FIELD p_kzdaks.      "GM130917
  SELECTION-SCREEN END OF LINE.                             "Wo081208

  PARAMETERS: p_email NO-DISPLAY.                           "GM280915
  SELECTION-SCREEN SKIP.

  SELECTION-SCREEN BEGIN OF BLOCK bl3 WITH FRAME TITLE TEXT-012.
    PARAMETERS: p_prev AS CHECKBOX.
    PARAMETERS: p_appr AS CHECKBOX.
    PARAMETERS: p_pdf  AS CHECKBOX USER-COMMAND pdfi.
    PARAMETERS: p_file TYPE char255 LOWER CASE OBLIGATORY
                                               MODIF ID pdf.
  SELECTION-SCREEN END OF BLOCK bl3.
SELECTION-SCREEN END OF BLOCK bl1.

PARAMETERS: p_udcall AS CHECKBOX.
PARAMETERS: p_faxnr TYPE adfax-fax_number NO-DISPLAY.
SELECTION-SCREEN FUNCTION KEY 1.


TYPE-POOLS szadr.

TYPES gty_adfax TYPE STANDARD TABLE OF adfax.

TYPES:
  BEGIN OF gty_itab,
    kunnr      TYPE qals-selkunnr,
    yqm_spezid TYPE yqm_spezid,
    vnlpv      TYPE yqm_vnlpv,
    pndat      TYPE qals-yqm_probedatum,
    tplnr      TYPE tplnr,
    prueflos   TYPE qals-prueflos,
    objnr      TYPE qals-objnr,
    gutachten  TYPE char1,
    ok         TYPE char1,
    seiten     TYPE pagesum,
    kz_oen     TYPE flag,
    kz_apbe    TYPE char1,
  END OF gty_itab,

  BEGIN OF gty_stati,
    estat TYPE tj30-estat,
    stonr TYPE tj30-stonr,
    txt04 TYPE tj30t-txt04,
  END OF gty_stati,

  BEGIN OF gty_arch,
    text      TYPE char10,
    ar_object TYPE arc_params-ar_object,
  END OF gty_arch.

DATA gs_itab TYPE gty_itab.
DATA gt_itab TYPE STANDARD TABLE OF gty_itab.

DATA gt_qals     TYPE STANDARD TABLE OF qals.
DATA gt_qapo     TYPE STANDARD TABLE OF qapo.
DATA gt_qapp     TYPE STANDARD TABLE OF qapp.
DATA gt_qamv_all TYPE STANDARD TABLE OF qamv.
DATA gt_qamr     TYPE STANDARD TABLE OF qamr.
DATA gt_qasr     TYPE STANDARD TABLE OF qasr.
DATA gt_qave     TYPE STANDARD TABLE OF qave.

DATA gs_addr    TYPE szadr_addr1_complete.
DATA gs_addr1   TYPE szadr_addr1_line.
DATA gs_fax     TYPE szadr_adfax_line.
DATA gs_smtp    TYPE szadr_adsmtp_line.
DATA gt_sebam_t TYPE STANDARD TABLE OF yqm_sebam_t.

DATA gs_stati TYPE gty_stati.
DATA gt_stati TYPE STANDARD TABLE OF gty_stati.

DATA gs_itcpo TYPE itcpo.
DATA gs_itcpp TYPE itcpp.

DATA:
  BEGIN OF gs_header,
    kz_ve           TYPE char1,
    kz_gedruckt     TYPE char1,
    kz_lsto         TYPE char1,
    kz_sper         TYPE char1,
    lin             TYPE i,
    estat           TYPE jest-stat,
    anrede          TYPE char50,
    comart          TYPE char3,
    addr            TYPE char40,
    kunnr           TYPE kunnr,
    yqm_spezid      TYPE yqm_spezid,
    sort1           TYPE ad_sort1ul,
    sort2           TYPE ad_sort2ul,
    count_qamv      TYPE p,
    s_status        TYPE bsvx-sttxt,
    u_status        TYPE bsvx-sttxt,
    parnr           TYPE ihpa-parnr,
    weitergel       TYPE addr1_data-name_co,
    file            TYPE string,
    kein_dakks_logo TYPE yqm_kein_dakks_logo,
  END OF gs_header.

DATA gv_druckkz TYPE c.
DATA gs_params  TYPE arc_params.
DATA gs_index   TYPE toa_dara.

DATA gs_arch TYPE gty_arch.
DATA gt_arch TYPE STANDARD TABLE OF gty_arch.

DATA gs_matn_tx_t TYPE yqm_matn_tx_t.
DATA gt_ihpa      TYPE STANDARD TABLE OF ihpa.
DATA gt_ftable    TYPE filetable.
DATA gs_ftable    TYPE filename.
DATA gv_prueflos  TYPE qplos.
DATA gv_rc        TYPE i.

DATA gr_prueflos TYPE RANGE OF qals-prueflos.

CONSTANTS gc_leiter TYPE usr01-bname VALUE 'EIBL'.
CONSTANTS gc_stellv TYPE usr01-bname VALUE 'DREHE'.

CONSTANTS gc_fax     TYPE itcpo-tddest     VALUE 'PRFX'.
CONSTANTS gc_faxland TYPE itcpo-tdteleland VALUE 'DE'.
CONSTANTS gc_email   TYPE itcpo-tddest     VALUE 'EMAI'.

CONSTANTS gc_stsma TYPE tj30-stsma VALUE 'YQM_TP'.

CONSTANTS gc_gedruckt TYPE jest-stat VALUE 'APBE'.
CONSTANTS gc_verwend  TYPE jest-stat VALUE 'VE'.
CONSTANTS gc_kave     TYPE jest-stat VALUE 'KAVE'.
CONSTANTS gc_lsto     TYPE jest-stat VALUE 'LSTO'.
CONSTANTS gc_sper     TYPE jest-stat VALUE 'SPER'.

CONSTANTS gc_sap_object TYPE arc_params-sap_object VALUE 'BUS2045'.
CONSTANTS gc_ar_object  TYPE arc_params-ar_object  VALUE 'ZYRQ_ALL'.
CONSTANTS gc_ar_id      TYPE arc_params-archiv_id  VALUE 'BM'.
CONSTANTS gc_function   TYPE toa_dara-function     VALUE 'CFBC'.

CONSTANTS gc_on  TYPE flag VALUE 'X'.
CONSTANTS gc_off TYPE flag VALUE space.

DATA gv_sch_oen TYPE c.

INITIALIZATION.

  GET PARAMETER ID 'QLS' FIELD gv_prueflos.

  IF sy-subrc = 0 AND gv_prueflos IS NOT INITIAL.
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = gv_prueflos
    ) TO so_los.
  ENDIF.

  GET PARAMETER ID 'GXD' FIELD p_file.

AT SELECTION-SCREEN.

  IF p_pdf = gc_on.
    LOOP AT so_los ASSIGNING FIELD-SYMBOL(<ls_los>).
      IF <ls_los>-high IS NOT INITIAL.
        MESSAGE e701(yqmlims) WITH 'Es sind keine Intervalle beim PDF-Druck zulässig'.
      ENDIF.
    ENDLOOP.
  ENDIF.

  gs_header-lin = lines( so_los ).

  IF p_email = gc_on.
    p_pdf = gc_off.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.

    CASE screen-name.
      WHEN 'P_APPR'.
        IF sy-calld IS INITIAL.
          screen-input = '0'.
          MODIFY SCREEN.
        ENDIF.

      WHEN 'P_UDCALL'.
        IF sy-calld IS INITIAL.
          screen-active = '0'.
          screen-input  = '0'.
          screen-output = '0'.
          MODIFY SCREEN.
        ENDIF.
    ENDCASE.

    IF screen-group1 = 'AKT'.
      screen-input = '0'.
      MODIFY SCREEN.
    ENDIF.

    IF screen-group1 = 'PDF'.
      screen-input = COND #( WHEN p_pdf = gc_on THEN '1' ELSE '0' ).
      MODIFY SCREEN.
    ENDIF.

  ENDLOOP.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  gs_header-file = p_file.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title      = 'Downloadpfad für PDF'
      file_filter       = 'PDF (*.pdf)|*.pdf'
      initial_directory = gs_header-file
    CHANGING
      file_table        = gt_ftable
      rc                = gv_rc
    EXCEPTIONS
      OTHERS            = 4 ).

  IF sy-subrc = 0 AND gv_rc > 0.
    READ TABLE gt_ftable INTO gs_ftable INDEX 1.
    IF sy-subrc = 0.
      p_file = gs_ftable.
    ENDIF.
  ENDIF.

START-OF-SELECTION.

  SET PARAMETER ID 'GXD' FIELD p_file.

  PERFORM init.

  " Hauptmenge der Prüflose lesen
  SELECT *
    FROM qals
    WHERE prueflos       IN @so_los
    AND   kunnr          IN @so_kunnr
    AND   matnr          IN @so_matnr
    AND   yqm_tplnr      IN @so_tplnr
    AND   enstehdat      IN @so_enstd
    AND   yqm_probedatum IN @so_pnahm
    INTO TABLE @DATA(lt_qals_sel).
  IF sy-subrc <> 0.
    CLEAR lt_qals_sel.
  ENDIF.

  LOOP AT lt_qals_sel INTO DATA(ls_qals).

    CLEAR: gs_header,
           gs_itab,
           gt_qave,
           gt_qapo,
           gt_qamv_all,
           gt_qamr,
           gt_qasr,
           gt_qapp.

    " Entspricht GET qals
    gs_header-kz_gedruckt   = gc_on.
    gs_header-kz_ve         = gc_on.
    gs_header-kz_lsto       = gc_on.
    gs_header-kz_sper       = gc_on.

    CLEAR gs_itab-gutachten.
    gs_itab-ok = gc_on.

    CLEAR: gs_header-s_status, gs_header-u_status.

    CALL FUNCTION 'STATUS_TEXT_EDIT'
      EXPORTING
        objnr         = ls_qals-objnr
        flg_user_stat = gc_on
        only_active   = gc_on
        spras         = sy-langu
      IMPORTING
        line          = gs_header-s_status
        user_line     = gs_header-u_status
      EXCEPTIONS
        OTHERS        = 1.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    IF gs_header-s_status CS gc_verwend.

      CALL FUNCTION 'STATUS_CHECK'
        EXPORTING
          objnr             = ls_qals-objnr
          status            = 'I0218'
        EXCEPTIONS
          object_not_found  = 1
          status_not_active = 2
          OTHERS            = 3.
      IF sy-subrc = 0.
        gs_header-kz_ve = gc_off.
      ELSE.
        gs_header-kz_ve = gc_on.
      ENDIF.
    ENDIF.

    IF gs_header-s_status CS gc_lsto.
      gs_header-kz_lsto = gc_off.
    ENDIF.

    IF gs_header-s_status CS gc_sper.
      gs_header-kz_sper = gc_off.
    ENDIF.

    IF gs_header-u_status CS gc_gedruckt.
      gs_header-kz_gedruckt = gc_off.
    ENDIF.

    IF gs_header-u_status CS gc_kave.
      gs_itab-ok = gc_off.
    ENDIF.

    IF ls_qals-prueflos(2) = '94'.
      gs_header-kz_ve   = gc_off.
      gs_header-kz_gedruckt = gc_off.
    ENDIF.

    IF gs_header-kz_lsto = gc_off OR gs_header-kz_sper = gc_off.
      IF gs_header-kz_lsto = gc_off.
        WRITE: / ls_qals-prueflos, ' Status steht auf Storniert.'.
      ENDIF.
      IF gs_header-kz_sper = gc_off.
        WRITE: / ls_qals-prueflos, ' Status steht auf Gesperrt.'.
      ENDIF.
    ELSE.
      IF gs_header-kz_ve = gc_on.
        WRITE: / ls_qals-prueflos, ' Status steht nicht auf Verwendungsentscheid.'.
      ENDIF.
    ENDIF.

    IF p_prev = gc_on OR p_appr = gc_on.
      CLEAR ls_qals-yqm_qpbversion.
    ENDIF.

    IF ( p_prev = gc_on OR p_appr = gc_on ) AND sy-tcode = 'YQM_QA33'.
      CLEAR gs_header-kz_ve.
    ELSE.
      IF NOT ( gs_header-kz_ve      = gc_off
           AND gs_header-kz_lsto = gc_on
           AND gs_header-kz_sper = gc_on ).
        CONTINUE.
      ENDIF.
    ENDIF.

    CALL FUNCTION 'QG01_LOT_READ_WITH_RESULTS'
      EXPORTING
        i_prueflos    = ls_qals-prueflos
      TABLES
        t_qave        = gt_qave
        t_qapo        = gt_qapo
        t_qamv        = gt_qamv_all
        t_qamr        = gt_qamr
        t_qasr        = gt_qasr
        t_qapp        = gt_qapp
      EXCEPTIONS
        lot_not_found = 1
        OTHERS        = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
      CONTINUE.
    ENDIF.

    LOOP AT gt_qamv_all INTO DATA(ls_qamv).
      CLEAR gs_header-count_qamv.
      LOOP AT gt_qamr TRANSPORTING NO FIELDS
           WHERE vorglfnr = ls_qamv-vorglfnr
             AND merknr   = ls_qamv-merknr.
        gs_header-count_qamv = gs_header-count_qamv + 1.
      ENDLOOP.

    ENDLOOP.

    gs_header-lin = lines( gt_qamr ).

    IF gs_header-kz_ve <> gc_off.
      CONTINUE.
    ENDIF.

    IF gs_header-lin <= 0.
      CONTINUE.
    ENDIF.

*    IF ls_qals-matnr IS INITIAL.
* Partner immer aus dem Serviceauftrag lesen, da kein SD Auftrag mehr verwendet wird
    PERFORM lese_ihpa USING ls_qals-aufnr
                      CHANGING gs_header-parnr sy-subrc.
*    ELSE.
*      PERFORM lese_sdauftrag USING ls_qals-kdauf
*                             CHANGING gs_header-parnr
*                                      sy-subrc
*                                      gs_header-adrnr.
*    ENDIF.

    IF sy-subrc = 0.
      ls_qals-kunnr = gs_header-parnr.
    ENDIF.

    gs_itab-kunnr      = ls_qals-kunnr.
    gs_itab-pndat      = ls_qals-yqm_probedatum.
    gs_itab-tplnr      = ls_qals-yqm_tplnr.
    gs_itab-prueflos   = ls_qals-prueflos.
    gs_itab-objnr      = ls_qals-objnr.
    gs_itab-yqm_spezid = ls_qals-yqm_spezid.
    gs_itab-vnlpv      = ls_qals-yqm_vnlpv.

    IF gs_header-kz_gedruckt = gc_off.
      gs_itab-kz_apbe = 'J'.
    ELSE.
      CLEAR gs_itab-kz_apbe.
    ENDIF.

    PERFORM lese_tp USING    ls_qals-yqm_tplnr space
                    CHANGING gv_sch_oen.
    IF gv_sch_oen IS NOT INITIAL.
      gs_itab-kz_oen = 'X'.
    ELSE.
      CLEAR gs_itab-kz_oen.
    ENDIF.

    APPEND gs_itab TO gt_itab.

    APPEND ls_qals TO gt_qals.

  ENDLOOP.

END-OF-SELECTION.

  gs_header-kein_dakks_logo = p_kzdaks.

  IF p_pdf = gc_on.
    IF so_los-high IS NOT INITIAL.
      WRITE: 'Es sind keine Intervalle beim PDF-Druck zulässig!'.
      CLEAR: gs_itab,
             gt_itab.
    ENDIF.
  ENDIF.

  gs_header-lin = lines( gt_itab ).

  IF gs_header-lin = 0.
    SKIP.
    WRITE: / 'Kein Prüflos wird verarbeitet.'.
  ENDIF.

  SORT gt_qapo BY prueflos vorglfnr.
  SORT gt_qapp BY prueflos vorglfnr.

  PERFORM sebam_und_email.

  SORT gt_itab BY kunnr yqm_spezid vnlpv prueflos.

  DATA:
    lv_first_row   TYPE abap_bool VALUE abap_true,
    lv_kunnr_prev  TYPE kunnr,
    lv_spezid_prev TYPE yqm_spezid,
    lv_vnlpv_prev  TYPE yqm_vnlpv.

  CLEAR: gs_header-kunnr,
         gs_header-yqm_spezid,
         gr_prueflos.

  LOOP AT gt_itab INTO gs_itab.

    IF lv_first_row = abap_false
       AND ( gs_itab-kunnr      <> lv_kunnr_prev
          OR gs_itab-yqm_spezid <> lv_spezid_prev
          OR gs_itab-vnlpv      <> lv_vnlpv_prev ).

      IF gs_header-kunnr IS NOT INITIAL
         AND gr_prueflos IS NOT INITIAL.
        PERFORM verarbeiten TABLES gr_prueflos
                            USING  gs_header-kunnr.
      ENDIF.

      CLEAR gr_prueflos.
    ENDIF.

    gs_header-kunnr      = gs_itab-kunnr.
    gs_header-yqm_spezid = gs_itab-yqm_spezid.

    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = gs_itab-prueflos
    ) TO gr_prueflos.

    lv_kunnr_prev  = gs_itab-kunnr.
    lv_spezid_prev = gs_itab-yqm_spezid.
    lv_vnlpv_prev  = gs_itab-vnlpv.
    lv_first_row   = abap_false.

  ENDLOOP.

  IF gs_header-kunnr IS NOT INITIAL
     AND gr_prueflos IS NOT INITIAL.
    PERFORM verarbeiten TABLES gr_prueflos
                        USING  gs_header-kunnr.
  ENDIF.

  PERFORM close_form TABLES   gr_prueflos
                     CHANGING gv_druckkz.

  PERFORM setzen_gedruckt_status.

  IF sy-ucomm = 'SEXI'
  OR sy-ucomm = 'SCAN'.
    EXIT.
  ENDIF.

  IF p_udcall = gc_on.
    COMMIT WORK AND WAIT.
    LEAVE LIST-PROCESSING.
  ENDIF.

  MESSAGE s789(yqmlims).
  SET PF-STATUS space.
*
**&---------------------------------------------------------------------*
**&      Form  VERARBEITEN_LOSE
**&---------------------------------------------------------------------*
FORM verarbeiten_lose   TABLES t_prueflos
                        USING  VALUE(iv_kunnr).

  DATA lv_anzahl   TYPE i.
  DATA lv_exit     TYPE flag.
  DATA lv_dialog   TYPE c VALUE 'X'.
  DATA lv_seiten   TYPE pagesum.
  DATA ls_prueflos LIKE LINE OF gr_prueflos.
  DATA ls_arpbhd   TYPE yqm_arpbhd_t.

  lv_anzahl = lines( t_prueflos ).
  CHECK lv_anzahl > 0.

  CLEAR:
    lv_exit,
    ls_arpbhd,
    gs_header-kz_ve,
    lv_anzahl.

  LOOP AT gt_qals INTO qals WHERE prueflos IN t_prueflos.

    IF gs_header-kein_dakks_logo IS INITIAL.
      p_kzdaks = gs_matn_tx_t-kein_dakks_logo.
    ENDIF.

    PERFORM ausgabe_medium
      USING
        iv_kunnr
        qals-aufnr
        space
      CHANGING
        lv_dialog.

    gs_itcpo-tdsuffix1 = 'Pb'.
    gs_itcpo-tdsuffix2 = qals-prueflos.

    IF sy-slset CS 'ARCHIV'.
      gs_itcpo-tdarmod = '2'.
    ENDIF.

    lv_dialog = COND #(
      WHEN sy-batch = gc_on THEN gc_off
      ELSE gc_on ).

    PERFORM archiv_parameter.

    IF p_prev = gc_on OR p_pdf = gc_on.
      gs_itcpo-tdgetotf = gc_on.
      lv_dialog         = gc_off.
    ENDIF.

    IF p_prev = gc_on.
      gs_itcpo-tddest    = 'LOCL'.
      gs_itcpo-tdpreview = gc_on.
    ENDIF.

    IF p_udcall = gc_on.

      lv_dialog = gc_off.

      SELECT SINGLE *
        FROM yqm_arpbhd_t
        WHERE kunag   = @qals-kunnr
          AND inaktiv = @space
        INTO @ls_arpbhd.

      IF sy-subrc <> 0.
        SELECT SINGLE *
          FROM yqm_arpbhd_t
          WHERE kunag   = @space
            AND inaktiv = @space
          INTO @ls_arpbhd.

        IF sy-subrc <> 0.
          CLEAR ls_arpbhd.
        ENDIF.
      ENDIF.

      IF ls_arpbhd IS INITIAL.
        MESSAGE a117(yqmlims) WITH 'YQM_ARPBHD_T'.
      ENDIF.

      CASE ls_arpbhd-modus.
        WHEN '1'.
          gs_itcpo-tdarmod = '3'.
        WHEN '2'.
          gs_itcpo-tdarmod = '2'.
        WHEN '3'.
          gs_itcpo-tdarmod = '3'.
      ENDCASE.

      IF ls_arpbhd-printer IS NOT INITIAL.
        gs_itcpo-tddest = ls_arpbhd-printer.
      ENDIF.

    ENDIF.

    PERFORM archive_index
      USING
        qals-prueflos
        qals-ktextmat.

    CALL FUNCTION 'Y_QMLIMS_CERT_CREATE'
      EXPORTING
        iv_pdf                = p_pdf
        iv_preview            = p_prev
        iv_udcall             = p_udcall
        iv_approval           = p_appr
        iv_kzdakks            = p_kzdaks
        iv_dialog             = lv_dialog
        iv_prueflos           = qals-prueflos
        iv_filename           = p_file
        is_itcpo              = gs_itcpo
        is_archive_index      = gs_index
        is_archive_parameters = gs_params
        is_qals               = qals
      EXCEPTIONS
        form_error            = 1
        action_cancelled      = 2
        OTHERS                = 3.

    IF sy-subrc <> 0.
      EXPORT ok_code FROM 'CANC' TO MEMORY ID 'YQMLIMS'.
    ELSE.
      EXPORT ok_code FROM space TO MEMORY ID 'YQMLIMS'.
    ENDIF.

    IF sy-tcode = 'YQM_QA33'.

      IF p_udcall = gc_on.

        READ TABLE gt_stati INTO gs_stati
          WITH KEY txt04 = gc_gedruckt
          BINARY SEARCH.

        IF sy-subrc = 0.
          gs_header-estat = gs_stati-estat.
        ENDIF.

        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            objnr               = qals-objnr
            user_status         = gs_header-estat
          EXCEPTIONS
            object_not_found    = 2
            status_inconsistent = 4
            status_not_allowed  = 6.

        IF sy-subrc = 0.
          COMMIT WORK AND WAIT.
        ENDIF.

      ENDIF.

      LEAVE PROGRAM.

    ENDIF.

  ENDLOOP.

  IF lv_exit = gc_on.
    LEAVE PROGRAM.
  ENDIF.

  LOOP AT t_prueflos INTO ls_prueflos.
    READ TABLE gt_itab INTO gs_itab
      WITH KEY prueflos = ls_prueflos-low.

    IF sy-subrc = 0 AND gs_itab-seiten > lv_seiten.
      lv_seiten = gs_itab-seiten.
    ENDIF.
  ENDLOOP.

  LOOP AT t_prueflos INTO ls_prueflos.
    READ TABLE gt_itab INTO gs_itab
      WITH KEY prueflos = ls_prueflos-low.

    IF sy-subrc = 0.
      gs_itab-seiten = lv_seiten.
      MODIFY gt_itab FROM gs_itab INDEX sy-tabix.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  LESE_DEBITOR
*&---------------------------------------------------------------------*
FORM lese_debitor
  USING
    iv_kunnr TYPE kunnr
    iv_kz    TYPE flag
    iv_adrnr TYPE ad_addrnum
  CHANGING
    ct_fax    TYPE gty_adfax
    cv_name1  TYPE char50
    cv_comart TYPE char03
    cv_addr   TYPE char40.

  DATA:
    lv_adrnr TYPE kna1-adrnr,
    ls_adrc  TYPE adrc,
    ls_kna1  TYPE kna1,
    ls_knvk  TYPE knvk.

  CLEAR gs_header-weitergel.

  SELECT SINGLE kunnr,
                adrnr,
                name3
    FROM kna1
    INTO CORRESPONDING FIELDS OF @ls_kna1
    WHERE kunnr = @iv_kunnr.
  IF sy-subrc <> 0.
    CLEAR ls_kna1.
  ENDIF.

  IF iv_adrnr IS INITIAL.
    lv_adrnr = ls_kna1-adrnr.
  ELSE.
    lv_adrnr = iv_adrnr.
  ENDIF.

  SELECT SINGLE addrnumber,
                name_co,
                street,
                house_num1
    FROM adrc
    INTO CORRESPONDING FIELDS OF @ls_adrc
    WHERE addrnumber = @lv_adrnr.

  CHECK sy-subrc = 0.

  CONCATENATE ls_adrc-street ls_adrc-house_num1
         INTO ls_adrc-street
    SEPARATED BY space.

* Ansprechpartner einstellen
  gs_header-weitergel = ls_adrc-name_co.
  CLEAR cv_name1.

  IF iv_kz = gc_on.
    " nicht im SAPScript-Fall; in normaler Druckliste
    " muss sowohl die Default-SMTP-Adresse geliefert werden
    PERFORM lese_adresse_neu USING 'D' iv_kunnr ls_knvk-parnr iv_kz
                             CHANGING ct_fax cv_comart cv_addr.
    ls_knvk-name1 = ls_kna1-name3.
    CLEAR ls_kna1-name3.
  ENDIF.

  IF ls_kna1-name3 IS NOT INITIAL.

    CONCATENATE ls_kna1-name3 ','
           INTO cv_name1.

    PERFORM lese_adresse_neu USING 'D' iv_kunnr ls_knvk-parnr space
                             CHANGING ct_fax cv_comart cv_addr.

  ELSE.

    SELECT SINGLE kunnr,
                  parnr,
                  anred,
                  name1,
                  pavip
      FROM knvk
      INTO CORRESPONDING FIELDS OF @ls_knvk
      WHERE kunnr = @iv_kunnr
        AND pavip = '2'.

    IF sy-subrc = 0.

      CONCATENATE ls_knvk-anred ls_knvk-name1
             INTO cv_name1
        SEPARATED BY space.
      CONCATENATE cv_name1 ','
             INTO cv_name1.

      PERFORM lese_adresse_neu USING 'P' iv_kunnr ls_knvk-parnr iv_kz
                            CHANGING ct_fax cv_comart cv_addr.

    ELSE.

      PERFORM lese_adresse_neu USING 'D' iv_kunnr ls_knvk-parnr space
                            CHANGING ct_fax cv_comart cv_addr.

    ENDIF.
  ENDIF.

  PERFORM anrede USING cv_name1
                 CHANGING cv_name1.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  LESE_ADRESSE
*&---------------------------------------------------------------------*
FORM lese_adresse
  USING
    VALUE(iv_kz)
    VALUE(iv_adrnr)
    VALUE(iv_prsnr)
    VALUE(iv_script)
  CHANGING
    ct_fax TYPE STANDARD TABLE
    VALUE(cv_comart)
    VALUE(cv_addr).

  DATA lv_addr3_sel  TYPE addr3_sel.
  DATA lv_addr3_val  TYPE addr3_val.
  DATA lv_table_type TYPE szad_field-table_type.

  DATA ls_fax  TYPE adfax.
  DATA lt_fax  TYPE STANDARD TABLE OF adfax.
  DATA ls_smtp TYPE adsmtp.
  DATA lt_smtp TYPE STANDARD TABLE OF adsmtp.

  CHECK iv_adrnr IS NOT INITIAL.
  CHECK iv_adrnr <> '0000000000'.

  CLEAR:
    cv_comart,
    cv_addr.

  CASE iv_kz.

    WHEN 'D' OR 'T'.

      CLEAR:
        gs_header-anrede,
        gs_header-weitergel,
        gs_header-sort1,
        gs_header-sort2.

      CALL FUNCTION 'ADDR_GET_COMPLETE'
        EXPORTING
          addrnumber     = iv_adrnr
        IMPORTING
          addr1_complete = gs_addr
        EXCEPTIONS
          OTHERS         = 1.

      IF sy-subrc = 0.

        LOOP AT gs_addr-addr1_tab INTO gs_addr1.
          cv_comart           = gs_addr1-data-deflt_comm.
          gs_header-sort1     = gs_addr1-data-sort1.
          gs_header-sort2     = gs_addr1-data-sort2.
          gs_header-weitergel = gs_addr1-data-name_co.

          IF iv_kz = 'T' AND gs_addr1-data-name3 IS NOT INITIAL.
            gs_header-anrede = |{ gs_addr1-data-name3 },|.
          ENDIF.

          EXIT.
        ENDLOOP.

      ENDIF.

      IF iv_script = gc_on.
        cv_comart = 'INT'.
      ENDIF.

      CASE cv_comart.
        WHEN 'FAX'.
          LOOP AT gs_addr-adfax_tab INTO gs_fax
            WHERE adfax-flgdefault = gc_on.
            cv_addr = gs_fax-adfax-faxnr_call.
          ENDLOOP.

        WHEN 'INT'.
          LOOP AT gs_addr-adsmtp_tab INTO gs_smtp
            WHERE adsmtp-flgdefault = gc_on.
            cv_addr = gs_smtp-adsmtp-smtp_addr.
          ENDLOOP.
      ENDCASE.

      IF cv_comart = space.
        cv_comart = 'PRT'.
      ENDIF.

      LOOP AT gs_addr-adfax_tab INTO gs_fax.
        COLLECT gs_fax-adfax INTO ct_fax.
      ENDLOOP.

    WHEN 'P' OR 'U'.

      CHECK iv_prsnr IS NOT INITIAL.

      lv_addr3_sel-persnumber = iv_prsnr.
      lv_addr3_sel-addrnumber = iv_adrnr.

      CALL FUNCTION 'ADDR_PERS_COMP_GET'
        EXPORTING
          address_pers_in_comp_selection = lv_addr3_sel
        IMPORTING
          address_pers_in_comp_value     = lv_addr3_val
        EXCEPTIONS
          OTHERS                         = 1.

      CHECK sy-subrc = 0.

      cv_comart = lv_addr3_val-deflt_comm.

      IF cv_comart = 'INT' OR iv_kz = 'U'.
        lv_table_type = 'ADSMTP'.
      ELSE.
        lv_table_type = |AD{ cv_comart }|.
      ENDIF.

      IF lv_table_type = 'ADFAX' OR iv_script = gc_on.

        CALL FUNCTION 'ADDR_PERS_COMP_COMM_GET'
          EXPORTING
            address_number    = iv_adrnr
            language          = sy-langu
            person_number     = iv_prsnr
            table_type        = lv_table_type
          TABLES
            comm_table        = lt_fax
          EXCEPTIONS
            parameter_error   = 1
            address_not_exist = 2
            person_not_exist  = 3
            internal_error    = 4
            OTHERS            = 5.

        IF sy-subrc = 0.
          LOOP AT lt_fax INTO ls_fax WHERE flgdefault = gc_on.
            cv_addr = ls_fax-faxnr_call.
          ENDLOOP.

          LOOP AT gs_addr-adfax_tab INTO gs_fax.
            APPEND gs_fax-adfax TO ct_fax.
          ENDLOOP.
        ENDIF.

      ENDIF.

      IF lv_table_type = 'ADSMTP' OR iv_script = gc_on.

        CALL FUNCTION 'ADDR_PERS_COMP_COMM_GET'
          EXPORTING
            address_number    = iv_adrnr
            language          = sy-langu
            person_number     = iv_prsnr
            table_type        = lv_table_type
          TABLES
            comm_table        = lt_smtp
          EXCEPTIONS
            parameter_error   = 1
            address_not_exist = 2
            person_not_exist  = 3
            internal_error    = 4
            OTHERS            = 5.

        IF sy-subrc = 0.
          LOOP AT lt_smtp INTO ls_smtp WHERE flgdefault = gc_on.
            cv_addr = ls_smtp-smtp_addr.
          ENDLOOP.
        ENDIF.

      ENDIF.

  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  LESE_TP
*&---------------------------------------------------------------------*
FORM lese_tp
  USING
    VALUE(iv_tplnr)
    VALUE(iv_kz)
  CHANGING
    VALUE(cv_oen).

  DATA lt_fax   TYPE STANDARD TABLE OF adfax.
*  DATA lv_pltxt TYPE iflo-pltxt.

  CALL FUNCTION 'FUNC_LOCATION_READ'
    EXPORTING
      tplnr   = iv_tplnr
    IMPORTING
      iflo_wa = iflo
    EXCEPTIONS
      OTHERS  = 4.

  IF sy-subrc <> 0.
    WRITE: / 'Fehler beim Lesen Technischer Platz',
             iv_tplnr,
             qals-prueflos.
    RETURN.
  ENDIF.

  CLEAR cv_oen.

  IF iflo-yqm_vaboen IS NOT INITIAL.
    cv_oen = gc_on.
  ENDIF.

*  lv_pltxt = to_upper( iflo-pltxt ).

  PERFORM lese_adresse
    USING
      'T'
      iflo-adrnr
      space
      iv_kz
    CHANGING
      lt_fax
      gs_header-comart
      gs_header-addr.

  IF iflo-adrnr IS NOT INITIAL.
    CLEAR gs_header-anrede.

    PERFORM anrede
      USING
        gs_header-anrede
      CHANGING
        gs_header-anrede.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SETZEN_GEDRUCKT_STATUS
*&---------------------------------------------------------------------*
FORM setzen_gedruckt_status.
* bestimmen internen Namen des Anwenderstatus des Status ABPE
  LOOP AT gt_stati
    INTO gs_stati
    WHERE txt04 = gc_gedruckt.
    gs_header-estat = gs_stati-estat.
    EXIT.
  ENDLOOP.

* setzen Gedruckt-Kennzeichen
  LOOP AT gt_itab INTO gs_itab.
    CALL FUNCTION 'STATUS_CHANGE_EXTERN'
      EXPORTING
        objnr               = gs_itab-objnr
        user_status         = gs_header-estat
      EXCEPTIONS
        object_not_found    = 2
        status_inconsistent = 4
        status_not_allowed  = 6.
    CASE sy-subrc.
      WHEN 2.
        WRITE: / 'Objekt', gs_itab-objnr, 'nicht vorhanden'.
      WHEN 4.
        WRITE: / gs_itab-objnr, 'Status inkonsistent'.
      WHEN 6.
        WRITE: / gs_itab-objnr, 'Status', gs_header-estat, 'nicht erlaubt'.
    ENDCASE.
  ENDLOOP.
                                                            "Wo260701
ENDFORM.                    " SETZEN_GEDRUCKT_STATUS
*&---------------------------------------------------------------------*
*&      Form  ARCHIV_PARAMETER
*&---------------------------------------------------------------------*
FORM archiv_parameter.                                      "Wo201200

  CLEAR gs_params.

  gs_params-sap_object = gc_sap_object.
  gs_params-ar_object  = gc_ar_object.
  gs_params-mandant    = sy-mandt.
  gs_params-archiv_id  = gc_ar_id.                          "CF221018

ENDFORM.                    " ARCHIV_PARAMETER             "Wo201200
*&---------------------------------------------------------------------*
*&      Form  ARCHIVE_INDEX
*&---------------------------------------------------------------------*
FORM archive_index
  USING
    VALUE(iv_prueflos)
    VALUE(iv_ktext).

  DATA lv_kz TYPE flag.
  DATA ls_params TYPE arc_params.

  CLEAR:
    gs_index,
    lv_kz,
    ls_params.

  gs_index-function   = gc_function.
  gs_index-sap_object = gs_params-sap_object.
  gs_index-ar_object  = gs_params-ar_object.

  TRANSLATE iv_ktext TO UPPER CASE.

  LOOP AT gt_arch INTO gs_arch.

    CHECK gs_arch-text CS iv_ktext.

    IF gs_index-ar_object <> gs_arch-ar_object.
      lv_kz = gc_on.
    ENDIF.

    gs_index-ar_object = gs_arch-ar_object.
    EXIT.

  ENDLOOP.

  gs_index-object_id  = iv_prueflos.
  gs_index-formarchiv = gs_params-archiv_id.

  IF lv_kz = gc_on.

    CALL FUNCTION 'GET_ARCHIVE_PARAMETERS'
      EXPORTING
        ar_object              = gs_index-ar_object
        no_dialog              = gc_on
        printer                = gs_params-printer
        sap_object             = gs_params-sap_object
      IMPORTING
        out_parameters         = ls_params
      EXCEPTIONS
        archive_info_not_found = 1
        not_valid              = 2
        OTHERS                 = 3.

    IF sy-subrc <> 0.
      MESSAGE i019(pt)
        WITH gs_index-ar_object
             gs_params-sap_object.
      RETURN.
    ENDIF.

  ENDIF.

  IF gs_index-formarchiv <> ls_params-archiv_id
     AND ls_params-archiv_id IS NOT INITIAL.

    gs_index-formarchiv = ls_params-archiv_id.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ANREDE
*&---------------------------------------------------------------------*
FORM anrede USING VALUE(iv_name1)
         CHANGING VALUE(cv_name1).

  DATA: lv_i TYPE p.

  lv_i = strlen( iv_name1 ).
  IF lv_i = 0.
    cv_name1 = TEXT-302.    "neutral sehr geehrte Damen und Herren
  ELSE.
    cv_name1 = iv_name1.
    TRANSLATE cv_name1 TO UPPER CASE.
    IF iv_name1 CS 'FRAU'.   "ergibt Sehr geehrte
      CONCATENATE TEXT-300 iv_name1 INTO cv_name1 SEPARATED BY space.
    ELSE.                  "ergibt Sehr geehrter
      CONCATENATE TEXT-301 iv_name1 INTO cv_name1 SEPARATED BY space.
    ENDIF.
  ENDIF.
  SHIFT cv_name1 LEFT DELETING LEADING space.
ENDFORM.                    " ANREDE
*&---------------------------------------------------------------------*
*&      Form  INIT
*&---------------------------------------------------------------------*
FORM init.

  CLEAR: gs_header.

  SELECT estat stonr FROM tj30 INTO TABLE gt_stati
    WHERE stsma = gc_stsma.
  IF sy-subrc = 0.
    SORT gt_stati BY txt04.
  ELSE.
    CLEAR gt_stati.
  ENDIF.
  LOOP AT gt_stati INTO gs_stati.
    SELECT SINGLE txt04 INTO gs_stati-txt04
      FROM tj30t WHERE stsma = gc_stsma
                   AND estat = gs_stati-estat
                   AND spras = sy-langu.
    IF sy-subrc <> 0.
      gs_stati-txt04 = gs_stati-estat.
    ENDIF.
    MODIFY gt_stati FROM gs_stati.
  ENDLOOP.

  gs_arch-text      = 'EWAG  -FW'.    APPEND gs_arch TO gt_arch.
  gs_arch-text      = 'EWAG  -WA'.    APPEND gs_arch TO gt_arch.
  gs_arch-text      = 'EWAG  -HKW'.   APPEND gs_arch TO gt_arch.
  gs_arch-text      = 'EWAG  -WV'.    APPEND gs_arch TO gt_arch.
  gs_arch-text      = 'EWAG  -GA'.    APPEND gs_arch TO gt_arch.

ENDFORM.                    " INIT
*&---------------------------------------------------------------------*
*&      Form  ausgabe_medium
*&---------------------------------------------------------------------*
FORM ausgabe_medium
  USING
    VALUE(iv_kunnr)
    VALUE(iv_aufnr)
    VALUE(iv_kz)
  CHANGING
    VALUE(cv_dialog).

  DATA lv_kunnr TYPE kunnr.
  DATA lv_parnr TYPE ihpa-parnr.
  DATA lv_adrnr TYPE kna1-adrnr.
  DATA lt_fax   TYPE STANDARD TABLE OF adfax.

  PERFORM lese_ihpa
    USING
      iv_aufnr
    CHANGING
      lv_parnr
      sy-subrc.

  IF sy-subrc <> 0.
    lv_parnr = iv_kunnr.
  ENDIF.

  lv_kunnr = lv_parnr.

  PERFORM lese_debitor
    USING
      lv_kunnr
      iv_kz
      lv_adrnr
    CHANGING
      lt_fax
      gs_header-anrede
      gs_header-comart
      gs_header-addr.

  IF p_faxnr IS NOT INITIAL.
    gs_header-comart = 'FAX'.
    gs_header-addr   = p_faxnr.
  ENDIF.

  IF p_email = gc_on.

    CASE gs_header-comart.

      WHEN 'PRT'.
        RETURN.

      WHEN 'FAX'.
        cv_dialog          = gc_off.
        gs_itcpo-tddest    = gc_fax.
        gs_itcpo-tdteleland = gc_faxland.
        gs_itcpo-tdtelenum  = gs_header-addr.

        SELECT SINGLE name
          FROM tsp03d
          WHERE name = @gc_fax
          INTO @gs_itcpo-tddest.

        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

      WHEN 'INT'.
        cv_dialog       = gc_off.
        gs_itcpo-tddest = gc_email.
        RETURN.

    ENDCASE.

    gs_itcpo-tdnoprev = gc_on.
    gs_itcpo-tdimmed  = gc_on.

  ELSE.

    gs_header-comart = 'PRT'.

    IF gs_itcpp-tddest IS NOT INITIAL.
      gs_itcpo-tddest = gs_itcpp-tddest.
    ENDIF.

    gs_itcpo-tdimmed = gc_on.

    IF sy-slset NS 'ARCHIV'.
      gs_itcpo-tdarmod = '3'.
    ENDIF.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  lese_ihpa
*&---------------------------------------------------------------------*
FORM lese_ihpa
  USING    VALUE(iv_aufnr)
  CHANGING VALUE(cv_parnr)
           VALUE(cv_rc).

  DATA:
    lv_objnr TYPE aufk-objnr,
    ls_ihpa  TYPE ihpa.

  CLEAR: cv_rc,
         cv_parnr.

  lv_objnr = |OR{ iv_aufnr }|.

  " Instandhaltungspartner
  READ TABLE gt_ihpa INTO ls_ihpa
       WITH KEY objnr = lv_objnr
                parvw = 'ZL'.
  IF sy-subrc <> 0.

    " Partner aus Instandhaltungspartner-Tabelle ermitteln
    SELECT SINGLE objnr,
                  parvw,
                  parnr
      FROM ihpa
      INTO CORRESPONDING FIELDS OF @ls_ihpa
      WHERE objnr = @lv_objnr
        AND parvw = 'ZL'.

    IF sy-subrc = 0.
      APPEND ls_ihpa TO gt_ihpa.
    ENDIF.
  ENDIF.

  cv_rc = sy-subrc.

  IF sy-subrc = 0.
    cv_parnr = ls_ihpa-parnr.
  ENDIF.

ENDFORM.                    " lese_ihpa
*&---------------------------------------------------------------------*
*&      Form  verarbeiten
*&---------------------------------------------------------------------*
FORM verarbeiten
  TABLES
    t_prueflos
  USING
    VALUE(iv_kunnr).

  PERFORM verarbeiten_lose
    TABLES
      t_prueflos
    USING
      iv_kunnr.

  IF gv_druckkz = gc_on.
    PERFORM close_form
      TABLES
        t_prueflos
      CHANGING
        gv_druckkz.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  close_form
*&---------------------------------------------------------------------*
FORM close_form
  TABLES
    t_prueflos
  CHANGING
    VALUE(cv_druckkz).

  DATA lt_otfdata TYPE STANDARD TABLE OF itcoo.

  CHECK cv_druckkz = gc_on.

  CALL FUNCTION 'CLOSE_FORM'
    IMPORTING
      result                   = gs_itcpp
    TABLES
      otfdata                  = lt_otfdata
    EXCEPTIONS
      unopened                 = 1
      bad_pageformat_for_print = 2
      send_error               = 3
      spool_error              = 4
      codepage                 = 5
      OTHERS                   = 6.

  IF sy-subrc = 0
     AND ( p_prev = gc_on OR p_pdf = gc_on ).

    PERFORM otf_to_pdf
      TABLES
        t_prueflos
        lt_otfdata.

  ENDIF.

  cv_druckkz = gc_off.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SEBAM_UND_EMAIL
*&---------------------------------------------------------------------*
FORM sebam_und_email .

  DATA: lv_anlass  TYPE qals-yqm_anlass,
        lv_kunnr   TYPE qals-kunnr,
        lv_kzamt   TYPE yqm_anlass_t-kzamt,
        lv_kzsebam TYPE yqm_kzsebam,
        lv_betreff TYPE text50,
        lv_wa      TYPE solisti1,
        lt_empf    TYPE STANDARD TABLE OF solisti1,
        lt_body    TYPE STANDARD TABLE OF solisti1,
        ls_sebam   TYPE yqm_sebam_t,
        lv_tplnr   TYPE tplnr,
        ls_itab    TYPE gty_itab,
        lt_itab    TYPE TABLE OF gty_itab,
        lv_senddat TYPE yqm_sebam_t-senddat.
*
  lt_itab = gt_itab.
  SORT lt_itab BY prueflos.

* SEBAM Tabelle befüllen
  LOOP AT lt_itab INTO ls_itab.
*    CHECK p_nachdr = gc_off.
    CHECK p_prev = gc_off.
    SELECT SINGLE matnr yqm_anlass kunnr ktextmat yqm_tplnr yqm_probedatum INTO
      (ls_sebam-matnr, lv_anlass, lv_kunnr, ls_sebam-ktextmat, lv_tplnr, ls_sebam-probedatum)
      FROM qals
      WHERE prueflos = ls_itab-prueflos.
    IF sy-subrc = 0.
      SELECT SINGLE kzamt INTO lv_kzamt FROM yqm_anlass_t
        WHERE anlass = lv_anlass.
      IF sy-subrc = 0 AND lv_kzamt = gc_on.
        SELECT SINGLE kzsebam INTO lv_kzsebam FROM yqm_pfad_t
          WHERE kunnr = lv_kunnr
            AND kzsebam = gc_on.
        IF sy-subrc = 0.

*         dann füllen
          ls_sebam-anlass    = lv_anlass.
          ls_sebam-kunnrzl   = lv_kunnr.
          ls_sebam-prueflos  = ls_itab-prueflos.
          ls_sebam-erdat     = sy-datum.

* GM230514 zusätzlich noch Inhalte aus IFLO füllen
          IF lv_tplnr IS INITIAL.
            WRITE: / 'Fehler zum Lesen Technischer Platz, ist im Prüflossatz QALS noch nicht bekannt:', lv_tplnr.
          ELSE.
            CALL FUNCTION 'FUNC_LOCATION_READ'
              EXPORTING
                tplnr   = lv_tplnr
              IMPORTING
                iflo_wa = iflo
              EXCEPTIONS
                OTHERS  = 4.
            IF sy-subrc > 0.
              WRITE: / 'Fehler beim Lesen Technischer Platz zum Prüflossatz', lv_tplnr, gs_itab-prueflos.
            ELSE.
              ls_sebam-tplnr        = lv_tplnr.
              ls_sebam-bestellnr    = iflo-yqm_bestellnr.
              ls_sebam-wasserwirtnr = iflo-yqm_wasserwirtnr.
            ENDIF.
          ENDIF.
          APPEND ls_sebam TO gt_sebam_t.
        ENDIF.
      ENDIF.
    ENDIF.

*   Füllen Body
    lv_wa = ls_itab-prueflos.
    APPEND lv_wa TO lt_body.
  ENDLOOP.
* sende EMAIL an Burkard und Dreher
  DATA: lv_temp TYPE char8.
* Aufbau Betreff
  IF lines( lt_body ) > 0.
    WRITE sy-datum TO lv_temp.
    CONCATENATE 'Prüfberichtsdruck vom' lv_temp
      INTO lv_betreff SEPARATED BY space.
*   Aufbau Empfänger
    lv_wa = gc_leiter. APPEND lv_wa TO lt_empf.
    lv_wa = gc_stellv. APPEND lv_wa TO lt_empf.
*   absenden EMail

    CALL FUNCTION 'YIHS_MAIL'
      EXPORTING
        iv_betreff   = lv_betreff
      TABLES
        t_empfaenger = lt_empf
        t_mail_body  = lt_body.
*   masseninsert in SEBAM-Tabelle
    INSERT yqm_sebam_t FROM TABLE gt_sebam_t
      ACCEPTING DUPLICATE KEYS.
*    Fehlermeldungen bewusst nicht abfangen
*    IF sy-subrc <> 0.
*      MESSAGE e819(yqmlims) WITH 'YQM_SEBAM_T'.
*    ENDIF.
    lv_senddat = sy-datlo - 14.

* Lösche automatisch alle Einträge, die bereits vor
* mehr als 14 Tagen versendet wurden
    DELETE FROM yqm_sebam_t
      WHERE senddat NE '00000000'
      AND   senddat LT lv_senddat
      AND   quitkz  = 'X'.
*    Fehlermeldungen bewusst nicht abfangen
*    IF sy-subrc <> 0.
*      MESSAGE s830(yqmlims) WITH 'YQM_SEBAM_T'.
*    ENDIF.
  ENDIF.
ENDFORM.                    " SEBAM_UND_EMAIL                 "Wo081208
*&---------------------------------------------------------------------*
*&      Form  LESE_ADRESSE_NEU
*&---------------------------------------------------------------------*
FORM lese_adresse_neu
  USING
    VALUE(iv_kz)
    VALUE(iv_kunnr)
    VALUE(iv_prsnr)
    VALUE(iv_script)
  CHANGING
    ct_fax TYPE STANDARD TABLE
    VALUE(cv_comart)
    VALUE(cv_addr).

  DATA lv_objid     TYPE bapi4001_1-objkey.
  DATA lv_objid_p   TYPE bapi4003_1-objkey_p.
  DATA lv_adrnr     TYPE bapi4001_1-addr_no.
  DATA lv_deflt_com TYPE adrc-deflt_comm.

  DATA lt_1vl    TYPE STANDARD TABLE OF bapiad1vl.
  DATA ls_1vl    TYPE bapiad1vl.
  DATA lt_3vl    TYPE STANDARD TABLE OF bapiad3vl.
  DATA lt_tel    TYPE STANDARD TABLE OF bapiadtel.
  DATA lt_fax    TYPE STANDARD TABLE OF bapiadfax.
  DATA ls_fax    TYPE bapiadfax.
  DATA ls_fax1   TYPE adfax.
  DATA lt_smtp   TYPE STANDARD TABLE OF bapiadsmtp.
  DATA ls_smtp   TYPE bapiadsmtp.
  DATA lt_rem    TYPE STANDARD TABLE OF bapiad_rem.
  DATA lt_com    TYPE STANDARD TABLE OF bapicomrem.
  DATA lt_use    TYPE STANDARD TABLE OF bapiaduse.
  DATA lt_return TYPE STANDARD TABLE OF bapiret2.

  CLEAR:
    cv_comart,
    cv_addr.

  lv_objid   = iv_kunnr.
  lv_objid_p = iv_prsnr.

  IF iv_kz = space.

    CALL FUNCTION 'BAPI_ADDRESSORG_GETDETAIL'
      EXPORTING
        obj_type             = 'KNA1'
        obj_id               = lv_objid
        context              = '0001'
        iv_current_comm_data = gc_on
      IMPORTING
        address_number       = lv_adrnr
      TABLES
        bapiad1vl            = lt_1vl
        bapiadtel            = lt_tel
        bapiadfax            = lt_fax
        bapiadsmtp           = lt_smtp
        bapiad_rem           = lt_rem
        bapicomrem           = lt_com
        bapiaduse            = lt_use
        return               = lt_return.

    SELECT SINGLE deflt_comm
      FROM adrc
      WHERE addrnumber = @lv_adrnr
      INTO @lv_deflt_com.

    IF sy-subrc = 0.
      cv_comart = lv_deflt_com.
    ENDIF.

    LOOP AT lt_1vl INTO ls_1vl.
      gs_header-sort1     = ls_1vl-sort1.
      gs_header-sort2     = ls_1vl-sort2.
      gs_header-weitergel = ls_1vl-c_o_name.

      IF iv_kz = 'T' AND ls_1vl-name_3 IS NOT INITIAL.
        gs_header-anrede = |{ ls_1vl-name_3 },|.
      ENDIF.

      EXIT.
    ENDLOOP.

    IF iv_script = gc_on.
      cv_comart = 'INT'.
    ENDIF.

    CASE cv_comart.
      WHEN 'FAX'.
        LOOP AT lt_fax INTO ls_fax WHERE std_no = gc_on.
          cv_addr = ls_fax-fax_no.
        ENDLOOP.

      WHEN 'INT'.
        LOOP AT lt_smtp INTO ls_smtp WHERE std_no = gc_on.
          cv_addr = ls_smtp-e_mail.
        ENDLOOP.
    ENDCASE.

    IF cv_comart = space.
      cv_comart = 'PRT'.
    ENDIF.

    LOOP AT lt_fax INTO ls_fax.
      CLEAR ls_fax1.
      MOVE-CORRESPONDING ls_fax TO ls_fax1.
      COLLECT ls_fax1 INTO ct_fax.
    ENDLOOP.

  ELSE.

    IF lv_objid_p = 0.

      CALL FUNCTION 'BAPI_ADDRESSORG_GETDETAIL'
        EXPORTING
          obj_type             = 'KNA1'
          obj_id               = lv_objid
          context              = '0001'
          iv_current_comm_data = gc_on
        IMPORTING
          address_number       = lv_adrnr
        TABLES
          bapiad1vl            = lt_1vl
          bapiadtel            = lt_tel
          bapiadfax            = lt_fax
          bapiadsmtp           = lt_smtp
          bapiad_rem           = lt_rem
          bapicomrem           = lt_com
          bapiaduse            = lt_use
          return               = lt_return.

    ELSE.

      CALL FUNCTION 'BAPI_ADDRESSCONTPART_GETDETAIL'
        EXPORTING
          obj_type_p           = 'BUS1006001'
          obj_id_p             = lv_objid_p
          obj_type_c           = 'KNA1'
          obj_id_c             = lv_objid
          context              = '0005'
          iv_current_comm_data = gc_on
        IMPORTING
          address_number       = lv_adrnr
        TABLES
          bapiad3vl            = lt_3vl
          bapiadtel            = lt_tel
          bapiadfax            = lt_fax
          bapiadsmtp           = lt_smtp
          bapicomrem           = lt_com
          bapiaduse            = lt_use
          return               = lt_return.

    ENDIF.

    SELECT SINGLE deflt_comm
      FROM adrc
      WHERE addrnumber = @lv_adrnr
      INTO @lv_deflt_com.

    IF sy-subrc = 0.
      cv_comart = lv_deflt_com.
    ENDIF.

    CASE cv_comart.
      WHEN 'FAX'.

        LOOP AT lt_fax INTO ls_fax WHERE std_no = gc_on.
          cv_addr = ls_fax-fax_no.
        ENDLOOP.

        LOOP AT lt_fax INTO ls_fax.
          CLEAR ls_fax1.
          MOVE-CORRESPONDING ls_fax TO ls_fax1.
          ls_fax1-fax_number = ls_fax-fax.
          ls_fax1-fax_extens = ls_fax-extension.
          ls_fax1-faxnr_call = ls_fax-fax_no.
          COLLECT ls_fax1 INTO ct_fax.
        ENDLOOP.

      WHEN 'INT'.

        LOOP AT lt_smtp INTO ls_smtp WHERE std_no = gc_on.
          cv_addr = ls_smtp-e_mail.
        ENDLOOP.

    ENDCASE.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  OTF_TO_PDF
*&---------------------------------------------------------------------*
FORM otf_to_pdf TABLES t_prueflos
                       t_otf.

  DATA:
    lv_filesize   TYPE i,
    lv_binlines   TYPE i,
    lv_binwidth   TYPE i,
    lv_filename   TYPE string,
    lv_approve    TYPE flag,
    lv_accept     TYPE flag,
    lv_reject     TYPE flag,
    lv_set_inact  TYPE flag,
    lv_estat_pbio TYPE j_status,
    lt_parts      TYPE STANDARD TABLE OF string,
    ls_qals       TYPE qals,
    lt_pdf        TYPE STANDARD TABLE OF tline.

  lv_binlines = lines( t_otf ).

  IF t_otf IS NOT INITIAL.
    lv_binwidth = strlen( t_otf[ 1 ] ).
  ENDIF.

  lv_filesize = lv_binlines * lv_binwidth.

  IF p_prev = gc_on.

    IF p_appr = gc_on.
      lv_approve = gc_on.
    ELSE.
      CLEAR lv_approve.
    ENDIF.

    CLEAR ls_qals.
    IF t_prueflos IS NOT INITIAL.
      SELECT SINGLE prueflos,
                    objnr,
                    matnr
        FROM qals
        INTO CORRESPONDING FIELDS OF @ls_qals
        WHERE prueflos IN @t_prueflos.
      IF sy-subrc <> 0.
        CLEAR ls_qals.
      ENDIF.
    ENDIF.

    CALL FUNCTION 'Y_QMLIMS_SERVICE_PDF_PREVIEW'
      EXPORTING
        iv_approve               = lv_approve
        is_qals                  = ls_qals
        it_otf                   = t_otf
      IMPORTING
        ev_accept                = lv_accept
        ev_reject                = lv_reject
      EXCEPTIONS
        convert_otf_to_pdf_error = 1
        cntl_error               = 2
        action_cancelled         = 3
        OTHERS                   = 4.

    CASE sy-subrc.
      WHEN 0.
        IF lv_accept IS NOT INITIAL OR lv_reject IS NOT INITIAL.

          LOOP AT gt_itab INTO gs_itab
               WHERE prueflos IN t_prueflos.

            IF lv_estat_pbio IS INITIAL.
              CALL FUNCTION 'STATUS_TEXT_CONVERSION'
                EXPORTING
                  language           = sy-langu
                  mode               = 'E'
                  objnr              = gs_itab-objnr
                  txt04              = 'PBIO'
                IMPORTING
                  status_number      = lv_estat_pbio
                EXCEPTIONS
                  insufficient_input = 1
                  not_found          = 2
                  object_not_found   = 3
                  wrong_mode         = 4
                  OTHERS             = 5.
              IF sy-subrc <> 0.
                WRITE: / gs_itab-objnr, 'Status inkonsistent'.
              ENDIF.
            ENDIF.

            IF lv_accept = gc_on.
              lv_set_inact = gc_off.
            ELSEIF lv_reject = gc_on.
              lv_set_inact = gc_on.
            ENDIF.

            CALL FUNCTION 'STATUS_CHANGE_EXTERN'
              EXPORTING
                objnr               = gs_itab-objnr
                user_status         = lv_estat_pbio
                set_inact           = lv_set_inact
              EXCEPTIONS
                object_not_found    = 2
                status_inconsistent = 4
                status_not_allowed  = 6.

            CASE sy-subrc.
              WHEN 2.
                WRITE: / 'Objekt', gs_itab-objnr, 'nicht vorhanden'.
              WHEN 4.
                WRITE: / gs_itab-objnr, 'Status inkonsistent'.
              WHEN 6.
                WRITE: / gs_itab-objnr, 'Status', gs_header-estat, 'nicht erlaubt'.
            ENDCASE.

          ENDLOOP.
        ENDIF.
    ENDCASE.

    IF sy-tcode = 'YQM_QA33'.
      IF lv_accept = 'X'.
        EXPORT ok_code FROM space  TO MEMORY ID 'YQMLIMS'.
      ELSE.
        EXPORT ok_code FROM 'CANC' TO MEMORY ID 'YQMLIMS'.
      ENDIF.
      COMMIT WORK AND WAIT.
      LEAVE PROGRAM.
    ENDIF.

  ENDIF.

  IF p_pdf = gc_on.

    CALL FUNCTION 'CONVERT_OTF'
      EXPORTING
        format                = 'PDF'
        max_linewidth         = 134
      IMPORTING
        bin_filesize          = lv_filesize
      TABLES
        otf                   = t_otf
        lines                 = lt_pdf
      EXCEPTIONS
        err_max_linewidth     = 1
        err_format            = 2
        err_conv_not_possible = 3
        OTHERS                = 4.

    IF sy-subrc = 0.

      SPLIT p_file AT '\' INTO TABLE lt_parts.

      READ TABLE lt_parts INTO lv_filename INDEX lines( lt_parts ).

      IF sy-subrc <> 0 OR lv_filename IS INITIAL.
        lv_filename = so_los-low.
      ENDIF.

      SHIFT lv_filename RIGHT DELETING TRAILING '.pdf'.
      CONDENSE lv_filename.

      CONCATENATE lv_filename '.pdf' INTO lv_filename.

      TRY.
          cl_gui_frontend_services=>gui_download(
            EXPORTING
              bin_filesize = lv_filesize
              filename     = lv_filename
              filetype     = 'BIN'
            CHANGING
              data_tab     = lt_pdf ).

          MESSAGE s110 WITH lv_filename.

        CATCH cx_root.
          MESSAGE s161(0d) WITH 'Es erfolgt keine PDF-Ausgabe für' lv_filename.
      ENDTRY.

    ENDIF.

  ELSE.
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.                    " OTF_TO_PDF
