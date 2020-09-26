defmodule Makeup.Lexers.CLexer.Testing do
  @moduledoc false
  # The tests need to be checked manually!!! (remove this line when they've been checked)
  alias Makeup.Lexers.CLexer
  alias Makeup.Lexer.Postprocess

  @sample_a """
  //---------------------------------------------------------
  kos_status_t kos_msg_queue_notification(
    IN kos_cap_t notification_cap
  ) {
    kos_status_t status;

    if ( notification_cap ) {
      // setting the notification
      seL4_SetCap( 0, kos_cap_cptr(notification_cap) );
      seL4_MessageInfo_t msg = seL4_Call(
        KOS_APP_SLOT_MESSAGING_EP,
        seL4_MessageInfo_new(KOS_MSG_QUEUE_SET_NOTIFICATION, 0, 1, 0)
      );
      status = seL4_MessageInfo_get_label( msg );
    } else {
      // clearing the notification
      seL4_MessageInfo_t msg = seL4_Call(
        KOS_APP_SLOT_MESSAGING_EP,
        seL4_MessageInfo_new(KOS_MSG_QUEUE_CLEAR_NOTIFICATION, 0, 0, 0)
      );
      status = seL4_MessageInfo_get_label( msg );
    }

    return status;
  }
"""
@sample_b """
static inline int test_fn(
IN kos_cap_t notification_cap
) {
int arr[3] = {0};
int a = 0;
a--;
return a;
}
"""
@sample_c """
#ifdef BOOGER
return NULL;
#endif
"""

  def lex_a(), do: @sample_a |> lex()
  def lex_b(), do: @sample_b |> lex()
  def lex_c(), do: @sample_c |> lex()

  # This function has two purposes:
  # 1. Ensure deterministic lexer output (no random prefix)
  # 2. Convert the token values into binaries so that the output
  #    is more obvious on visual inspection
  #    (iolists are hard to parse by a human)
  def lex(text) do
    text
    |> CLexer.lex(group_prefix: "group")
    |> Postprocess.token_values_to_binaries()
    |> Enum.map(fn {ttype, meta, value} -> {ttype, Map.delete(meta, :language), value} end)
  end
end
