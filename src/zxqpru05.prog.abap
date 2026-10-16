*&---------------------------------------------------------------------*
*& Include          ZXQPRU05
*&---------------------------------------------------------------------*
ASSIGN ('(SAPLQPRS)G_T185F_AKTI') TO <gv_akti>.

IF sy-subrc = 0.
  gv_akti = <gv_akti>.
ELSE.
  CLEAR gv_akti.
ENDIF.

MOVE-CORRESPONDING i_qprs TO qprs.
