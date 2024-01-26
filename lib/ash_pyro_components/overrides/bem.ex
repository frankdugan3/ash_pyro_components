defmodule AshPyroComponents.Overrides.BEM do
  @moduledoc """
    This overrides file complements `PyroComponents.Overrides.BEM` by adding [BEM](https://getbem.com/) classes to all AshPyro components. It does not define any style.

    This is great if you want to fully customize your own styles; all you have to do is define the classes in your CSS file.

    ## Configuration

    As with any Pyro overrides, you need to include the correct override files in your `config.exs` file:

    ```elixir
    config :pyro, :overrides, [AshPyroComponents.Overrides.BEM, PyroComponents.Overrides.BEM]
    ```
  """

  ##############################################################################
  ####    S T Y L E    S E T T I N G S
  ##############################################################################

  use Pyro.Overrides

  @prefix Application.compile_env(:pyro_components, :bem_prefix, "pyro_")

  ##############################################################################
  ####    A S H    C O M P O N E N T S
  ##############################################################################

  @prefixed_ash_data_table @prefix <> "ash_data_table"
  override AshPyroComponents.Components.DataTable, :ash_data_table do
    set :class, &__MODULE__.ash_data_table_class/1
  end

  def ash_data_table_class(passed_assigns) do
    [@prefixed_ash_data_table, get_nested(passed_assigns, [:pyro_data_table, :class])]
  end

  @prefixed_ash_form @prefix <> "ash_form"
  override AshPyroComponents.Components.Form, :ash_form do
    set :class, &__MODULE__.ash_form_class/1
    set :actions_class, @prefixed_ash_form <> "__actions"
    set :autocomplete, "off"
  end

  def ash_form_class(passed_assigns) do
    [@prefixed_ash_form, get_nested(passed_assigns, [:pyro_form, :class])]
  end

  @prefixed_ash_form_render_field @prefix <> "ash_form_render_field"
  override AshPyroComponents.Components.Form, :render_field do
    set :field_group_class, &__MODULE__.ash_form_field_group_class/1
    set :field_group_label_class, @prefixed_ash_form_render_field <> "__group_label"
  end

  def ash_form_field_group_class(passed_assigns) do
    [
      @prefixed_ash_form_render_field <> "__group",
      get_nested(passed_assigns, [:field, :class])
    ]
  end

  @prefixed_ash_filter_form_render @prefix <> "ash_filter_form"
  override AshPyroComponents.Components.FilterForm, :render do
    set :class, @prefixed_ash_filter_form_render
    set :form_class, @prefixed_ash_filter_form_render <> "__form"
    set :fieldset_class, @prefixed_ash_filter_form_render <> "__fieldset"
    set :legend_class, @prefixed_ash_filter_form_render <> "__legend"
    set :legend_label_class, @prefixed_ash_filter_form_render <> "__legend_label"
    set :button_class, @prefixed_ash_filter_form_render <> "__button"
    set :input_class, @prefixed_ash_filter_form_render <> "__input"
  end

  override AshPyroComponents.Components.FilterForm, :render_component do
    set :fieldset_class, @prefixed_ash_filter_form_render <> "__fieldset"
    set :legend_class, @prefixed_ash_filter_form_render <> "__legend"
    set :legend_label_class, @prefixed_ash_filter_form_render <> "__legend_label"
    set :button_class, @prefixed_ash_filter_form_render <> "__button"
    set :input_class, @prefixed_ash_filter_form_render <> "__input"
  end

  override AshPyroComponents.Components.FilterForm, :render_predicate do
    set :class, @prefixed_ash_filter_form_render <> "__predicate"
    set :left_fields_class, @prefixed_ash_filter_form_render <> "__predicate_left_fields"
    set :button_class, @prefixed_ash_filter_form_render <> "__button"
    set :input_class, @prefixed_ash_filter_form_render <> "__input"
  end
end
