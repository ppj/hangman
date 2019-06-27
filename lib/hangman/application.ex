defmodule Hangman.Application do
  use Application

  # TODO: Upgrade to use a DynamicSupervisor
  def start(_type, _args) do
    children = [
      { DynamicSupervisor, strategy: :one_for_one, name: Hangman.DynamicSupervisor }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
