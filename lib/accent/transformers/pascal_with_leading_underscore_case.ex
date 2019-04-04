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

  def call(""), do: ""

  def call(<<h::utf8, t::binary>>) do
    PascalCase.call(<<h::utf8, t::binary>>)
    # String.downcase(<<h>>) <> do_pascalize(t)
  end

  # private

  # defp do_pascalize(<<?_, ?_, t::binary>>) do
  #   do_pascalize(<<?_, t::binary>>)
  # end

  # defp do_pascalize(<<?_, h::utf8, t::binary>>) do
  #   String.upcase(<<h>>) <> do_pascalize(t)
  # end

  # defp do_pascalize(<<?_>>), do: <<>>

  # defp do_pascalize(<<h::utf8, t::binary>>) do
  #   <<h>> <> do_pascalize(t)
  # end

  # defp do_pascalize(<<>>), do: <<>>
end
