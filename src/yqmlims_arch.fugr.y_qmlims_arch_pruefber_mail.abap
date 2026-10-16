FUNCTION y_qmlims_arch_pruefber_mail.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(IV_PRUEFLOS) TYPE  QPLOS
*"     REFERENCE(IS_QALS) TYPE  QALS
*"     VALUE(IV_KUNNR) TYPE  KUNNR
*"     VALUE(IV_ID) TYPE  SAEARDOID
*"     VALUE(IV_VBELN) TYPE  VBELN_VA
*"     VALUE(IV_PNDAT) TYPE  QALS-YQM_PROBEDATUM OPTIONAL
*"  EXPORTING
*"     VALUE(EV_SUBRC) TYPE  SYST_SUBRC
*"  TABLES
*"      T_TOA01 STRUCTURE  TOA01 OPTIONAL
*"      T_RECEIVER STRUCTURE  SOMLRECI1 OPTIONAL
*"----------------------------------------------------------------------

  DATA lv_email        TYPE text80.
  DATA lv_mobil        TYPE text80.
  DATA lv_telnr        TYPE text80.
  DATA lv_text         TYPE so_text255.
  DATA lv_artlab       TYPE yqm_artlab.
  DATA lv_pn_date      TYPE char10.
  DATA lv_count        TYPE sy-dbcnt.
  DATA lv_body_start   TYPE so_bd_strt.
  DATA lv_head_start   TYPE so_hd_num.
  DATA lv_xstring      TYPE xstring.
  DATA lv_binlength    TYPE sapb-length.
  DATA lv_tab_lines    TYPE i.
  DATA lv_input_length TYPE i.

  DATA ls_address      TYPE bapiaddr3.
  DATA ls_addsmtp      TYPE bapiadsmtp.
  DATA ls_addtel       TYPE bapiadtel.
  DATA ls_freigeber    TYPE gty_freigeber.
  DATA ls_toa01        TYPE toa01.
  DATA ls_qave         TYPE qave.
  DATA ls_arpbag       TYPE yqm_arpbag_t.
  DATA ls_matn_tx      TYPE yqm_matn_tx_t.
  DATA ls_docdata      TYPE sodocchgi1.
  DATA ls_objpack      TYPE sopcklsti1.
  DATA ls_objtxt       TYPE solisti1.

  DATA lt_addsmtp      TYPE STANDARD TABLE OF bapiadsmtp.
  DATA lt_addtel       TYPE STANDARD TABLE OF bapiadtel.
  DATA lt_return       TYPE STANDARD TABLE OF bapiret2.
  DATA lt_arpbag       TYPE STANDARD TABLE OF yqm_arpbag_t.
  DATA lt_reclist      TYPE STANDARD TABLE OF somlreci1.
  DATA lt_objpack      TYPE STANDARD TABLE OF sopcklsti1.
  DATA lt_objhead      TYPE STANDARD TABLE OF solisti1.
  DATA lt_objtxt       TYPE STANDARD TABLE OF solisti1.
  DATA lt_objtxt_leg   TYPE STANDARD TABLE OF solisti1.
  DATA lt_objbin       TYPE STANDARD TABLE OF solix.
  DATA lt_objbinalle   TYPE STANDARD TABLE OF solix.
  DATA lt_content      TYPE STANDARD TABLE OF solix.

  CLEAR:
    gt_doc,
    gt_tbl,
    gt_reclist,
    gt_attachment.

  IF NOT iv_pndat IS INITIAL.
    WRITE iv_pndat TO lv_pn_date.
  ELSEIF NOT is_qals-yqm_probedatum IS INITIAL.
    WRITE is_qals-yqm_probedatum  TO lv_pn_date.
  ELSE.
    CLEAR lv_pn_date.
  ENDIF.

  IF NOT iv_prueflos IS INITIAL.
    SELECT SINGLE artlab
      FROM yqm_matn_hd_t AS m JOIN qals AS q ON m~matnr = q~matnr
      INTO lv_artlab
      WHERE prueflos = iv_prueflos.
    IF  sy-subrc       <> 0.
      CLEAR lv_artlab.
    ENDIF.
    SELECT SINGLE * FROM qave INTO ls_qave
      WHERE prueflos = iv_prueflos.
    IF sy-subrc <> 0.
      CLEAR ls_qave.
    ENDIF.
  ENDIF.

