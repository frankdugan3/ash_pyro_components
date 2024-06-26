defmodule AshPyroComponentsExample.Vendor.Employee do
  @moduledoc false
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPyro.Extensions.Resource],
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub],
    domain: AshPyroComponentsExample.Vendor

  pyro do
    live_view do
      page "/employees", :employees do
        keep_live? true

        list "/", :index, :read do
          label "Employee Directory"
        end

        create "/create", :new, :create
        update "/edit", :edit, :update
        show "/", :show, :read
      end
    end

    data_table do
      action :read do
        default_sort [:employer_name, :position, :name]
        exclude [:employer, :id, :employer_id]
        column :employer_name, label: "Employer"
        column :position
        column :name

        column :hired
      end
    end

    form do
      action_type [:create, :update] do
        field :name do
          autofocus true
        end

        field :position
        field :hired
        field :employer do
          type :autocomplete
          autocomplete_option_label_key :name
        end
      end
    end
  end

  postgres do
    table "vendor_employees"
    repo AshPyroComponentsExample.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :ci_string, allow_nil?: false, public?: true
    attribute :position, :ci_string, public?: true
    attribute :hired, AshPyroComponents.Type.ZonedDateTime, allow_nil?: false, public?: true
  end

  identities do
    identity :unique_name, [:name]
  end

  relationships do
    belongs_to :employer, AshPyroComponentsExample.Vendor.Company, allow_nil?: false, public?: true
  end

  aggregates do
    first :employer_name, :employer, :name, public?: true
  end

  actions do
    default_accept [:name, :position, :hired]
    defaults [:destroy]

    read :read do
      primary? true
      pagination do
        countable true
        max_page_size 100
        required? true
        offset? true
      end
      prepare build(load: [:employer])
    end

    create :create do
      argument :employer, :map, allow_nil?: false

      change manage_relationship(:employer,
               type: :append_and_remove,
               use_identities: [:_primary_key, :unique_name]
             )
    end

    update :update do
      require_atomic? false
      argument :employer, :map, allow_nil?: false

      change manage_relationship(:employer,
               type: :append_and_remove,
               use_identities: [:_primary_key, :unique_name]
             )
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end
end
