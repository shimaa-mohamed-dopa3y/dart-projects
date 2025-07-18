import 'package:flutter/material.dart';

void main() {
  runApp(ShopApp());
}

class ShopApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.yellow,
        textTheme: TextTheme(
          titleLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: LoginScreen(),
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool validateCredentials(String username, String password) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$');

    return usernameRegex.hasMatch(username) && passwordRegex.hasMatch(password);
  }

  void login() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CatalogScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: "Username"),
                validator: (value) {
                  if (value == null || value.isEmpty || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                    return 'Enter a valid username (alphanumeric)';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password"),
                validator: (value) {
                  if (value == null || value.isEmpty || !RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$').hasMatch(value)) {
                    return 'Password must be at least 6 characters with letters and numbers';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                child: Text("Enter", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Catalog Screen
class CatalogScreen extends StatefulWidget {
  @override
  _CatalogScreenState createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Map<String, dynamic>> catalogItems = [
    {'name': 'Code Smell', 'price': 20, 'color': Colors.red},
    {'name': 'Control Flow', 'price': 15, 'color': Colors.pink},
    {'name': 'Interpreter', 'price': 25, 'color': Colors.purple},
    {'name': 'Recursion', 'price': 30, 'color': Colors.blue},
    {'name': 'Sprint', 'price': 18, 'color': Colors.lightBlue},
    {'name': 'Heisenbug', 'price': 22, 'color': Colors.cyan},
    {'name': 'Spaghetti', 'price': 28, 'color': Colors.teal},
    {'name': 'Hydra Code', 'price': 35, 'color': Colors.green},
    {'name': 'Off-By-One', 'price': 17, 'color': Colors.lightGreen},
    {'name': 'Scope', 'price': 24, 'color': Colors.lime},
    {'name': 'Callback', 'price': 21, 'color': Colors.yellow},
  ];

  List<Map<String, dynamic>> cartItems = [];

  void toggleCartItem(Map<String, dynamic> item) {
    setState(() {
      if (cartItems.contains(item)) {
        cartItems.remove(item);
      } else {
        cartItems.add(item);
      }
    });
  }

  bool isInCart(Map<String, dynamic> item) {
    return cartItems.contains(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: Text("Catalog", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellow,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen(cartItems: cartItems)),
              ).then((_) => setState(() {})); // Refresh catalog screen on return
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: catalogItems.length,
        itemBuilder: (context, index) {
          final item = catalogItems[index];
          final inCart = isInCart(item);
          return ListTile(
            leading: CircleAvatar(backgroundColor: item['color']),
            title: Text(item['name'], style: TextStyle(color: Colors.black)),
            subtitle: Text('${item['price']} \$', style: TextStyle(color: Colors.black54)),
            trailing: ElevatedButton(
              onPressed: () => toggleCartItem(item),
              style: ElevatedButton.styleFrom(
                  backgroundColor: inCart ? Colors.red : Colors.black),
              child: Text(inCart ? "REMOVE" : "ADD", style: TextStyle(color: Colors.yellow)),
            ),
          );
        },
      ),
    );
  }
}

// Cart Screen
class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  CartScreen({required this.cartItems});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int get totalPrice {
    return widget.cartItems.fold(0, (total, item) => total + item['price'] as int);
  }

  void removeFromCart(Map<String, dynamic> item) {
    setState(() {
      widget.cartItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: Text("Cart", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellow,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return ListTile(
                  title: Text(item['name'], style: TextStyle(color: Colors.black)),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => removeFromCart(item),
                  ),
                );
              },
            ),
          ),
          Divider(color: Colors.black),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${totalPrice}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: Text("BUY", style: TextStyle(color: Colors.yellow)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
