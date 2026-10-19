// =============================================================================
// File: main.cc
// Purpose: Starts the Linux Flutter application and its GTK event loop.
// =============================================================================
#include "my_application.h"

int main(int argc, char** argv) {
  // Create the application and run it with the supplied command-line arguments.
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
