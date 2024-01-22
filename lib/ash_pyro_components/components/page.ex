defmodule AshPyroComponents.Components.Page do
  @moduledoc """
  Auto-render a full-featured page for a given resource.
  """

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [connected?: 1, get_connect_params: 1]
  import Pyro.Component.Helpers

  alias Ash.Resource.Info, as: RI
  alias AshPyro.Extensions.Resource.Info, as: PI
  alias AshPyro.Extensions.Resource.LiveView.Page

  @doc """
  Get the timezone from session or connect_params, defaulting to the local timezone.
  """
  @spec get_live_tz(Phoenix.LiveView.Socket.t(), any()) :: any()
  def get_live_tz(socket, session) do
    if connected?(socket) do
      case get_connect_params(socket) do
        %{"timezone" => timezone} -> timezone
        _ -> session["timezone"] || default_timezone()
      end
    else
      session["timezone"] || default_timezone()
    end
  end

  @doc """
  Update the `:now` assign taking the timezone into account.
  """
  @spec handle_tick(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def handle_tick(%{assigns: %{tz: tz}} = socket) when is_binary(tz) do
    assign(socket, :now, local_now(tz))
  end

  def handle_tick(socket) do
    assign(socket, :now, local_now())
  end

  @doc """
  Build a page automatically from AshPyro's `live_view` DSL. It will provide a complete page with all the usual features:

    - url-based state
    - pagination
    - sorting
    - filtering
    - realtime updates via pub-sub
    - forms
    - authorization
    - formatting date/time to user's timezone
    - routes to include in your `router.ex`. 🚀

  ```elixir
  defmodule ExampleWeb.Vendor.CompanyLive do
    use ExampleWeb, :live_view
    use AshPyroComponents.Components.Page,
      resource: Example.Vendor.Company,
      page: :companies
  end
  ```
  """
  defmacro __using__(opts \\ []) do
    resource = Macro.expand(opts[:resource], __CALLER__)

    unless resource do
      raise "resource is required"
    end

    routes =
      opts[:router]
      |> Macro.expand(__CALLER__)
      |> Module.concat(Helpers)

    unless opts[:router] do
      raise "router is required"
    end

    page_name = opts[:page]

    unless page_name && is_atom(page_name) do
      raise "page (name) is required"
    end

    pyro_page = PI.page_for!(resource, page_name)
    list_component_id = "#{pyro_page.name}_list"

    live_view =
      quote do
        import AshPyroComponents.Component
        import Pyro.Component
        import unquote(__MODULE__)

        alias Ash.Resource.Info, as: RI
        alias AshPyro.Extensions.Resource.Info, as: PI
        alias PyroComponents.Components.DataTable

        require Ash.Query

        Module.register_attribute(__MODULE__, :resource, persist: true)
        Module.register_attribute(__MODULE__, :pyro_page, persist: true)
        @resource unquote(resource)
        @pyro_page PI.page_for!(@resource, unquote(page_name))

        @impl true
        def render(var!(assigns)) do
          ~H"""
          <.header>
            <%= @page_title %>
            <:subtitle><%= @page_description %></:subtitle>
          </.header>
          <AshPyroComponents.Components.DataTable.ash_data_table
            id={@list_component_id}
            resource={@resource}
            config={@data_table_config}
            sort={@list_sort}
            display={@list_display}
            filter={@list_filter}
            page={@list_pagination}
            rows={@records}
            actor={@current_user}
            tz={@tz}
          />
          """
        end

        @impl true
        def mount(params, session, socket) do
          timezone =
            if connected?(socket) do
              case get_connect_params(socket) do
                %{"timezone" => timezone} -> timezone
                _ -> session["timezone"] || default_timezone()
              end
            else
              session["timezone"] || default_timezone()
            end

          {:ok,
           socket
           |> assign_new(:tz, fn -> timezone end)
           |> assign_new(:pyro_page, fn -> @pyro_page end)
           |> assign_new(:list_component_id, fn -> unquote(list_component_id) end)
           |> assign_new(:params, fn -> %{unquote(list_component_id) => %{}} end)
           |> assign(:resource, @resource)
           |> assign(:records, [])
           |> handle_action()}
        end

        @impl true
        def handle_params(new_params, _uri, socket) do
          {:noreply,
           socket
           |> validate_sort_params(new_params)
           |> validate_filter_params(new_params)
           |> validate_display_params(new_params)
           |> validate_page_params(new_params)
           |> maybe_patch_params(new_params)}
        end

        @impl true
        def handle_event("reset-list", %{"target-id" => unquote(list_component_id)}, socket) do
          handle_params(%{}, "", assign(socket, :params, %{unquote(list_component_id) => %{}}))
        end

        @impl true
        def handle_event(
              "change-sort",
              %{
                "component-id" => unquote(list_component_id),
                "sort-key" => sort_key,
                "ctrlKey" => ctrl?,
                "shiftKey" => shift?
              },
              socket
            ) do
          component_params =
            get_nested(socket, [:assigns, :params, unquote(list_component_id)], %{})

          sort =
            DataTable.toggle_sort(
              socket.assigns.list_sort,
              sort_key,
              ctrl?,
              shift?
            )

          component_params = Map.put(component_params, "sort", sort)

          params =
            Map.put(socket.assigns.params, unquote(list_component_id), component_params)

          {:noreply,
           socket
           |> assign(:params, params)
           |> maybe_patch_params(socket.assigns.params)}
        end

        @impl true
        def handle_event("change-page-number", %{"target-id" => unquote(list_component_id), "offset" => offset}, socket) do
          component_params =
            get_nested(socket, [:assigns, :params, unquote(list_component_id)], %{})

          component_params = Map.put(component_params, "offset", offset)

          params =
            Map.put(socket.assigns.params, unquote(list_component_id), component_params)

          {:noreply,
           socket
           |> assign(:params, params)
           |> maybe_patch_params(socket.assigns.params)}
        end

        @impl true
        def handle_event(
              "change-page-limit",
              %{"pagination_form" => %{"target-id" => unquote(list_component_id), "limit" => limit}},
              socket
            ) do
          component_params =
            get_nested(socket, [:assigns, :params, unquote(list_component_id)], %{})

          component_params =
            Map.put(component_params, "limit", "#{limit}")

          params =
            Map.put(socket.assigns.params, unquote(list_component_id), component_params)

          {:noreply,
           socket
           |> assign(:params, params)
           |> maybe_patch_params(socket.assigns.params)}
        end

        defp validate_sort_params(socket, params) do
          stored_component_params =
            get_nested(socket, [:assigns, :params, unquote(list_component_id)], %{})

          sort_params =
            Map.get(
              get_nested(params, [unquote(list_component_id)], %{}),
              "sort",
              socket.assigns.data_table_config.default_sort
            )

          case Ash.Sort.parse_input(unquote(resource), sort_params) do
            {:ok, sort} ->
              params =
                Map.put(
                  socket.assigns.params,
                  unquote(list_component_id),
                  Map.put(
                    stored_component_params,
                    "sort",
                    PyroComponents.Components.DataTable.encode_sort(sort_params)
                  )
                )

              socket
              |> assign(:params, params)
              |> assign(:list_sort, sort)

            _ ->
              list_sort =
                Ash.Sort.parse_input!(
                  unquote(resource),
                  socket.assigns.data_table_config.default_sort
                )

              params =
                Map.put(
                  socket.assigns.params,
                  unquote(list_component_id),
                  PyroComponents.Components.DataTable.encode_sort(list_sort)
                )

              socket
              |> assign(:params, params)
              |> assign(:list_sort, list_sort)
          end
        end

        # TODO:Actually validate filter params
        defp validate_filter_params(socket, _params), do: assign(socket, :list_filter, [])

        defp validate_display_params(socket, params) do
          stored_component_params =
            get_nested(socket, [:assigns, :params, unquote(list_component_id)], %{})

          display_params =
            get_nested(params, [unquote(list_component_id), "display"], "")

          display_fields = String.split(display_params, ",", trim: true)

          sorts =
            Enum.map(Map.get(socket.assigns, :list_sort, []) || [], fn {key, _} ->
              Atom.to_string(key)
            end)

          # Ensure all applied sorts are visible
          missing_sorts = sorts -- display_fields
          display_fields = Enum.concat(missing_sorts, display_fields)
          display_params = Enum.join(display_fields, ",")

          known_fields =
            Enum.map(socket.assigns.data_table_config.columns, &Atom.to_string(&1.name))

          if length(display_fields) > 0 && Enum.all?(display_fields, &(&1 in known_fields)) do
            params =
              Map.put(
                socket.assigns.params,
                unquote(list_component_id),
                Map.put(stored_component_params, "display", display_params)
              )

            socket
            |> assign(:params, params)
            |> assign(:list_display, Enum.map(display_fields, &String.to_existing_atom/1))
          else
            list_display = socket.assigns.data_table_config.default_display

            params =
              Map.put(
                socket.assigns.params,
                unquote(list_component_id),
                Map.put(
                  stored_component_params,
                  "display",
                  PyroComponents.Components.DataTable.encode_display(list_display)
                )
              )

            socket
            |> assign(:params, params)
            |> assign(:list_display, list_display)
          end
        end

        defp validate_page_params(
               %{assigns: %{live_action_config: %Page.List{pagination: :offset, default_limit: default_limit}}} = socket,
               params
             ) do
          stored_component_params =
            get_nested(socket, [:assigns, :params, unquote(list_component_id)], %{})

          offset =
            case Integer.parse(get_nested(params, [unquote(list_component_id), "offset"], "0")) do
              {value, _} -> value
              _ -> 0
            end

          limit =
            case Integer.parse(get_nested(params, [unquote(list_component_id), "limit"], "")) do
              {value, _} -> value
              _ -> default_limit
            end

          params =
            Map.put(
              socket.assigns.params,
              unquote(list_component_id),
              stored_component_params
              |> Map.drop(["after", "before"])
              |> Map.put("offset", Integer.to_string(offset))
              |> Map.put("limit", Integer.to_string(limit))
            )

          socket
          |> assign(:params, params)
          |> assign(:list_pagination, %{offset: offset, limit: limit})
        end

        defp validate_page_params(socket, _params) do
          stored_component_params =
            get_nested(socket, [:assigns, :params, unquote(list_component_id)], %{})

          params =
            Map.put(
              socket.assigns.params,
              unquote(list_component_id),
              Map.drop(stored_component_params, ["limit", "offset", "after", "before"])
            )

          socket
          |> assign(:params, params)
          |> assign(:list_pagination, nil)
        end

        defp maybe_patch_params(%{assigns: %{params: valid_params}} = socket, params) when valid_params == params do
          {attributes, fields} =
            socket.assigns.data_table_config.columns
            |> Enum.filter(&(&1.name in socket.assigns.list_display))
            |> Enum.split_with(&(&1.resource_field_type == :attribute))

          query =
            unquote(resource)
            |> Ash.Query.sort(socket.assigns.list_sort)
            |> Ash.Query.select(Enum.map(attributes, & &1.name))
            |> Ash.Query.load(Enum.map(fields, & &1.name))

          page =
            case socket.assigns.list_pagination do
              %{} = page ->
                page
                |> Keyword.new()
                |> Keyword.put(:count, socket.assigns.live_action_config.count?)

              _ ->
                nil
            end

          case apply(unquote(pyro_page.api), :read!, [
                 query,
                 [
                   actor: socket.assigns.current_user,
                   action: socket.assigns.list_action,
                   page: page || nil
                 ]
               ]) do
            %{results: records, count: count, more?: more?} ->
              socket
              |> assign(
                :records,
                records
              )
              |> assign(
                :list_pagination,
                socket.assigns.list_pagination
                |> Map.put(:count, count)
                |> Map.put(:more?, more?)
              )

            records ->
              assign(
                socket,
                :records,
                records
              )
          end
        end

        defp maybe_patch_params(%{assigns: %{params: valid_params, live_action: live_action}} = socket, _params),
          do: push_patch(socket, to: route_for(socket, live_action, valid_params), replace: true)
      end

    handle_action =
      Enum.map(pyro_page.live_actions, &build_handle_action(&1, pyro_page, routes))

    route_helper_header =
      quote do
        @doc false
        defp route_for(socket, live_action, params \\ %{})
      end

    route_helpers =
      Enum.map(pyro_page.live_actions, &build_route_helpers(&1, pyro_page, routes))

    [live_view, handle_action, route_helper_header, route_helpers]
  end

  defp build_handle_action(
         %Page.List{live_action: live_action, label: label, action: action, description: description},
         %Page{view_as: :list_and_modal, route_helper: route_helper},
         routes
       ) do
    quote do
      @doc false
      defp handle_action(%{assigns: %{live_action: unquote(live_action), current_user: actor}} = socket) do
        socket
        |> assign(:data_table_config, PI.data_table_for!(@resource, unquote(action)))
        |> assign(
          :live_action_config,
          Enum.find(
            socket.assigns.pyro_page.live_actions,
            &(&1.live_action == unquote(live_action))
          )
        )
        |> assign(
          :return_to,
          apply(unquote(routes), unquote(route_helper), [socket, unquote(live_action)])
        )
        |> assign(:list_action, unquote(action))
        |> assign(:page_title, unquote(label))
        |> assign(:page_description, unquote(description))
      end
    end
  end

  defp build_handle_action(_, _, _), do: :noop

  defp build_route_helpers(
         %Page.List{live_action: live_action},
         %Page{view_as: :list_and_modal, route_helper: route_helper},
         routes
       ) do
    quote do
      defp route_for(socket, unquote(live_action), params) do
        apply(unquote(routes), unquote(route_helper), [socket, unquote(live_action), params])
      end
    end
  end

  defp build_route_helpers(_, _, _), do: :noop
end
