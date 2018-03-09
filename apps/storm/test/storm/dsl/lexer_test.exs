defmodule Storm.DSL.LexerTest do
  use ExUnit.Case, async: true

  alias Storm.DSL.Lexer

  @reserved_words [
    :push, :think, :do, :end, :for, :in, :true, :false, :null
  ]

  @symbols [
    :"{", :"}", :"[", :"]", :":", :",", :"=", :".."
  ]

  describe "whitespaces" do
    test "skips spaces" do
      assert Lexer.tokenize("    ") == {:ok, []}
    end

    test "skips tabs" do
      assert Lexer.tokenize("			") == {:ok, []}
    end

    test "new lines" do
      assert Lexer.tokenize("\n") == {:ok, []}
    end

    test "multiple new lines" do
      assert Lexer.tokenize("\n\n\n") == {:ok, []}
    end

    test "new lines (heredoc)" do
      heredoc = """


      """

      assert Lexer.tokenize(heredoc) == {:ok, []}
    end
  end

  describe "numbers" do
    test "positive integer" do
      assert Lexer.tokenize("42") == {:ok, [{:int, 1, 42}]}
    end

    test "negative integer" do
      assert Lexer.tokenize("-42") == {:ok, [{:int, 1, -42}]}
    end

    test "positive float" do
      assert Lexer.tokenize("42.7") == {:ok, [{:float, 1, 42.7}]}
    end

    test "negative float" do
      assert Lexer.tokenize("-42.7") == {:ok, [{:float, 1, -42.7}]}
    end

    test "float needs integer number" do
      assert Lexer.tokenize(".7") == {:error, {"illegal character: '.7'", 1}}
    end

    test "float needs decimal number" do
      assert Lexer.tokenize("-42.") == {:error, {"illegal character: '.'", 1}}
    end
  end

  describe "strings" do
    test "double quoted string" do
      assert Lexer.tokenize(to_string('"foo"')) == {:ok, [{:string, 1, "foo"}]}
    end
  end

  describe "reserved words" do
    Enum.each @reserved_words, fn word ->
      test "#{word} is special identifier" do
        assert Lexer.tokenize(Atom.to_string(unquote(word))) == {:ok, [{unquote(word), 1}]}
      end
    end
  end

  describe "symbols" do
    Enum.each @symbols, fn symbol ->
      test "#{symbol} is special character" do
        assert Lexer.tokenize(Atom.to_string(unquote(symbol))) == {:ok, [{unquote(symbol), 1}]}
      end
    end
  end

  describe "words" do
    test "lowercase words are identifiers" do
      assert Lexer.tokenize("foo") == {:ok, [{:identifier, 1, "foo"}]}
    end

    test "identifiers can have underscores" do
      assert Lexer.tokenize("foo_bar") == {:ok, [{:identifier, 1, "foo_bar"}]}
    end

    test "uppercase words are syntax error" do
      assert Lexer.tokenize("Foo") == {:error, {"illegal character: 'F'", 1}}
    end
  end
end