* Informationen zum Zeugnisersteller besorgen
  IF NOT ls_qave-vcode IS INITIAL.
    IF NOT ls_qave-vaename IS INITIAL.
      ls_freigeber-vname  = ls_qave-vaename.
      ls_freigeber-vdatum = ls_qave-vaedatum.
      ls_freigeber-vzeit  = ls_qave-vezeitaen.
    ELSE.
      ls_freigeber-vname  = ls_qave-vname.
      ls_freigeber-vdatum = ls_qave-vdatum.
      ls_freigeber-vzeit  = ls_qave-vezeiterf.
    ENDIF.
  ELSE.
    ls_freigeber-vname = sy-uname.
  ENDIF.

  CALL FUNCTION 'BAPI_USER_GET_DETAIL'
    EXPORTING
      username = ls_freigeber-vname
    IMPORTING
      address  = ls_address
    TABLES
      return   = lt_return
      addtel   = lt_addtel
      addsmtp  = lt_addsmtp.

  ls_freigeber-vname_list  = ls_address-fullname.

  LOOP AT lt_addtel INTO ls_addtel WHERE r_3_user = '1'.
    CONCATENATE ls_addtel-telephone
                ls_addtel-extension
                INTO lv_telnr SEPARATED BY '-'.
  ENDLOOP.

  LOOP AT lt_addtel INTO ls_addtel WHERE r_3_user = '3'.
    lv_mobil = ls_addtel-telephone.     "Mobilnummer
  ENDLOOP.

  LOOP AT lt_addsmtp INTO ls_addsmtp WHERE std_no = 'X'.
    lv_email = ls_addsmtp-e_mail.     "EMail-Anschrift Anspr
  ENDLOOP.

  SELECT * FROM yqm_arpbag_t
    INTO TABLE lt_arpbag
    WHERE kunag EQ iv_kunnr
      AND ( pnart EQ is_qals-yqm_probenahmeart
         OR pnart EQ space )
      AND dab   LE sy-datum
      AND dbi   GE sy-datum
      AND aki   EQ ' '.
  IF sy-subrc <> 0.
    CLEAR lt_arpbag.
  ENDIF.
  LOOP AT lt_arpbag INTO ls_arpbag.
    MOVE-CORRESPONDING ls_arpbag TO gs_arpbag.
* nur den ersten namen merken
    IF iv_kunnr GE '0000000000' AND iv_kunnr LE '0000000100' AND sy-dbcnt = 1.
      gv_name1 = gs_arpbag-name.
    ELSE.
* 15.1.19 Gme Änderung Betreffszeile
      SELECT SINGLE adrnr
        FROM kna1
        INTO @DATA(lv_adrnr)
        WHERE kunnr = @iv_kunnr.
      IF sy-subrc NE 0.
        gv_name1 = gs_arpbag-name(20).
      ELSE.
        SELECT SINGLE sort2 FROM adrc INTO gv_name1 WHERE addrnumber = lv_adrnr.
        IF sy-subrc NE 0.
          gv_name1 = gs_arpbag-name(20).
        ENDIF.
      ENDIF.
    ENDIF.

* Mailempfänger
    IF iv_vbeln IS NOT INITIAL
     AND gs_arpbag-vbeln = iv_vbeln
* wenn ein SD-Auftrag in der Tabelle gepflegt ist so sollen nur die dazugehörigen eMails gezogen werden
     OR  gs_arpbag-vbeln IS INITIAL.
* In Abhängigkeit des neuen Feldes BED sollen Empfänger
* immer oder nur bei Rückweisunge von Merkmalen informiert werden
      IF gs_arpbag-bed = 'X'.
* Bei Rückweisung sollen (evtl. in Abhängigkeit der Art der Untersuchung)
* zusätzliche Empfänger informiert werden (Bei Legionellen das Gesundheitsamt)
        IF gs_arpbag-artlab IS INITIAL
        OR gs_arpbag-artlab EQ lv_artlab.
          SELECT COUNT( * ) FROM qasr
            INTO lv_count
            WHERE prueflos = iv_prueflos
              AND mbewertg = 'R'.
          IF  sy-subrc = 0
          AND lv_count GT 0.
            gs_reclist-receiver = gs_arpbag-mail.
            gs_reclist-rec_type = 'U'.
            APPEND gs_reclist TO gt_reclist.
            CLEAR gs_reclist.
          ENDIF.
        ENDIF.
      ELSE.
        gs_reclist-receiver = gs_arpbag-mail.
        gs_reclist-rec_type = 'U'.
        APPEND gs_reclist TO gt_reclist.
        CLEAR gs_reclist.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF lv_artlab = 'LEG'.
    CLEAR lt_objtxt_leg.
    PERFORM befund_legionellen_ermitteln TABLES lt_objtxt_leg
                                         USING iv_prueflos.
  ELSE.
    CLEAR lt_objtxt_leg.
  ENDIF.

