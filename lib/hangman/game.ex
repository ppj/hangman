defmodule Hangman.Game do
  defstruct(
    turns_left: 7,
    state: :initializing,
    letters: [],
    used: MapSet.new()
  )

  def new_game(word \\ Dictionary.random_word()) do
    %Hangman.Game{
      letters: word |> String.codepoints()
    }
  end

  def make_move(game = %{state: state}, _guess) when state in [:won, :lost] do
    game
    |> return_with_tally()
  end

  def make_move(game, guess) do
    process_move(game, guess, MapSet.member?(game.used, guess))
    |> return_with_tally()
  end

  def tally(game) do
    %{
      state: game.state,
      turns_left: game.turns_left,
      letters: game.letters |> reveal_guessed(game.used),
      used: game.used
    }
  end

  defp reveal_guessed(letters, used) do
    letters
    |> Enum.map(fn letter -> reveal_letter(letter, MapSet.member?(used, letter)) end)
  end

  defp reveal_letter(letter, _in_word = true), do: letter
  defp reveal_letter(_letter, _not_in_word), do: "_"

  defmacrop is_lowercase_ascii(char) do
    quote do
      unquote(char) in 97..122
    end
  end

  defp process_move(game, _guess, _already_guessed = true) do
    Map.put(game, :state, :already_used)
  end

  defp process_move(game, guess = <<char>>, _not_already_guessed) when is_lowercase_ascii(char) do
    Map.put(game, :used, MapSet.put(game.used, guess))
    |> score_guess(Enum.member?(game.letters, guess))
  end

  defp process_move(game, _invalid_guess, _) do
    Map.put(game, :state, :invalid_guess)
  end

  defp score_guess(game, _good_guess = true) do
    new_state =
      MapSet.new(game.letters)
      |> MapSet.subset?(game.used)
      |> maybe_won()

    Map.put(game, :state, new_state)
  end

  defp score_guess(game = %{turns_left: 1}, _bad_guess) do
    %{
      game
      | state: :lost,
        turns_left: 0
    }
  end

  defp score_guess(game = %{turns_left: turns_left}, _bad_guess) do
    %{
      game
      | state: :bad_guess,
        turns_left: turns_left - 1
    }
  end

  defp maybe_won(true), do: :won
  defp maybe_won(_), do: :good_guess

  defp return_with_tally(game), do: { game, tally(game) }
end
