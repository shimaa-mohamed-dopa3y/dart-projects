import 'dart:io';

void main() {
  print('Simple Dart Calculator');
  print('----------------------');
  
  while (true) {
    print('\nChoose an operation:');
    print('1. Add (+)');
    print('2. Subtract (-)');
    print('3. Multiply (*)');
    print('4. Divide (/)');
    print('5. Exit');
    print('Enter your choice (1-5):');
    
    var choice = stdin.readLineSync();
    
    if (choice == '5') {
      print('Goodbye!');
      break;
    }
    
    if (choice != '1' && choice != '2' && choice != '3' && choice != '4') {
      print('Invalid choice. Please try again.');
      continue;
    }
    
    print('Enter first number:');
    var num1 = double.tryParse(stdin.readLineSync() ?? '');
    
    print('Enter second number:');
    var num2 = double.tryParse(stdin.readLineSync() ?? '');
    
    if (num1 == null || num2 == null) {
      print('Invalid number input. Please try again.');
      continue;
    }
    
    double result;
    String operation;
    
    switch (choice) {
      case '1':
        result = num1 + num2;
        operation = '+';
        break;
      case '2':
        result = num1 - num2;
        operation = '-';
        break;
      case '3':
        result = num1 * num2;
        operation = '*';
        break;
      case '4':
        if (num2 == 0) {
          print('Error: Cannot divide by zero.');
          continue;
        }
        result = num1 / num2;
        operation = '/';
        break;
      default:
        print('Invalid choice');
        continue;
    }
    
    print('\nResult: $num1 $operation $num2 = $result');
  }
}