* Bei Verarbeitung im Vordergrund werden die zusätzlichen Berichtsempfänger
* ermittelt und zur Auswahl angeboten
  IF sy-batch IS INITIAL.
    CALL FUNCTION 'Y_QMLIMS_CERT_DET_ADD_RECEIVER'
      EXPORTING
        is_qals    = is_qals
      TABLES
        t_receiver = lt_reclist.
    IF NOT lt_reclist[] IS INITIAL.
      APPEND LINES OF lt_reclist TO gt_reclist.
      SORT gt_reclist.
      DELETE ADJACENT DUPLICATES FROM gt_reclist.
    ENDIF.
  ENDIF.

  APPEND LINES OF t_receiver TO gt_reclist.

  IF  sy-sysid NE 'PHC'.
    IF t_toa01[] IS INITIAL.
      CONCATENATE gv_name1 '- Laborbericht' iv_prueflos
        sy-sysid 'TEST' INTO gv_documenttitle SEPARATED BY space.
    ELSE.
      CONCATENATE gv_name1 '- Laborberichte PN ' lv_pn_date
        sy-sysid 'TEST' INTO gv_documenttitle SEPARATED BY space.
    ENDIF.
  ELSE.
    IF t_toa01[] IS INITIAL.
      CONCATENATE gv_name1 '- Laborbericht' iv_prueflos
                        INTO gv_documenttitle SEPARATED BY space.
    ELSE.
      CONCATENATE gv_name1 '- Laborberichte PN ' lv_pn_date
                        INTO gv_documenttitle SEPARATED BY space.
    ENDIF.
  ENDIF.
  gv_documentname    = 'Prüfbericht'.

*"----------------------------------------------------------------------
* Mailanhang Prüfbericht erstellen

  CALL FUNCTION 'ARCHIVOBJECT_GET_BYTES'
    EXPORTING
      archiv_id                = 'BM'
      archiv_doc_id            = iv_id
      document_type            = 'PDF'
      length                   = '000000000000'
      offset                   = '000000000000'
      mode                     = ' '
      signature                = 'X'
      shift_flag               = ' '
      compid                   = 'DATA'
    IMPORTING
      binlength                = lv_binlength
    TABLES
      archivobject             = gt_doc
      binarchivobject          = gt_tbl
    EXCEPTIONS
      error_archiv             = 1
      error_communicationtable = 2
      error_kernel             = 3
      OTHERS                   = 4.
  IF sy-subrc <> 0.
    ev_subrc = '90'. "Prüfbericht nicht im Archiv BM
  ELSE.

    lv_input_length = lv_binlength.

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_input_length
      IMPORTING
        buffer       = lv_xstring
      TABLES
        binary_tab   = gt_tbl
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.

    IF sy-subrc <> 0.
      ev_subrc = '91'.
      RETURN.
    ENDIF.

    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer     = lv_xstring
      TABLES
        binary_tab = lt_content.

*"----------------------------------------------------------------------
    gs_attachment-type  = 'PDF'.
    gs_attachment-name  = iv_prueflos.

    CONCATENATE iv_prueflos '.PDF' INTO gs_attachment-descr.
    gs_attachment-objektx[] = lt_content[].
    APPEND gs_attachment TO gt_attachment.
    CLEAR gs_attachment-objektx.

    LOOP AT t_toa01 INTO ls_toa01.

      CLEAR gs_attachment.
      CLEAR gt_doc.
      CLEAR gt_tbl.
      CLEAR lt_content.

* Mailanhang Prüfbericht erstellen
      CALL FUNCTION 'ARCHIVOBJECT_GET_BYTES'
        EXPORTING
          archiv_id                = 'BM'
          archiv_doc_id            = ls_toa01-arc_doc_id
          document_type            = 'PDF'
          length                   = '000000000000'
          offset                   = '000000000000'
          mode                     = ' '
          signature                = 'X'
          shift_flag               = ' '
          compid                   = 'DATA'
        IMPORTING
