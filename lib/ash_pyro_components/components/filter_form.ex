defmodule AshPyroComponents.Components.FilterForm do
  @moduledoc """
  Automatically render filter forms for Ash resources.
  """

  use AshPyroComponents.LiveComponent

  import PyroComponents.Components.Core, only: [input: 1, icon: 1]

  @doc """
  Renders a filter form for the given resource action.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :id, :string, required: true
  attr :resource, :atom, required: true, doc: "the resource of the data table"
  attr :action, :atom, required: true, doc: "the action to filter"
  attr :to_uri, :any, required: true, doc: "a function that takes params and returns a uri"

  attr :uri_params, :map,
    required: true,
    doc: "the current params; filter params are expected to be namespaced under target_id"

  attr :target_id, :string, required: true, doc: "the target component id"
  attr :actor, :map, default: nil, doc: "the actor to be passed to actions"
  attr :tz, :string, default: "Etc/UTC", doc: "timezone"
  attr :class, :css_classes, overridable: true
  attr :form_class, :css_classes, overridable: true
  attr :fieldset_class, :css_classes, overridable: true
  attr :legend_class, :css_classes, overridable: true
  attr :legend_label_class, :css_classes, overridable: true
  attr :button_class, :css_classes, overridable: true
  attr :input_class, :css_classes, overridable: true

  @impl true
  def render(assigns) do
    assigns =
      assign_overridables(assigns)

    ~H"""
    <div id={@id} class={@class}>
      <button
        :if={!@filter_form}
        type="button"
        class={@button_class}
        phx-target={@myself}
        phx-click="new_filter"
      >
        Filter Results
      </button>
      <.form
        :let={f}
        :if={@filter_form}
        class={@form_class}
        for={@filter_form}
        phx-target={@myself}
        phx-change="apply_filter"
        phx-submit="apply_filter"
        autocomplete="off"
      >
        <fieldset class={@fieldset_class}>
          <legend class={@legend_class}>
            <span class={@legend_label_class}>Filter</span>
            <.input
              input_class={@input_class}
              field={f[:operator]}
              type="select"
              options={group_operator_options()}
            />
            <button type="button" class={@button_class} phx-target={@myself} phx-click="clear_filter">
              Clear Filter
            </button>
            <button
              type="button"
              class={@button_class}
              phx-target={@myself}
              phx-click="add_predicate"
              phx-value-id={f.data.id}
            >
              Add Predicate
            </button>
            <button
              type="button"
              class={@button_class}
              phx-target={@myself}
              phx-click="add_group"
              phx-value-id={f.data.id}
            >
              Add Group
            </button>
          </legend>
          <.inputs_for :let={c} field={f[:components]}>
            <.render_component
              form={c}
              myself={@myself}
              actor={@actor}
              resource={@resource}
              action={@action}
              tz={@tz}
            />
          </.inputs_for>
        </fieldset>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket), do: {:ok, socket}

  @impl true
  def update(%{uri_params: uri_params, target_id: target_id} = assigns, %{assigns: %{filter_form: filter_form}} = socket) do
    filter_form =
      case get_nested(uri_params, [target_id, "filter"]) do
        filter_params when is_map(filter_params) and filter_params != %{} ->
          AshPhoenix.FilterForm.validate(filter_form, filter_params)

        _ ->
          nil
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:filter_form, filter_form)}
  end

  @impl true
  def update(%{resource: resource, uri_params: uri_params, target_id: target_id} = assigns, socket) do
    filter_form =
      case get_nested(uri_params, [target_id, "filter"]) do
        filter_params when is_map(filter_params) ->
          AshPhoenix.FilterForm.new(resource, params: filter_params)

        _ ->
          nil
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:filter_form, filter_form)}
  end

  @impl true
  def handle_event(
        "clear_filter",
        _filter_params,
        %{assigns: %{to_uri: to_uri, target_id: target_id, uri_params: uri_params}} = socket
      ) do
    component_params = uri_params |> Map.get(target_id, %{}) |> Map.delete("filter")
    uri_params = Map.put(uri_params, target_id, component_params)

    {
      :noreply,
      socket
      |> assign(:filter_form, nil)
      |> push_patch(to: apply(to_uri, [uri_params]), replace: true)
    }
  end

  @impl true
  def handle_event("new_filter", _params, %{assigns: %{filter_form: nil, resource: resource}} = socket) do
    filter_form =
      AshPhoenix.FilterForm.new(resource)

    handle_event(
      "add_predicate",
      %{"id" => filter_form.id},
      assign(socket, :filter_form, filter_form)
    )
  end

  @impl true
  def handle_event(
        "apply_filter",
        %{"filter" => filter_params},
        %{
          assigns: %{
            filter_form: filter_form,
            to_uri: to_uri,
            target_id: target_id,
            uri_params: uri_params,
            resource: resource,
            action: action
          }
        } = socket
      ) do
    case AshPhoenix.FilterForm.validate(filter_form, filter_params) do
      %{valid?: true} = validated_form ->
        case AshPhoenix.FilterForm.filter(Ash.Query.for_read(resource, action), validated_form) do
          {:ok, _} ->
            component_params =
              uri_params
              |> Map.get(target_id, %{})
              |> Map.put("filter", AshPhoenix.FilterForm.params_for_query(validated_form))

            uri_params = Map.put(uri_params, target_id, component_params)

            {
              :noreply,
              socket
              |> assign(:filter_form, validated_form)
              |> push_patch(to: apply(to_uri, [uri_params]), replace: true)
            }

          {:error, error} ->
            {:noreply, assign(socket, :filter_form, error)}
        end

      filter_form ->
        {:noreply, assign(socket, :filter_form, filter_form)}
    end
  end

  @impl true
  def handle_event("remove_predicate", %{"id" => id}, %{assigns: %{filter_form: filter_form}} = socket) do
    filter_form =
      AshPhoenix.FilterForm.remove_predicate(filter_form, id)

    {:noreply, assign(socket, :filter_form, filter_form)}
  end

  @impl true
  def handle_event("remove_group", %{"id" => id}, %{assigns: %{filter_form: filter_form}} = socket) do
    filter_form =
      AshPhoenix.FilterForm.remove_group(filter_form, id)

    {:noreply, assign(socket, :filter_form, filter_form)}
  end

  @impl true
  def handle_event("add_predicate", %{"id" => id}, %{assigns: %{filter_form: filter_form, resource: resource}} = socket) do
    field = default_foreign_label(resource)
    operator = first_predicate_operator(resource, field)

    filter_form =
      AshPhoenix.FilterForm.add_predicate(filter_form, field, operator, nil, to: id)

    # TODO: Figure out how to focus predicate input
    {:noreply, assign(socket, :filter_form, filter_form)}
  end

  @impl true
  def handle_event("add_group", %{"id" => id}, %{assigns: %{filter_form: filter_form}} = socket) do
    {filter_form, group_id} =
      AshPhoenix.FilterForm.add_group(filter_form, to: id, return_id?: true)

    handle_event("add_predicate", %{"id" => group_id}, assign(socket, :filter_form, filter_form))
  end

  @impl true
  def handle_event(
        "set_predicate_path",
        %{"id" => id, "path" => path},
        %{assigns: %{filter_form: filter_form, resource: resource}} = socket
      ) do
    path = path_from_string(path)
    field_resource = AshPyro.Extensions.Resource.Info.resource_by_path(resource, path)
    field = default_foreign_label(field_resource)
    operator = first_predicate_operator(field_resource, field)

    filter_form =
      AshPhoenix.FilterForm.update_predicate(filter_form, id, fn predicate ->
        predicate
        |> Map.put(:path, path)
        |> Map.put(:field, field)
        |> Map.put(:value, "")
        |> Map.put(:operator, operator)
      end)

    {:noreply, assign(socket, :filter_form, filter_form)}
  end

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :form, :any, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true
  attr :actor, :map, required: true
  attr :resource, :atom, required: true
  attr :action, :atom
  attr :tz, :string, required: true
  attr :class, :css_classes, overridable: true
  attr :fieldset_class, :css_classes, overridable: true
  attr :legend_class, :css_classes, overridable: true
  attr :legend_label_class, :css_classes, overridable: true
  attr :button_class, :css_classes, overridable: true
  attr :input_class, :css_classes, overridable: true

  defp render_component(%{form: %{source: %AshPhoenix.FilterForm.Predicate{}}} = assigns), do: render_predicate(assigns)

  defp render_component(%{form: %{source: %AshPhoenix.FilterForm{}}} = assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <fieldset class={@fieldset_class}>
      <legend class={@legend_class}>
        <span class={@legend_label_class}>Group</span>
        <.input
          input_class={@input_class}
          type="select"
          field={@form[:operator]}
          options={group_operator_options()}
        />
        <button
          type="button"
          class={@button_class}
          phx-target={@myself}
          phx-click="remove_group"
          phx-value-id={@form.data.id}
        >
          Remove Group
        </button>
        <button
          type="button"
          class={@button_class}
          phx-target={@myself}
          phx-click="add_predicate"
          phx-value-id={@form.data.id}
        >
          Add Predicate
        </button>
        <button
          type="button"
          class={@button_class}
          phx-target={@myself}
          phx-click="add_group"
          phx-value-id={@form.data.id}
        >
          Add Group
        </button>
      </legend>
      <.input type="hidden" field={@form[:negated?]} />
      <.inputs_for :let={c} field={@form[:components]}>
        <.render_component
          form={c}
          myself={@myself}
          actor={@actor}
          resource={@resource}
          action={@action}
          tz={@tz}
        />
      </.inputs_for>
    </fieldset>
    """
  end

  defp path_options(nil), do: []
  defp path_options([]), do: []

  defp path_options(path) do
    path
    |> Enum.reduce([], fn
      current, [{last_item, last_path} | _rest] = acc ->
        [{current, last_path ++ [last_item]} | acc]

      current, acc ->
        [{current, []} | acc]
    end)
    |> Enum.reverse()
  end

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :form, :any, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true
  attr :actor, :map, required: true
  attr :resource, :atom, required: true
  attr :action, :atom
  attr :tz, :string, required: true
  attr :fieldset_class, :css_classes, overridable: true
  attr :class, :css_classes, overridable: true
  attr :left_fields_class, :css_classes, overridable: true
  attr :button_class, :css_classes, overridable: true
  attr :input_class, :css_classes, overridable: true

  defp render_predicate(assigns) do
    related = Ash.Resource.Info.related(assigns.resource, assigns.form.data.path)
    destination_field = destination_field(related, assigns.form.data.field)

    assigns =
      assigns
      |> assign(:related, related)
      |> assign(:destination_field, destination_field)
      |> assign(
        :is_enum?,
        case destination_field do
          %{type: {:array, type}} ->
            Ash.Helpers.implements_behaviour?(type, Ash.Type.Enum)

          %{type: type} ->
            Ash.Helpers.implements_behaviour?(type, Ash.Type.Enum)

          _ ->
            false
        end
      )
      |> assign_overridables()

    ~H"""
    <div class={@class}>
      <.input type="hidden" field={@form[:path]} />
      <.input type="hidden" field={@form[:negated?]} />
      <div class={@left_fields_class}>
        <button
          :for={{item, path} <- path_options(@form.data.path)}
          class={@button_class}
          type="button"
          phx-target={@myself}
          phx-click="set_predicate_path"
          phx-value-id={@form.data.id}
          phx-value-path={Enum.join(path, ".")}
          title="Change Path"
        >
          <%= humanize_field(item) %>
        </button>
        <.input
          input_class={@input_class}
          field={@form[:field]}
          type="select"
          options={field_options(@resource, @form.data.path, @action, @actor)}
          id={Phoenix.HTML.Form.input_id(@form, :field) <> Enum.join(@form.data.path, ".")}
          value={@form.data.field}
        />
      </div>
      <.input
        input_class={@input_class}
        field={@form[:operator]}
        type="select"
        options={predicate_operator_options(@related, @form.data.field)}
      />
      <.render_right
        form={@form}
        destination_field={@destination_field}
        tz={@tz}
        is_enum?={@is_enum?}
        input_class={@input_class}
      />
      <button
        class={@button_class}
        type="button"
        phx-target={@myself}
        phx-click="remove_predicate"
        phx-value-id={@form.data.id}
        title="Remove Predicate"
      >
        <.icon name="hero-x-circle" />
      </button>
    </div>
    """
  end

  attr :form, :any, required: true
  attr :destination_field, :map, required: true
  attr :is_enum?, :boolean, required: true
  attr :tz, :string, required: true
  attr :input_class, :any, required: true

  def render_right(%{form: %{data: %{operator: :is_nil}}} = assigns) do
    ~H"""
    <.input
      input_class={@input_class}
      field={@form[:value]}
      type="select"
      options={["true", "false"]}
    />
    """
  end

  def render_right(%{destination_field: %Ash.Resource.Aggregate{kind: :count}} = assigns) do
    ~H"""
    <.input input_class={@input_class} field={@form[:value]} inputmode="numeric" pattern="[0-9]*" />
    """
  end

  def render_right(%{destination_field: %Ash.Resource.Aggregate{kind: :sum}} = assigns) do
    ~H"""
    <.input input_class={@input_class} field={@form[:value]} inputmode="decimal" />
    """
  end

  def render_right(%{destination_field: %{type: Ash.Type.Date}} = assigns) do
    ~H"""
    <.input input_class={@input_class} field={@form[:value]} type="date" />
    """
  end

  def render_right(%{destination_field: %{type: Ash.Type.Boolean}} = assigns) do
    ~H"""
    <.input
      input_class={@input_class}
      type="select"
      field={@form[:value]}
      options={["true", "false"]}
    />
    """
  end

  def render_right(%{is_enum?: true, destination_field: %{type: {:array, enum_type}}} = assigns) do
    assigns = assign(assigns, :enum_type, enum_type)

    ~H"""
    <.input
      input_class={@input_class}
      type="select"
      field={@form[:value]}
      options={enum_to_form_options(@enum_type)}
    />
    """
  end

  def render_right(%{is_enum?: true} = assigns) do
    ~H"""
    <.input
      input_class={@input_class}
      type="select"
      field={@form[:value]}
      options={enum_to_form_options(@destination_field.type)}
    />
    """
  end

  def render_right(%{destination_field: %{type: type}} = assigns)
      when type in [Ash.Type.CiString, Ash.Type.String, Ash.Type.UUID] do
    ~H"""
    <.input input_class={@input_class} field={@form[:value]} />
    """
  end

  def render_right(%{destination_field: %{type: Ash.Type.UtcDatetimeUsec}} = assigns) do
    ~H"""
    <.input input_class={@input_class} field={@form[:value]} type="datetime-local" />
    """
  end

  def render_right(%{destination_field: %{type: AshPyroComponents.Type.ZonedDateTime}} = assigns) do
    ~H"""
    <.input input_class={@input_class} field={@form[:value]} type="datetime-zoned" tz={@tz} />
    """
  end

  # def render_right(%{destination_field: %{type: AshPyroComponents.Type.Interval}} = assigns) do
  #   ~H"""
  #   <EctoIntervalInput.ecto_interval_input field={@form[:value]} />
  #   """
  # end

  def render_right(%{destination_field: %{type: Ash.Type.Integer}} = assigns) do
    ~H"""
    <.input input_class={@input_class} field={@form[:value]} inputmode="numeric" pattern="[0-9]*" />
    """
  end

  def render_right(%{destination_field: %{type: Ash.Type.Decimal}} = assigns) do
    ~H"""
    <.input input_class={@input_class} field={@form[:value]} inputmode="decimal" />
    """
  end

  def render_right(assigns) do
    ~H"""
    <div>Not implemented for field: <%= inspect(@destination_field) %></div>
    """
  end

  def path_from_string(path) when is_binary(path),
    do: path |> String.split(".") |> Enum.filter(&(&1 != "")) |> Enum.map(&String.to_existing_atom/1)

  defp field_options(resource, [], action, actor),
    do:
      resource
      |> authorized_public_fields(action, actor)
      |> Enum.map(fn %{name: name} ->
        label = form_field_label(resource, action, name)
        {label, name}
      end)
      |> Enum.sort()

  defp field_options(resource, path, _action, actor) do
    destination = Ash.Resource.Info.related(resource, path)
    action = Ash.Resource.Info.primary_action(destination, :read)

    destination
    |> authorized_public_fields(action, actor)
    |> Enum.map(fn %{name: name} ->
      label = form_field_label(destination, action, name)
      {label, name}
    end)
    |> Enum.sort()
  end

  defp destination_field(resource, field) when is_binary(field),
    do: destination_field(resource, Ash.Resource.Info.field(resource, field))

  defp destination_field(resource, field) when is_atom(field),
    do: destination_field(resource, Ash.Resource.Info.field(resource, field))

  defp destination_field(resource, %{relationship_path: [], field: field}) when not is_nil(field),
    do: destination_field(resource, Ash.Resource.Info.field(resource, field))

  defp destination_field(resource, %{relationship_path: relationship_path, field: field})
       when is_list(relationship_path) and length(relationship_path) > 0 do
    related_resource =
      AshPyro.Extensions.Resource.Info.resource_by_path(resource, relationship_path)

    destination_field(related_resource, field)
  end

  defp destination_field(_resource, field) do
    field
  end

  @doc """
  Get the available predicate operators and functions for the given resource field.
  """
  def predicate_operators(resource, field) when is_binary(field),
    do: predicate_operators(resource, destination_field(resource, field))

  def predicate_operators(resource, field) when is_atom(field),
    do: predicate_operators(resource, destination_field(resource, field))

  def predicate_operators(resource, field) do
    field_type = Ash.Type.storage_type(field.type)

    resource
    |> Ash.DataLayer.functions()
    |> Enum.concat(Ash.Filter.builtin_functions())
    |> Enum.filter(fn function ->
      try do
        # TODO: Can add non-predicate functions after adding render_right support for args.
        struct(function).__predicate__? &&
          Enum.any?(function.args, fn [left_type, _] -> left_type == field_type end)
      rescue
        _ ->
          false
      end
    end)
    |> Enum.concat(
      Enum.filter(Ash.Filter.builtin_predicate_operators(), fn
        # is_nil doesn't make any sense for non-nil fields
        Ash.Query.Operator.IsNil ->
          Map.get(field, :allow_nil?, false)

        operator ->
          case operator.types do
            [:same, :any] ->
              true

            _types ->
              # TODO: Can add more types after lists are supported.
              # Enum.any?(types, fn
              #   _type ->
              #     false
              # end)
              false
          end
      end)
    )
  end

  @doc """
  Get the available predicate operators for the given resource field as select options.
  """
  def predicate_operator_options(resource, field) do
    resource
    |> predicate_operators(field)
    |> Enum.map(fn field ->
      try do
        operator = field.operator()
        name = field.name()

        case operator do
          :is_nil -> {"is null", name}
          operator -> {Atom.to_string(operator), name}
        end
      rescue
        _ ->
          case field.name() do
            name -> {name |> to_string() |> String.replace("_", " "), name}
          end
      end
    end)
  end

  @doc """
  Get the available group operators for filter form groups as select options.
  """
  @group_operators [:and, :or]
  def group_operator_options do
    @group_operators
  end

  defp first_predicate_operator(resource, field) do
    resource
    |> predicate_operators(field)
    |> List.first()
    |> then(& &1.name())
  end

  defp humanize_enum(enum) when is_atom(enum) do
    enum |> Atom.to_string() |> humanize_enum()
  end

  defp humanize_enum(enum) when is_binary(enum) do
    String.replace(enum, "_", " ")
  end

  defp enum_to_form_options(module) do
    Enum.map(apply(module, :values, []), fn e ->
      {humanize_enum(e), Atom.to_string(e)}
    end)
  end

  def default_foreign_label(resource) do
    fields =
      Ash.Resource.Info.public_fields(resource)

    fallback =
      Enum.find(fields, &(&1.name == :label)) || Enum.find(fields, &(&1.name == :name)) ||
        Enum.find(fields, &(&1.name != :id && &1.type == :attribute)) || List.first(fields)

    fallback =
      case fallback do
        nil -> nil
        %{name: name} -> name
      end

    Enum.reduce_while(
      Ash.Resource.Info.identities(resource),
      fallback,
      fn
        %{keys: [key]}, _acc when key != :id -> {:halt, key}
        _identity, acc -> {:cont, acc}
      end
    )
  end

  defp form_field_label(resource, action, field) do
    case AshPyro.Extensions.Resource.Info.form_field(resource, action, field) do
      %{label: label} -> label
      _ -> humanize_field(field)
    end
  end

  defp humanize_field(%{name: name}), do: humanize_field(name)
  defp humanize_field(name) when is_atom(name), do: name |> Atom.to_string() |> humanize_field()

  defp humanize_field(name) when is_binary(name),
    do: name |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)

  defp authorized_public_fields(resource, _action, _actor) do
    # TODO: Actually filter these by authz
    Ash.Resource.Info.public_fields(resource)
  end
end
