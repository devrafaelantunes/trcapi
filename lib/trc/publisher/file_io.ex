defmodule Trc.Publisher.FileIO do
  @moduledoc false

  # Typespecs
  @type path :: String.t()
  @type opts :: [chunk_size: integer()]

  @default_chunk_size 2048

  @doc """
    Streams a file based on the chunk_size
  """
  @callback get_stream(path(), opts()) :: File.Stream.t()
  @spec get_stream(path(), opts()) :: File.Stream.t()
  def get_stream(path, opts) do
    chunk_size = Keyword.get(opts, :chunk_size, @default_chunk_size)
    File.stream!(path, [encoding: :utf8], chunk_size)
  end
end
