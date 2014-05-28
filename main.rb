require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

#constants
CARD_SUITS = ['C', 'D', 'H', 'S']
CARD_RANKS = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
BLACKJACK = 21
DEALER_STOP = 17
INITIAL_BANKROLL = 1000
BANKRUPT = 0

#helper functions
helpers do
  def calculate_value(hand)
    value = 0

    hand.each do |card|
      if card[1] == 'A' # A case
        value += 11
      elsif card[1].to_i == 0 # K, Q, J cases
        value += 10
      else
        value += card[1].to_i
      end
    end

    hand.select{ |card| card[1] == 'A' }.count.times do
      value -= 10 if value > BLACKJACK
    end

    value
  end

  def card_image(card) #[suit, value]
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = case card[1]
      when 'J' then 'jack'
      when 'Q' then 'queen'
      when 'K' then 'king'
      when 'A' then 'ace'
      else card[1]
    end

    "<img src='images/cards/#{suit}_#{value}.jpg'>"
  end

  def hand_in_play?
    if (!session[:player_turn?] && !session[:dealer_turn?])
      determine_winner
      recalculate_bankroll
      session[:hand_in_play?] = false
    end
  end

  def determine_winner
    session[:player_value] = calculate_value(session[:player_hand])
    session[:dealer_value] = calculate_value(session[:dealer_hand]) 

    if session[:player_value] == BLACKJACK
      session[:player_wins?] = true
    elsif session[:player_value] > BLACKJACK
      session[:dealer_wins?] = true
    elsif session[:dealer_value] == BLACKJACK
      session[:dealer_wins?] = true
    elsif session[:dealer_value] > BLACKJACK
      session[:player_wins?] = true
    elsif session[:player_value] > session[:dealer_value]
      session[:player_wins?] = true
    elsif session[:player_value] < session[:dealer_value]
      session[:dealer_wins?] = true
    else
      #tie
    end    
  end

  def recalculate_bankroll
    if session[:player_wins?]
      session[:bankroll] += session[:bet_amount]
    elsif session[:dealer_wins?]
      session[:bankroll] -= session[:bet_amount]
    end
  end
end

#start of the game logic
get '/' do
  #starting bankroll
  session[:bankroll] = INITIAL_BANKROLL

  if session[:username]
    redirect '/set_start_values'
  else
    redirect '/login'
  end
end

#login form
get '/login' do
  erb :login
end

#storing the player name
post '/login' do
  if params[:username].empty?
    @error = "Please state your name before playing."
    halt erb :login #halt stops the further execution and return only
                    #what we specify after (erb :login here)
  end

  #storing the username state
  session[:username] = params[:username]

  redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/bet' do
  if params[:bet_amount].to_i == 0
    @error = "Please enter a valid bet amount."
    halt erb :bet
  elsif params[:bet_amount].to_i > session[:bankroll]
    @error = "You can't bet more than you have."
    halt erb :bet
  end

  #storing the bet amount
  session[:bet_amount] = params[:bet_amount].to_i

  redirect '/set_start_values'
end

get '/set_start_values' do
  session[:deck] = CARD_SUITS.product(CARD_RANKS).shuffle!
  session[:player_hand] = []
  session[:dealer_hand] = []

  #setting up game states
  session[:hand_in_play?] = true
  session[:player_turn?] = false
  session[:dealer_turn?] = false
  session[:player_wins?] = false
  session[:dealer_wins?] = false

  #initial deal
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop

  session[:player_value] = calculate_value(session[:player_hand])
  session[:dealer_value] = calculate_value(session[:dealer_hand])

  if session[:player_value] < BLACKJACK
    session[:player_turn?] = true
  end

  redirect '/game'
end

get '/game' do

  erb :game
end

post '/hit' do
  session[:player_hand] << session[:deck].pop
  redirect '/check_player'
end

post '/stay' do
  #changing state (turn)
  session[:player_turn?] = false

  redirect '/check_dealer'
end

get '/check_player' do
  session[:player_value] = calculate_value(session[:player_hand])

  if session[:player_value] >= BLACKJACK
    session[:player_turn?] = false
  end

  hand_in_play?

  erb :game
end

get '/check_dealer' do
  session[:dealer_value] = calculate_value(session[:dealer_hand])

  if session[:dealer_value] < DEALER_STOP
    session[:dealer_turn?] = true
  else
    session[:dealer_turn?] = false
  end

  hand_in_play?

  erb :game
end


post '/dealer_add_card' do
  session[:dealer_hand] << session[:deck].pop

  redirect '/check_dealer'
end

post '/play_again' do
  if session[:bankroll] == BANKRUPT
    redirect '/game_over'
  else
    redirect '/bet'
  end
end

post '/game_over' do
  redirect '/game_over'
end

get '/game_over' do

  erb :game_over
end

get '/restart' do
  session[:username] = false

  redirect '/'
end