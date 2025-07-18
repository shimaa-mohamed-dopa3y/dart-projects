import 'dart:io';

void main() {
  // Get first list from user
  print("Enter elements for the first list (space-separated numbers):");
  String? input1 = stdin.readLineSync()?.trim();
  List<int> a = [];
  if (input1 != null && input1.isNotEmpty) {
    a = input1.split(' ').where((e) => e.isNotEmpty).map((e) => int.tryParse(e)).whereType<int>().toList();
  }
  
  // Get second list from user
  print("Enter elements for the second list (space-separated numbers):");
  String? input2 = stdin.readLineSync()?.trim();
  List<int> b = [];
  if (input2 != null && input2.isNotEmpty) {
    b = input2.split(' ').where((e) => e.isNotEmpty).map((e) => int.tryParse(e)).whereType<int>().toList();
  }
  
  // Find common elements without duplicates
  List<int> commonList = findCommonElements(a, b);
  
  print("\nFirst list: $a");
  print("Second list: $b");
  print("Common elements: $commonList");
}

List<int> findCommonElements(List<int> list1, List<int> list2) {
  // Convert lists to sets to remove duplicates
  Set<int> set1 = Set<int>.from(list1);
  Set<int> set2 = Set<int>.from(list2);
  
  // Find the intersection of the two sets
  Set<int> commonSet = set1.intersection(set2);
  
  // Convert the result back to a list
  return commonSet.toList();
}