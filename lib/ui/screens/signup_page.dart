import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding/constants.dart';
import 'package:flutter_onboarding/ui/root_page.dart';
import 'package:flutter_onboarding/ui/screens/widgets/custom_textfield.dart';
import 'package:flutter_onboarding/ui/screens/signin_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:http/http.dart' as http;

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || name.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
        _isLoading = false;
      });
      return;
    }

    // Simulated signup logic
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          PageTransition(
            child: const SignIn(),
            type: PageTransitionType.bottomToTop,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Signup failed. Try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error occurred during signup.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/signup.png'),
              const Text(
                'Sign Up',
                style: TextStyle(fontSize: 35.0, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 30),

              CustomTextfield(
                controller: _emailController,
                hintText: 'Enter Email',
                icon: Icons.email,
                obscureText: false,
              ),
              const SizedBox(height: 10),

              CustomTextfield(
                controller: _nameController,
                hintText: 'Enter Full Name',
                icon: Icons.person,
                obscureText: false,
              ),
              const SizedBox(height: 10),

              CustomTextfield(
                controller: _passwordController,
                hintText: 'Enter Password',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 10),

              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 10),
              GestureDetector(
                onTap: _isLoading ? null : _signup,
                child: Container(
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Constants.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign Up',
                            style: TextStyle(color: Colors.white, fontSize: 18.0),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                width: size.width,
                decoration: BoxDecoration(
                  border: Border.all(color: Constants.primaryColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      height: 30,
                      child: Image.asset('assets/images/google.png'),
                    ),
                    Text(
                      'Sign Up with Google',
                      style: TextStyle(
                        color: Constants.blackColor,
                        fontSize: 18.0,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageTransition(
                      child: const SignIn(),
                      type: PageTransitionType.bottomToTop,
                    ),
                  );
                },
                child: Center(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'Have an Account? ',
                        style: TextStyle(color: Constants.blackColor),
                      ),
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(color: Constants.primaryColor),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
