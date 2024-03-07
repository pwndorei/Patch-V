#include <idc.idc>

static main()
{
  set_inf_attr(INF_AF, get_inf_attr(INF_AF) | AF_DODATA | AF_FINAL);

  auto_mark_range(0, BADADDR, AU_FINAL);

  auto_wait();

  //no .asm output

  qexit(0); // exit to OS, error code 0 - success
}
