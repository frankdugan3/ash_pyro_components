defmodule AshPyroComponentsExample.Vendor.Company do
  @moduledoc false
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPyro.Extensions.Resource],
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub],
    domain: AshPyroComponentsExample.Vendor

  import Phoenix.Component, only: [sigil_H: 2]

  require Phoenix.Component

  pyro do
    live_view do
      page "/companies", :companies do
        keep_live? true

        list "/", :index, :read do
          label :inherit
          description :inherit
        end

        list "/sequel", :sequel, :read
        list "/more", :list, :read

        show "/", :show, :read
        create "/create", :new, :create
        update "/edit", :edit, :update
      end
    end

    data_table do
      action :read do
        label "Du Hast"
        description "Du Hasst Mich"
        exclude [:id, :employees]

        column :name

        column :code do
          cell_class "whitespace-nowrap"

          render_cell fn assigns ->
            ~H"""
            <%= Map.get(@row, @col[:name]) %>
            <PyroComponents.Components.Core.icon name="hero-rocket-launch-micro" />
            """
          end
        end

        column :description
      end
    end

    form do
      action_type [:create, :update] do
        field :name do
          autofocus true
        end

        field :code

        field :description do
          type :long_text
        end
      end
    end
  end

  postgres do
    table "vendor_companies"
    repo AshPyroComponentsExample.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :ci_string, public?: true
    attribute :code, :ci_string, public?: true
    attribute :description, :ci_string, public?: true
  end

  identities do
    identity :unique_name, [:name]
    identity :unique_code, [:code]
  end

  relationships do
    has_many :employees, AshPyroComponentsExample.Vendor.Employee, destination_attribute: :employer_id, public?: true
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end
end
