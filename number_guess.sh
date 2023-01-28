#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=numguess -t --no-align -c"
RANDNUM=$(( RANDOM % 1000 ))
NUM_GUESSES=0

echo Enter your username:
read USERNAME

USER=$($PSQL "SELECT * FROM users WHERE username = '$USERNAME'")

if [[ -z $USER ]]
then
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  echo Welcome, $USERNAME! It looks like this is your first time here.
else
  GAMES_PLAYED=$(echo $($PSQL "SELECT games_played FROM users WHERE username = '$USERNAME'") | xargs)
  BEST_GAME=$(echo $($PSQL "SELECT best_game FROM users WHERE username = '$USERNAME'") | xargs)
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

echo Guess the secret number between 1 and 1000:
read USER_GUESS

while true
do
  if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]
  then
    echo That is not an integer, guess again:
    read USER_GUESS
  else
    # increment number of guesses
    NUM_GUESSES=$((NUM_GUESSES+1))

    # make comparison
    if [[ $USER_GUESS -gt $RANDNUM ]]
    then
      echo "It's lower than that, guess again:"
      read USER_GUESS
    elif [[ $USER_GUESS -lt $RANDNUM ]]
    then
      echo "It's higher than that, guess again:"
      read USER_GUESS
    else
      echo "You guessed it in $NUM_GUESSES tries. The secret number was $RANDNUM. Nice job!"

      # update games_played in database
      GAMES_PLAYED=$((GAMES_PLAYED+1))
      UPDATE_GAMES=$($PSQL "UPDATE users SET games_played = $GAMES_PLAYED WHERE username = '$USERNAME'")

      # get best_game from db
      BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username = '$USERNAME'")
      if [[ $BEST_GAME -gt $NUM_GUESSES || $BEST_GAME -eq 0 ]]
      then
        # update best_game in db
        UPDATE_BEST=$($PSQL "UPDATE users SET best_game = $NUM_GUESSES WHERE username = '$USERNAME'")
      fi
      break
    fi
  fi
done