*         LENGTH                   =
*         OFFSET                   =
          binlength                = lv_binlength
        TABLES
          archivobject             = gt_doc
          binarchivobject          = gt_tbl
        EXCEPTIONS
          error_archiv             = 1
          error_communicationtable = 2
          error_kernel             = 3
          OTHERS                   = 4.
      IF sy-subrc <> 0.
        ev_subrc = '90'. "Prüfbericht nicht im Archiv BM
      ELSE.
*"----------------------------------------------------------------------

        lv_input_length = lv_binlength.


        CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
          EXPORTING
            input_length = lv_input_length
          IMPORTING
            buffer       = lv_xstring
          TABLES
            binary_tab   = gt_tbl
          EXCEPTIONS
            failed       = 1
            OTHERS       = 2.

        IF sy-subrc <> 0.
          ev_subrc = '91'.
          RETURN.
        ENDIF.

        CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
          EXPORTING
            buffer     = lv_xstring
          TABLES
            binary_tab = lt_content.


        gs_attachment-type  = 'PDF'.
        gs_attachment-name  = ls_toa01-object_id. "i_prueflos.

        CONCATENATE ls_toa01-object_id '.PDF' INTO gs_attachment-descr.

        CLEAR gs_attachment-objektx.
        gs_attachment-objektx[] = lt_content[].
*"----------------------------------------------------------------------
        APPEND gs_attachment TO gt_attachment.
        CLEAR gs_attachment-objektx.
      ENDIF.

    ENDLOOP.


* Create Message Body
* Title and Description
    ls_docdata-obj_name  = gv_documentname.
    ls_docdata-obj_descr = gv_documenttitle.
* Main Text
    ls_objtxt = 'Sehr geehrte Damen und Herren,'.
    APPEND ls_objtxt TO lt_objtxt.
    CLEAR lt_objtxt.
    APPEND ls_objtxt TO lt_objtxt.

    SELECT SINGLE * FROM yqm_matn_tx_t INTO ls_matn_tx
      WHERE matnr = is_qals-matnr.
    IF sy-subrc <> 0.
      CLEAR ls_matn_tx.
    ENDIF.

    IF   is_qals-ktextlos IS INITIAL
    AND  is_qals-ktextmat IS INITIAL
    AND  ls_matn_tx-text IS INITIAL.
      IF lv_pn_date IS INITIAL.
        lv_text = iv_prueflos.
      ELSE.
        CONCATENATE iv_prueflos
                    ' ('
                    lv_pn_date
                    ')'
                    INTO lv_text.
      ENDIF.
    ELSE.
      IF NOT is_qals-ktextmat IS INITIAL.
        lv_text = is_qals-ktextmat.
      ENDIF.

      IF NOT is_qals-ktextlos IS INITIAL.
        IF NOT lv_text IS INITIAL.
          CONCATENATE lv_text '/' is_qals-ktextlos INTO lv_text.
        ELSE.
          lv_text = is_qals-ktextmat.
        ENDIF.
      ENDIF.

      IF NOT ls_matn_tx-text IS INITIAL.
        IF NOT lv_text IS INITIAL.
          CONCATENATE lv_text '/' ls_matn_tx-text INTO lv_text.
        ELSE.
          lv_text = ls_matn_tx-text.
        ENDIF.
      ENDIF.

      IF NOT lv_pn_date IS INITIAL.
        CONCATENATE lv_text ' / ' lv_pn_date INTO lv_text.
      ENDIF.

      CONCATENATE iv_prueflos
                  ' ('
                  lv_text
                  ')'
                  INTO lv_text.
    ENDIF.

    IF t_toa01[] IS INITIAL.
      CONCATENATE 'anbei erhalten Sie den Prüfbericht' lv_text 'als PDF-Datei.'
                  INTO ls_objtxt SEPARATED BY space.
    ELSE.
      CONCATENATE 'anbei erhalten Sie die Prüfberichte zum Probenahmedatum '
                  lv_pn_date 'als PDF-Datei.'
                  INTO ls_objtxt SEPARATED BY space.
    ENDIF.
    APPEND ls_objtxt TO lt_objtxt.
    CLEAR ls_objtxt.
    APPEND LINES OF lt_objtxt_leg TO lt_objtxt.
    CLEAR ls_objtxt.
    APPEND ls_objtxt TO lt_objtxt.
    CLEAR ls_objtxt.
    APPEND ls_objtxt TO lt_objtxt.
    ls_objtxt = ls_address-fullname. " 'Franz Meißner'.
    APPEND ls_objtxt TO lt_objtxt.
    IF NOT ls_address-department IS INITIAL.
      ls_objtxt = ls_address-department.
