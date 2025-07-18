import 'dart:io';

void main() {
  print('Palindrome Checker');
  print('------------------');
  
  while (true) {
    print('\nEnter Text (or type "exit" to quit):');
    String? input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      print('Please enter valid text.');
      continue;
    }

    if (input.toLowerCase() == 'exit') {
      print('Goodbye!');
      break;
    }

    // Check if palindrome
    String cleanedInput = input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    String reversedInput = cleanedInput.split('').reversed.join('');

    if (cleanedInput == reversedInput) {
      print('✅ "$input" is a Palindrome!');
    } else {
      print('❌ "$input" is NOT a Palindrome.');
    }
  }
}