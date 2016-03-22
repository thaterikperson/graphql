
defmodule GraphQL.Lang.AST.TypeInfo do
  @moduledoc ~S"""
  TypeInfo maintains type metadata pertaining to the current node of a query AST,
  and is generated by the TypeInfoVistor.

  The type information is made available to validation rules.
  """

  alias GraphQL.Util.Stack
  alias GraphQL.Type.List
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.Introspection
  alias GraphQL.Type.CompositeType

  @behaviour Access
  defstruct schema: nil,
            type_stack: %Stack{},
            parent_type_stack: %Stack{},
            input_type_stack: %Stack{},
            field_def_stack: %Stack{},
            directive: nil,
            argument: nil

  @doc """
  Return the top of the type stack, or nil if empty.
  """
  def type(type_info), do: Stack.peek(type_info.type_stack)

  def named_type(type_info, %List{} = type), do: named_type(type_info, type.ofType)
  def named_type(type_info, %NonNull{} = type), do: named_type(type_info, type.ofType)
  def named_type(_, type), do: type

  @doc """
  Return the top of the parent type stack, or nil if empty.
  """
  def parent_type(type_info) do
    Stack.peek(type_info.parent_type_stack)
  end

  @doc """
  Return the top of the field def stack, or nil if empty.
  """
  def field_def(type_info) do
    Stack.peek(type_info.field_def_stack)
  end

  # FIXME: pattern match on function heads
  def find_field_def(schema, parent_type, field_node) do
    name = String.to_atom(field_node.name.value)
    cond do
      name == String.to_atom(Introspection.meta(:schema)[:name]) && schema.query == parent_type ->
        Introspection.meta(:schema)
      name == String.to_atom(Introspection.meta(:type)[:name]) && schema.query == parent_type ->
        Introspection.meta(:type)
      name == String.to_atom(Introspection.meta(:typename)[:name]) ->
        Introspection.meta(:typename)
      parent_type.__struct__ == GraphQL.Type.Object || parent_type.__struct__ == GraphQL.Type.Interface ->
        CompositeType.get_field(parent_type, name)
      true ->
        nil
    end
  end
end
