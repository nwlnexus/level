defmodule LevelWeb.Schema.Types do
  @moduledoc false

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias Level.Groups
  alias Level.Spaces
  alias LevelWeb.Endpoint
  alias LevelWeb.Router.Helpers

  import_types LevelWeb.Schema.Enums
  import_types LevelWeb.Schema.Scalars
  import_types LevelWeb.Schema.InputObjects
  import_types LevelWeb.Schema.Connections
  import_types LevelWeb.Schema.Mutations

  @desc "A user represents a person belonging to a specific space."
  object :user do
    field :id, non_null(:id)
    field :state, non_null(:user_state)
    field :email, non_null(:string)
    field :first_name, :string
    field :last_name, :string
    field :time_zone, :string
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :space_memberships, non_null(:space_membership_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :space_order
      resolve &Level.Connections.space_memberships/3
    end

    field :group_memberships, non_null(:group_membership_connection) do
      arg :space_id, non_null(:id)
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :group_order
      resolve &Level.Connections.group_memberships/3
    end
  end

  @desc "A space membership defines the relationship between a user and a space."
  object :space_membership do
    field :state, non_null(:space_user_state)
    field :role, non_null(:space_user_role)
    field :space, non_null(:space), resolve: dataloader(:db)

    field :bookmarked_groups, list_of(:group) do
      resolve fn space_user, _args, _context ->
        {:ok, Groups.list_bookmarked_groups(space_user)}
      end
    end
  end

  @desc "A space represents a company or organization."
  object :space do
    field :id, non_null(:id)
    field :state, non_null(:space_state)
    field :name, non_null(:string)
    field :slug, non_null(:string)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)

    field :setup_state, non_null(:space_setup_state) do
      resolve fn space, _args, _context ->
        Spaces.get_setup_state(space)
      end
    end

    @desc "The currently active open invitation URL for the space"
    field :open_invitation_url, :string do
      resolve fn space, _args, _context ->
        case Spaces.get_open_invitation(space) do
          {:ok, invitation} ->
            {:ok, Helpers.open_invitation_url(Endpoint, :show, invitation.token)}

          :revoked ->
            {:ok, nil}
        end
      end
    end

    field :groups, non_null(:group_connection) do
      arg :first, :integer
      arg :last, :integer
      arg :before, :cursor
      arg :after, :cursor
      arg :order_by, :group_order
      arg :state, :group_state
      resolve &Level.Connections.groups/3
    end
  end

  @desc "A group is a collection of users within a space."
  object :group do
    field :id, non_null(:id)
    field :state, non_null(:group_state)
    field :name, non_null(:string)
    field :description, :string
    field :is_private, non_null(:boolean)
    field :inserted_at, non_null(:time)
    field :updated_at, non_null(:time)
    field :space, non_null(:space), resolve: dataloader(:db)
    field :creator, non_null(:user), resolve: dataloader(:db)
  end

  @desc "A group membership defines the relationship between a user and group."
  object :group_membership do
    field :group, non_null(:group), resolve: dataloader(:db)
  end

  @desc "A post represents a conversation."
  object :post do
    field :id, non_null(:id)
    field :state, non_null(:post_state)
    field :body, non_null(:string)
    field :space, non_null(:space), resolve: dataloader(:db)
    field :user, non_null(:user), resolve: dataloader(:db)
  end
end
