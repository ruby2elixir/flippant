for adapter <- [Flippant.Adapter.Memory, Flippant.Adapter.Redis] do
  defmodule Module.concat(adapter, Test) do
    use ExUnit.Case

    @adapter adapter
    @moduletag adapter: adapter

    setup_all do
      Logger.configure level: :warn

      Application.stop(:flippant)
      Application.put_env(:flippant, :adapter, @adapter)
      Application.ensure_started(:flippant)

      :ok
    end

    setup do
      Flippant.reset

      :ok
    end

    test "add/1 adds to the list of known features" do
      Flippant.add("search")
      Flippant.add("search")
      Flippant.add("delete")

      assert Flippant.features == ["delete", "search"]
    end

    test "reset/0 removes all known features" do
      Flippant.add("search")
      Flippant.add("delete")
      Flippant.register("awesome", fn(_, _) -> true end)

      Flippant.reset

      assert Flippant.features == []
      assert Flippant.registered == %{}
    end

    test "remove/1 removes a specific feature" do
      Flippant.add("search")
      Flippant.add("delete")
      Flippant.remove("search")

      assert Flippant.features == ["delete"]
    end

    test "enable/3 adds a feature rule for a group" do
      Flippant.enable("search", "staff", true)
      Flippant.enable("search", "users", false)
      Flippant.enable("delete", "staff")

      assert Flippant.features == ["delete", "search"]
      assert Flippant.features("staff") == ["delete", "search"]
      assert Flippant.features("users") == ["search"]
    end

    test "disable/2 disables a feature for a group" do
      Flippant.enable("search", "staff", true)
      Flippant.enable("search", "users", false)

      Flippant.disable("search", "users")

      assert Flippant.features == ["search"]
      assert Flippant.features("staff") == ["search"]
      assert Flippant.features("users") == []
    end

    test "enabled?/2 checks a feature for an actor" do
      Flippant.register("staff", fn(actor, _values) -> actor.staff? end)

      actor_a = %{id: 1, staff?: true}
      actor_b = %{id: 2, staff?: false}

      refute Flippant.enabled?("search", actor_a)
      refute Flippant.enabled?("search", actor_b)

      Flippant.enable("search", "staff")

      assert Flippant.enabled?("search", actor_a)
      refute Flippant.enabled?("search", actor_b)
    end

    test "enabled?/2 checks for a feature against multiple groups" do
      Flippant.register("awesome", fn(actor, _) -> actor.awesome? end)
      Flippant.register("radical", fn(actor, _) -> actor.radical? end)

      actor_a = %{id: 1, awesome?: true, radical?: false}
      actor_b = %{id: 2, awesome?: false, radical?: true}
      actor_c = %{id: 3, awesome?: false, radical?: false}

      Flippant.enable("search", "awesome")
      Flippant.enable("search", "radical")

      assert Flippant.enabled?("search", actor_a)
      assert Flippant.enabled?("search", actor_b)
      refute Flippant.enabled?("search", actor_c)
    end

    test "enabled?/2 uses rule values when checking" do
      Flippant.register("awesome", fn(actor, ids) -> actor.id in ids end)

      actor_a = %{id: 1}
      actor_b = %{id: 5}

      Flippant.enable("search", "awesome", [1, 2, 3])

      assert Flippant.enabled?("search", actor_a)
      refute Flippant.enabled?("search", actor_b)
    end

    test "breakdown/1 lists all enabled features for an actor" do
      Flippant.register("awesome", fn(actor, _) -> actor.awesome? end)
      Flippant.register("radical", fn(actor, _) -> actor.radical? end)
      Flippant.register("heinous", fn(actor, _) -> !actor.awesome? end)

      actor = %{id: 1, awesome?: true, radical?: true}

      Flippant.enable("search", "awesome")
      Flippant.enable("search", "heinous")
      Flippant.enable("delete", "radical")
      Flippant.enable("invite", "heinous")

      assert Flippant.breakdown(actor) == %{
        "search" => true,
        "delete" => true,
        "invite" => false
      }
    end
  end
end
