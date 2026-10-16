*&---------------------------------------------------------------------*
*& Include          ZXQQMU01
*&---------------------------------------------------------------------*
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"       IMPORTING
*"             VALUE(I_VIQMEL) LIKE  VIQMEL STRUCTURE  VIQMEL
*"             VALUE(I_TQ80) LIKE  TQ80 STRUCTURE  TQ80
*"       EXPORTING
*"             VALUE(E_VIQMEL) LIKE  VIQMEL STRUCTURE  VIQMEL
*"       TABLES
*"              T_VIQMFE STRUCTURE  WQMFE
*"              T_VIQMUR STRUCTURE  WQMUR
*"              T_VIQMMA STRUCTURE  WQMMA
*"              T_VIQMSM STRUCTURE  WQMSM
*"----------------------------------------------------------------------

DATA ls_t001w TYPE t001w.
DATA ls_qmfe  TYPE wqmfe.

IF i_viqmel-qmart = 'YL'
   AND e_viqmel-prueflos IS NOT INITIAL.

  SELECT SINGLE yqm_tplnr, yqm_service_doc_type,
                yqm_service_doc_id, yqm_service_doc_item_id
    FROM qals
    WHERE prueflos = @e_viqmel-prueflos
    INTO @DATA(ls_qals).

  IF sy-subrc = 0.
    e_viqmel-tplnr                   = ls_qals-yqm_tplnr.
    e_viqmel-yqm_service_doc_type    = ls_qals-yqm_service_doc_type.
    e_viqmel-yqm_service_doc_id      = ls_qals-yqm_service_doc_id.
    e_viqmel-yqm_service_doc_item_id = ls_qals-yqm_service_doc_item_id.
  ELSE.
    CLEAR e_viqmel-tplnr.
    CLEAR e_viqmel-yqm_service_doc_type.
    CLEAR e_viqmel-yqm_service_doc_id.
    CLEAR e_viqmel-yqm_service_doc_item_id.
  ENDIF.

  READ TABLE t_viqmfe INTO ls_qmfe INDEX 1.
  IF sy-subrc = 0.

    e_viqmel-qmkat = i_tq80-sakat.
    e_viqmel-qmgrp = ls_qmfe-fegrp.
    e_viqmel-qmcod = ls_qmfe-fecod.

    CASE e_viqmel-qmcod.
      WHEN 'TMW1'.
        e_viqmel-priok = '3'.
      WHEN 'TMW2'.
        e_viqmel-priok = '2'.
      WHEN 'TMW3'.
        e_viqmel-priok = '1'.
      WHEN 'TMW0'.
        e_viqmel-priok = '9'.
      WHEN OTHERS.
        e_viqmel-priok = '9'.
    ENDCASE.

    CLEAR ls_t001w.

    IF e_viqmel-mawerk IS NOT INITIAL.
      SELECT SINGLE fabkl
        FROM t001w
        WHERE werks = @e_viqmel-mawerk
        INTO @ls_t001w-fabkl.
      IF sy-subrc <> 0.
        CLEAR ls_t001w-fabkl.
      ENDIF.
    ENDIF.

    e_viqmel-strmn = sy-datlo.
    e_viqmel-strur = sy-timlo.

    CALL FUNCTION 'CALCULATE_PRIORITY'
      EXPORTING
        i_artpr             = e_viqmel-artpr
        i_priok             = e_viqmel-priok
        i_strmn             = e_viqmel-strmn
        i_strur             = e_viqmel-strur
        i_calid             = ls_t001w-fabkl
      IMPORTING
        e_ltrmn             = e_viqmel-ltrmn
        e_ltrur             = e_viqmel-ltrur
      EXCEPTIONS
        invalid_prio        = 1
        invalid_date        = 2
        dimension_not_found = 3
        unit_not_found      = 4
        OTHERS              = 5.

    IF sy-subrc <> 0.
      CLEAR: e_viqmel-ltrmn,
             e_viqmel-ltrur.
    ENDIF.

  ENDIF.

  CALL FUNCTION 'IQS2_CREATE_ILOA_FROM_VIQMEL'
    EXPORTING
      i_viqmel = e_viqmel.

ENDIF.
