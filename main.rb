require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

#constants
CARD_SUITS = ['C', 'D', 'H', 'S']
CARD_RANKS = ['2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A']

#helper functions
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
    value -= 10 if value > 21
  end

  value
end

def determine_winner
  session[:player_value] = calculate_value(session[:player_hand])
  session[:dealer_value] = calculate_value(session[:dealer_hand]) 

  if session[:player_value] > session[:dealer_value]
    session[:player_wins?] = true
  elsif session[:player_value] < session[:dealer_value]
    session[:dealer_wins?] = true
  else
    #tie
  end    
end


#here we start the game
#sending player to login first if there is no logged player
get '/' do
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
  session[:username] = params[:username]
  redirect '/set_start_values'
end

get '/set_start_values' do
  session[:deck] = CARD_SUITS.product(CARD_RANKS).shuffle!
  session[:player_hand] = []
  session[:dealer_hand] = []

  #setting up game states
  session[:player_turn?] = false
  session[:dealer_turn?] = false
  session[:hand_in_play?] = true

  #initial deal
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop

  #winning states - both false at the start
  session[:player_wins?] = false
  session[:dealer_wins?] = false

  session[:player_value] = calculate_value(session[:player_hand])
  session[:dealer_value] = calculate_value(session[:dealer_hand])
  #can replace dealer value so it counts without first card for starters

  if session[:player_value] < 21
    session[:player_turn?] = true
  else
    session[:player_turn?] = false
  end

  redirect '/game'
end

get '/game' do
  #session[:player_value] = calculate_value(session[:player_hand])
  #session[:dealer_value] = calculate_value(session[:dealer_hand])

  if (!session[:player_turn?] && !session[:dealer_turn?])
    determine_winner
    session[:hand_in_play?] = false
  end

  erb :game
end

post '/hit' do
  session[:player_hand] << session[:deck].pop
  redirect '/check_player'
end

post '/stay' do
  #changing state (turn)
  session[:player_turn?] = false

  #here goes the dealer turn --> moved to dealer add card

  redirect '/check_dealer'
end

get '/check_player' do
  session[:player_value] = calculate_value(session[:player_hand])

  if session[:player_value] >= 21
    session[:player_turn?] = false
  end

  redirect '/game'
end

get '/check_dealer' do
  session[:dealer_value] = calculate_value(session[:dealer_hand])

  if session[:dealer_value] < 17
    session[:dealer_turn?] = true
  else
    session[:dealer_turn?] = false
  end

  redirect '/game'
end


post '/dealer_add_card' do
  session[:dealer_hand] << session[:deck].pop

  redirect '/check_dealer'
end

post '/play_again' do
  redirect '/set_start_values'
end

post '/game_over' do
  redirect '/game_over'
end

get '/game_over' do
  session[:username] = false

  erb :game_over
end

#TO DOs !!!!