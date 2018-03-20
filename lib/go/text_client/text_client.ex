defmodule Go.TextClient do
  @moduledoc false
  
  alias Go.TextClient.Interact
  
  defdelegate start(size \\ 19), to: Interact
end
