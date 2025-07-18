void main() {
  print('Calculator using Loop (1 to 10)');
  print('-----------------------------');
  
  double sum = 0;
  double sub = 0;
  double mul = 1; // Start with 1 for multiplication
  double div = 1;  // Start with 1 for division
  
  // Initialize sub and div with the first value (1)
  // because subtraction and division need to start with the first number
  sub = 1;
  div = 1;
  bool firstIteration = true;
  
  for (int i = 1; i <= 10; i++) {
    sum += i;
    
    if (firstIteration) {
      // For first iteration, sub and div are already set to 1
      firstIteration = false;
    } else {
      sub -= i;
      div /= i;
    }
    
    mul *= i;
  }
  
  print('Sum of numbers 1 to 10: $sum');
  print('Subtraction of numbers 1 to 10: $sub');
  print('Multiplication of numbers 1 to 10: $mul');
  print('Division of numbers 1 to 10: ${div.toStringAsFixed(15)}');
}