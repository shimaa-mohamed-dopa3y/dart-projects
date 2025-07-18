import 'dart:io';
import 'dart:math';

void main() {
  // Create a Random object for generating random numbers
  final random = Random();
  int correctGuesses = 0;
  // Generate the first random number outside the loop
  int targetNumber = random.nextInt(10) + 1;
  
  while (true) {
    // Prompt user for input
    stdout.write("Guess number between 1 to 10: ");
    String? userInput = stdin.readLineSync();
    
    // Check if user wants to exit
    if (userInput?.toLowerCase() == "exit") {
      print("you guessed $correctGuesses correct answers");
      break;
    }
    
    // Try to convert user input to integer
    int? userGuess = int.tryParse(userInput ?? "");
    
    // Check if user input is a valid number
    if (userGuess == null) {
      print("Please enter a valid number or 'exit' to quit.");
      continue;
    }
    
    // Check if guess is correct
    if (userGuess == targetNumber) {
      print("right");
      correctGuesses++;
      // Generate a new random number only after a correct guess
      targetNumber = random.nextInt(10) + 1;
    } else {
      print("wrong");
    }
  }
}