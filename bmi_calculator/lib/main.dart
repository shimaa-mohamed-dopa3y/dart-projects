import 'package:flutter/material.dart';

void main() {
  runApp(BMICalculator());
}

class BMICalculator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFFEB1555),
        scaffoldBackgroundColor: Color(0xFF111328),
      ),
      home: BMICalculatorScreen(),
    );
  }
}

class BMICalculatorScreen extends StatefulWidget {
  @override
  _BMICalculatorScreenState createState() => _BMICalculatorScreenState();
}

class _BMICalculatorScreenState extends State<BMICalculatorScreen> {
  bool isMale = true;
  double height = 180; // in cm
  int weight = 50; // in kg
  int age = 24;

  void calculateAndNavigate() {
    double bmi = weight / ((height / 100) * (height / 100));
    String resultText;
    String feedbackText;

    // Determine feedback based on BMI value
    if (bmi < 18.5) {
      resultText = 'UNDERWEIGHT';
      feedbackText = "You are underweight. Consider a balanced diet.";
    } else if (bmi >= 18.5 && bmi < 24.9) {
      resultText = 'NORMAL';
      feedbackText = "Your body weight is absolutely normal. Good job!";
    } else if (bmi >= 25 && bmi < 29.9) {
      resultText = 'OVERWEIGHT';
      feedbackText = "You are slightly overweight. Consider exercising regularly.";
    } else {
      resultText = 'OBESE';
      feedbackText = "You are in the obese range. Consult a healthcare provider.";
    }

    // Navigate to the result screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(bmi: bmi, resultText: resultText, feedbackText: feedbackText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BMI Calculator"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Select Gender", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GenderSelector(
                  icon: Icons.male,
                  label: "Male",
                  isSelected: isMale,
                  onTap: () {
                    setState(() {
                      isMale = true;
                    });
                  },
                ),
                GenderSelector(
                  icon: Icons.female,
                  label: "Female",
                  isSelected: !isMale,
                  onTap: () {
                    setState(() {
                      isMale = false;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Height", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            HeightSelector(
              height: height,
              onHeightChanged: (newHeight) {
                setState(() {
                  height = newHeight;
                });
              },
            ),
            SizedBox(height: 20),
            Text("Weight and Age", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ValueSelector(
                  label: "Weight",
                  value: weight,
                  onIncrement: () {
                    setState(() {
                      weight++;
                    });
                  },
                  onDecrement: () {
                    setState(() {
                      weight--;
                    });
                  },
                ),
                ValueSelector(
                  label: "Age",
                  value: age,
                  onIncrement: () {
                    setState(() {
                      age++;
                    });
                  },
                  onDecrement: () {
                    setState(() {
                      age--;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: calculateAndNavigate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEB1555),
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text("Calculate BMI", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}

// Result screen to display BMI and feedback
class ResultScreen extends StatelessWidget {
  final double bmi;
  final String resultText;
  final String feedbackText;

  ResultScreen({required this.bmi, required this.resultText, required this.feedbackText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BMI Result"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Your Result", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text(resultText, style: TextStyle(color: Color(0xFFEB1555), fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(bmi.toStringAsFixed(1), style: TextStyle(color: Colors.white, fontSize: 50)),
            SizedBox(height: 20),
            Text(feedbackText, style: TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to the calculator
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEB1555),
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text("Back to Calculator", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for gender selection
class GenderSelector extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  GenderSelector({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFEB1555) : Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black54, spreadRadius: 2, blurRadius: 5)]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 80, color: Colors.white),
            SizedBox(height: 10),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// Widget for height selector with a slider
class HeightSelector extends StatelessWidget {
  final double height;
  final ValueChanged<double> onHeightChanged;

  HeightSelector({required this.height, required this.onHeightChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(height.toStringAsFixed(0), style: TextStyle(color: Colors.white, fontSize: 50)),
              Text(" cm", style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          Slider(
            value: height,
            min: 120,
            max: 220,
            onChanged: onHeightChanged,
            activeColor: Color(0xFFEB1555),
            inactiveColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}

// Widget for weight and age selectors
class ValueSelector extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  ValueSelector({required this.label, required this.value, required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontSize: 18)),
          Text(value.toString(), style: TextStyle(color: Colors.white, fontSize: 50)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: Colors.white),
                onPressed: onDecrement,
              ),
              IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
