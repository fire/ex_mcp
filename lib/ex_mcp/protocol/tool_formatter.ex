defmodule ExMCP.Protocol.ToolFormatter do
  @moduledoc """
  Formats tools from internal format to MCP JSON format.

  Converts snake_case keys (input_schema) to camelCase (inputSchema)
  and flattens meta/display_name to title field.
  """

  @doc """
  Transforms a tool from internal format to MCP JSON format.

  ## Examples

      iex> tool = %{name: "test", description: "Test", input_schema: %{"type" => "object"}, display_name: "Test Tool"}
      iex> ToolFormatter.format(tool)
      %{"name" => "test", "description" => "Test", "inputSchema" => %{"type" => "object"}, "title" => "Test Tool"}
  """
  @spec format(map()) :: map()
  def format(tool) when is_map(tool) do
    # Convert atom keys to string keys first
    tool = atom_keys_to_strings(tool)

    # Build MCP-compliant tool
    mcp_tool =
      %{}
      |> Map.put("name", tool["name"])
      |> Map.put("description", tool["description"])
      |> Map.put("inputSchema", tool["input_schema"] || tool["inputSchema"])

    # Add optional fields
    mcp_tool
    |> maybe_add_title(tool)
    |> maybe_add_annotations(tool)
    |> maybe_add_output_schema(tool)
  end

  defp atom_keys_to_strings(map) when is_map(map) do
    Enum.into(map, %{}, fn
      {key, value} when is_atom(key) ->
        {Atom.to_string(key), atom_keys_to_strings(value)}

      {key, value} ->
        {key, atom_keys_to_strings(value)}
    end)
  end

  defp atom_keys_to_strings(value), do: value

  defp maybe_add_title(acc, tool) do
    title =
      tool["display_name"] ||
        (tool["meta"] && is_map(tool["meta"]) &&
           (tool["meta"]["name"] || tool["meta"][:name]))

    if title, do: Map.put(acc, "title", title), else: acc
  end

  defp maybe_add_annotations(acc, tool) do
    annotations = tool["annotations"]

    if annotations && map_size(annotations) > 0 do
      Map.put(acc, "annotations", annotations)
    else
      acc
    end
  end

  defp maybe_add_output_schema(acc, tool) do
    output_schema = tool["output_schema"] || tool["outputSchema"]
    if output_schema, do: Map.put(acc, "outputSchema", output_schema), else: acc
  end
end
