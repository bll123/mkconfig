import std.stdio;
import std.string;

import tcl.tcl;
import tk.tk;

int main(string[] args)
{
  Tcl_Interp *tcl_interp;
  Tk_Window mainWindow;

  tcl_interp = Tcl_CreateInterp();
  if (Tcl_Init(tcl_interp) != TCL_OK || Tk_Init(tcl_interp) != TCL_OK) {
    if(*tcl_interp.result) {
      printf ("A:%s\n", tcl_interp.result);
    }
    return 1;
  }

  mainWindow = Tk_MainWindow(tcl_interp);
  if (mainWindow == null) {
    printf ("C:%s\n", tcl_interp.result);
    return 1;
  }

  Tcl_Eval (tcl_interp, "label .w -text \"Hello World\"");
  Tcl_Eval (tcl_interp, "pack .w");

  Tk_MainLoop ();

  return 0;
}
