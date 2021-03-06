defmodule Arbit.Display.Coinbasebitbns do
  @moduledoc """
    This module is responsible for
    defining the model schema and
    computing arbitrage between Coinbase & BitBnS
  """

  use Ecto.Schema
  alias Arbit.Track
  alias __MODULE__

  schema "coinbasebitbns" do
    field :coin,             :string
    field :coinbase_quote,   :string
    field :bitbns_quote,     :string
    field :coinbase_price,   :float
    field :bitbns_bid_price, :float
    field :bitbns_ask_price, :float
    field :bid_difference,   :float
    field :ask_difference,   :float
    field :bitbns_volume,    :float

    timestamps()
  end

  @doc """
  Compute arbitrage between Coinbase & Bitbns
  & return a list of %Coinbasebitbns{} structs
  """
  def compute_arbitrage do
    compute_arbitrage_usd_inr() ++ compute_arbitrage_usdc_inr()
  end

  @doc """
  Compute arbitrage between Coinbase USD coins & Bitbns INR coins
  and return a list of %Coinbasebitbns{} structs
  """
  def compute_arbitrage_usd_inr() do
    # Get Coinbase & Bitbns portfolios
    coinbase_portfolio = Track.list_coinbase()
    bitbns_portfolio   = Track.list_bitbns()

    # Filter in the coins belonging to the relevant market
    coinbase_portfolio = filter_market(coinbase_portfolio, "USD")
    bitbns_portfolio   = filter_market(bitbns_portfolio,   "INR")

    # Filter in common coins in the two portfolios
    coinbase_portfolio = filter_common_coins(coinbase_portfolio, bitbns_portfolio)
    bitbns_portfolio   = filter_common_coins(bitbns_portfolio, coinbase_portfolio)

    # Sort each portfolio by coin name
    coinbase_portfolio = Enum.sort_by(coinbase_portfolio, &(&1.coin))
    bitbns_portfolio   = Enum.sort_by(bitbns_portfolio,   &(&1.coin))

    # Zip the two portfolios
    zipped_portfolios = Enum.zip(coinbase_portfolio, bitbns_portfolio)

    # Create %Coinbasebitbns{} struct with difference %
    Enum.map(zipped_portfolios, & create_coinbasebitbns_struct(&1))
  end

  @doc """
  Compute arbitrage between Coinbase USDC coins & Bitbns INR coins
  and return a list of %Coinbasebitbns{} structs
  """
  def compute_arbitrage_usdc_inr() do
    # Get Coinbase & Bitbns portfolios
    coinbase_portfolio = Track.list_coinbase()
    bitbns_portfolio   = Track.list_bitbns()

    # Filter in the coins belonging to the relevant market
    coinbase_portfolio = filter_market(coinbase_portfolio, "USDC")
    bitbns_portfolio   = filter_market(bitbns_portfolio, "INR")

    # Filter in common coins in the two portfolios
    coinbase_portfolio = filter_common_coins(coinbase_portfolio, bitbns_portfolio)
    bitbns_portfolio   = filter_common_coins(bitbns_portfolio, coinbase_portfolio)

    # Sort each portfolio by coin name
    coinbase_portfolio = Enum.sort_by(coinbase_portfolio, &(&1.coin))
    bitbns_portfolio   = Enum.sort_by(bitbns_portfolio,   &(&1.coin))

    # Zip the two portfolios
    zipped_portfolios = Enum.zip(coinbase_portfolio, bitbns_portfolio)

    # Create %Coinbasebitbns{} struct with difference %
    Enum.map(zipped_portfolios, & create_coinbasebitbns_struct(&1))
  end

  #-------------------#
  # Private Functions #
  #-------------------#

  defp filter_market(portfolio, currency) do
    Enum.filter(portfolio, fn %{quote_currency: quote_currency} -> quote_currency == currency end)
  end

  # Keep those coins in first portfolio that is also present in second portfolio
  defp filter_common_coins(first_portfolio, second_portfolio) do
    Enum.filter(first_portfolio, fn %{coin: coin} -> coin_present_in?(coin, second_portfolio) end)
  end

  defp coin_present_in?(coin, portfolio) do
    Enum.any?(portfolio, fn %{coin: coin_in_struct} -> coin == coin_in_struct end)
  end

  # Create %Coinbasebitbns{} struct and fills them
  defp create_coinbasebitbns_struct({coinbase_portfolio, bitbns_portfolio}) do
    %Coinbasebitbns{}
    |> struct(%{coin:             coinbase_portfolio.coin})
    |> struct(%{coinbase_quote:   coinbase_portfolio.quote_currency})
    |> struct(%{bitbns_quote:     bitbns_portfolio.quote_currency})
    |> struct(%{coinbase_price:   coinbase_portfolio.price_usd})
    |> struct(%{bitbns_bid_price: bitbns_portfolio.bid_price_inr})
    |> struct(%{bid_difference:   compute_difference(coinbase_portfolio.price_inr, bitbns_portfolio.bid_price_inr)})
    |> struct(%{bitbns_ask_price: bitbns_portfolio.ask_price_inr})
    |> struct(%{ask_difference:   compute_difference(coinbase_portfolio.price_inr, bitbns_portfolio.ask_price_inr)})
    |> struct(%{bitbns_volume:    bitbns_portfolio.volume})
  end

  # Compute difference %
  defp compute_difference(price1, price2) do
    (price2 - price1) / price1 * 100 |> Float.round(2)
  end
end
