PROCESS BEFORE OUTPUT.

* Dynpro-Status setzen
  MODULE status_0050.

*----------------------------------------------------------------------*

PROCESS AFTER INPUT.
* Check Kostenstelle
  FIELD gv_kostl MODULE check_cost_center.

* Reaktion auf user commands
  MODULE user_command_0050.