*    objtxt = 'NSG-UW'.
      APPEND ls_objtxt TO lt_objtxt.
    ENDIF.
    CLEAR ls_objtxt.
    APPEND ls_objtxt TO lt_objtxt.
    IF NOT ls_address-tel1_numbr IS INITIAL.
      CONCATENATE 'Telefon: '
                  lv_telnr
                  INTO ls_objtxt SEPARATED BY space.
      APPEND ls_objtxt TO lt_objtxt.
    ENDIF.

    IF NOT lv_mobil IS INITIAL.
      CONCATENATE 'Mobil:   '
                  lv_mobil
                  INTO ls_objtxt RESPECTING BLANKS.
      APPEND ls_objtxt TO lt_objtxt.
    ENDIF.

    IF NOT lv_email IS INITIAL.
      CONCATENATE 'E-Mail:  '
                  lv_email
                  INTO ls_objtxt RESPECTING BLANKS.
      APPEND ls_objtxt TO lt_objtxt.
    ENDIF.

    lv_tab_lines = lines( lt_objtxt ).
    READ TABLE lt_objtxt INDEX lv_tab_lines INTO ls_objtxt.
    ls_docdata-doc_size = ( lv_tab_lines - 1 ) * 255 + strlen( ls_objtxt ).
*
    CLEAR: ls_objpack.
    CLEAR: lt_objbin, lt_objpack, lt_objhead.
    ls_objpack-doc_size   =   ls_docdata-doc_size.
    CLEAR ls_objpack-transf_bin.
    ls_objpack-head_start = 1.
    ls_objpack-head_num   = 0.
    ls_objpack-body_start = 1.
    ls_objpack-body_num   = lv_tab_lines.
    ls_objpack-doc_type   = 'RAW'.
    APPEND ls_objpack TO lt_objpack.
    CLEAR ls_objpack.

* Create Message Attachment
    lv_body_start = 1.
    lv_head_start = 1.

    LOOP AT gt_attachment INTO gs_attachment.
      CLEAR lt_objbin.

      IF gs_attachment-type = 'PDF'.
        APPEND LINES OF gs_attachment-objektx TO lt_objbin.
        APPEND gs_attachment-descr TO lt_objhead.
      ENDIF.
      IF gs_attachment-type = 'PDF'.
        lv_tab_lines = lines( lt_objbin ).
        READ TABLE lt_objbin INDEX lv_tab_lines TRANSPORTING NO FIELDS.

        ls_objpack-doc_size   = lv_tab_lines * 255.
        ls_objpack-transf_bin = 'X'.
        ls_objpack-head_start = lv_head_start.
        ls_objpack-head_num   = 1.
        ls_objpack-body_start = lv_body_start.
        ls_objpack-body_num   = lv_body_start + lv_tab_lines - 1 .

        lv_head_start = lv_head_start + 1.
        lv_body_start = lv_body_start + lv_tab_lines.
      ENDIF.
      APPEND LINES OF lt_objbin TO lt_objbinalle.
      ls_objpack-doc_type   = gs_attachment-type.
      ls_objpack-obj_name   = gs_attachment-name.
      ls_objpack-obj_descr  = gs_attachment-descr.
      APPEND ls_objpack TO lt_objpack.
      CLEAR ls_objpack.
    ENDLOOP.
* Send Message
    CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
      EXPORTING
        document_data              = ls_docdata
        put_in_outbox              = 'X'
        commit_work                = 'X'
      TABLES
        packing_list               = lt_objpack
        object_header              = lt_objhead
        contents_txt               = lt_objtxt
        contents_hex               = lt_objbinalle
*       contents_bin               = objbinalle
        receivers                  = gt_reclist
      EXCEPTIONS
        too_many_receivers         = 1
        document_not_sent          = 2
        document_type_not_exist    = 3
        operation_no_authorization = 4
        parameter_error            = 5
        x_error                    = 6
        enqueue_error              = 7
        OTHERS                     = 8.
    IF sy-subrc <> 0.
      ev_subrc = '91'. "Fehler beim Senden des Mail
    ENDIF.
  ENDIF.

ENDFUNCTION.
