*&---------------------------------------------------------------------*
*&  Include           ZXQEVU07
*&---------------------------------------------------------------------*
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"       IMPORTING
*"             VALUE(I_QALS) LIKE  QALS STRUCTURE  QALS
*"             VALUE(I_QAVE) LIKE  QAVE STRUCTURE  QAVE
*"             VALUE(I_TCODE) LIKE  SY-TCODE
*"       EXPORTING
*"             VALUE(E_EXIT_ACTIV) LIKE  QM00-QKZ
*"             VALUE(E_NO_ACCESS) LIKE  QM00-QKZ
*"             VALUE(E_MODIFY_FLAG) LIKE  QM00-QKZ
*"             VALUE(E_QAVE) LIKE  QAVE STRUCTURE  QAVE
*"----------------------------------------------------------------------

e_qave = i_qave.
