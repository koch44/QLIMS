DATA: lt_lines TYPE TABLE OF TLINE.

CLEAR gv_longtext.
IF NOT gs_qamv_qmtt-ltextkz IS INITIAL.
  CONCATENATE gs_qamv_qmtt-mandt
              gs_qamv_qmtt-werks
              gs_qamv_qmtt-pmtnr
              gs_qamv_qmtt-version
              gs_qamv_qmtt-sprache
         INTO gv_longtext.

  CALL FUNCTION 'READ_TEXT'
    EXPORTING
*     CLIENT                  = SY-MANDT
      id                      = 'QMTT'
      language                = sy-langu
      name                    = gv_longtext
      object                  = 'QPMETHODE'
*     ARCHIVE_HANDLE          = 0
*     LOCAL_CAT               = ' '
*   IMPORTING
*     HEADER                  =
*     OLD_LINE_COUNTER        =
    TABLES
      lines                   = lt_lines
    EXCEPTIONS
      id                      = 1
      language                = 2
      name                    = 3
      not_found               = 4
      object                  = 5
      reference_check         = 6
      wrong_access_to_archive = 7
      OTHERS                  = 8.
  IF sy-subrc <> 0.
* Implement suitable error handling here
    CLEAR gv_longtext.
  ENDIF.

ENDIF.





















