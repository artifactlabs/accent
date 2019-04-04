defmodule Accent.Transformer.PascalWithLeadingUnderscoreCase do
  @moduledoc """
  Converts the given binary or atom to pascalCase (with leading underscore) format.
  """

  alias Accent.Transformer.PascalCase

  @behaviour Accent.Transformer

  def call(atom) when is_atom(atom) do
    String.to_atom(call(to_string(atom)))
  end

  def call(<<?_, t::binary>>) do
    "_" <> call(t)
  end

  def call(string), do: PascalCase.call(string)
end
