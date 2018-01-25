defmodule Hangman.GameTest do
  use ExUnit.Case

  alias Hangman.Game

  describe "new_game/0" do
    test "returns structure" do
      game = Game.new_game()

      assert game.turns_left == 7
      assert game.state == :initializing
      assert length(game.letters) > 0
    end

    test "provides a word with all lower case letters" do
      word = Game.new_game()
             |> Map.get(:letters)
             |> Enum.join

      assert word == word |> String.downcase
    end

    test "state doesn't change when the game has been won or lost already" do
      for state <- [:won, :lost] do
        game = Game.new_game() |> Map.put(:state, state)
        assert ^game = Game.make_move(game, "x")
      end
    end
  end

  describe "make_move/2" do
    test "does not accept anything apart from a single, lowercase, ascii character as a guess" do
      game = Game.new_game()

      # a capital ascii character
      game = Game.make_move(game, "A")
      assert game.state == :invalid_guess
      assert game.turns_left == 7

      # a non-ascii character
      game = Game.make_move(game, "ó")
      assert game.state == :invalid_guess
      assert game.turns_left == 7

      # a string of more than one characters
      game = Game.make_move(game, "a string")
      assert game.state == :invalid_guess
      assert game.turns_left == 7

      # a charlist of one character
      game = Game.make_move(game, 'a')
      assert game.state == :invalid_guess
      assert game.turns_left == 7

      # a charlist of more than one character
      game = Game.make_move(game, 'abc')
      assert game.state == :invalid_guess
      assert game.turns_left == 7

      # a number
      game = Game.make_move(game, 321)
      assert game.state == :invalid_guess
      assert game.turns_left == 7

      # a list of strings
      game = Game.make_move(game, ["this", "is", "not", "acceptable"])
      assert game.state == :invalid_guess
      assert game.turns_left == 7
    end

    test "first time guess is accepted" do
      game = Game.new_game()

      game = Game.make_move(game, "x")
      assert game.state != :already_used
    end

    test "second time guess is not accepted" do
      game = Game.new_game()

      game = Game.make_move(game, "x")
      assert game.state != :already_used
      game = Game.make_move(game, "x")
      assert game.state == :already_used
    end

    test "sets game state to :good_guess when the guess is good but all letters have not been guessed yet" do
      game = Game.new_game("lorem")

      game = Game.make_move(game, "o")
      assert game.state == :good_guess
      assert game.turns_left == 7
    end

    test "sets game state to :won when all letters have been guessed correctly" do
      game = Game.new_game("steeple")

      [
        {"s", :good_guess},
        {"t", :good_guess},
        {"e", :good_guess},
        {"p", :good_guess},
        {"l", :won},
      ] |> Enum.reduce(game, fn({guess, state}, tracker_game) ->
        tracker_game = Game.make_move(tracker_game, guess)
        assert tracker_game.state == state
        assert tracker_game.turns_left == 7
        tracker_game
      end)
    end

    test "sets game state to :bad_guess for a bad guess when there are still turns remaining" do
      game = Game.new_game("steeple")

      game = Game.make_move(game, "x")
      assert game.state == :bad_guess
    end

    test "reduces remaining turns for a bad guess when there are still turns remaining" do
      game = Game.new_game("steeple")

      assert game.turns_left == 7
      game = Game.make_move(game, "x")
      assert game.turns_left == 6
    end

    test "sets game state to :lost for a bad guess on the last remaining turn" do
      game = Game.new_game("a")

      [
        {"t", :bad_guess, 6},
        {"u", :bad_guess, 5},
        {"v", :bad_guess, 4},
        {"w", :bad_guess, 3},
        {"x", :bad_guess, 2},
        {"y", :bad_guess, 1},
        {"z", :lost, 0},
      ] |> Enum.reduce(game, fn({guess, state, turns_left}, tracker_game) ->
        tracker_game = Game.make_move(tracker_game, guess)
        assert tracker_game.state == state
        assert tracker_game.turns_left == turns_left
        tracker_game
      end)
    end
  end
end
