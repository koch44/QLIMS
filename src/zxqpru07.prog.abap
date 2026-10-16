*&---------------------------------------------------------------------*
*& Include          ZXQPRU07
*&---------------------------------------------------------------------*
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"       EXPORTING
*"             VALUE(E_QPRS_CUST) LIKE  QPRS_CUST STRUCTURE  QPRS_CUST
*"             VALUE(E_ACTIV) LIKE  QM00-QKZ
*"----------------------------------------------------------------------

MOVE-CORRESPONDING qprs TO e_qprs_cust.
e_activ = 'X'.
