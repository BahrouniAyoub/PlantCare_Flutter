import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding/constants.dart';
import 'package:flutter_onboarding/ui/screens/widgets/custom_textfield.dart';
import 'package:page_transition/page_transition.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_onboarding/ui/root_page.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _emailController = TextEditingController(text: "test001@gmail.com");
  final _passwordController = TextEditingController(text: "123456");
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  bool _isLoading = false;
  String _errorMessage = '';

  // Function to handle login
  Future<void> _login() async {
    print("🔐 Sign In button clicked"); 
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    // Backend URL for login
    final url = 'http://10.0.2.2:5000/api/auth/login';

    // Prepare the login request payload
    final body = json.encode({
      'email': email,
      'password': password,
    });

    // Send the POST request
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('🔁 Backend response: ${response.body}');


      if (response.statusCode == 200) {
        // Successfully logged in
        final data = json.decode(response.body);
        final token = data['token'];
        final userId = data['userId'];

        // Save the token securely
        await _storage.write(key: 'jwt', value: token);

        // Navigate to the RootPage with the userId
        Navigator.pushReplacement(
          context,
          PageTransition(
            child: RootPage(userId: userId), // Pass the userId here
            type: PageTransitionType.bottomToTop,
          ),
        );
      } else {
        // Failed to login, show error
        setState(() {
          _errorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
      print('Error: $e');
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/signin.png'),
              const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 35.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              // Email TextField
              CustomTextfield(
                controller: _emailController,
                obscureText: false,
                hintText: 'Enter Email',
                icon: Icons.alternate_email,
                
              ),
              const SizedBox(
                height: 10,
              ),
              // Password TextField
              CustomTextfield(
                controller: _passwordController,
                obscureText: true,
                hintText: 'Enter Password',
                icon: Icons.lock,
              ),
              const SizedBox(
                height: 10,
              ),
              // Error Message Display
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(
                height: 10,
              ),
              // Sign In Button
              GestureDetector(
                onTap: _isLoading ? null : _login,
                child: Container(
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Constants.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: Center(
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              // Forgot Password Link
              GestureDetector(
                // onTap: () {
                //   Navigator.pushReplacement(
                //       context,
                //       PageTransition(
                //           child: const ForgotPassword(),
                //           type: PageTransitionType.bottomToTop));
                // },
                child: Center(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'Forgot Password? ',
                        style: TextStyle(
                          color: Constants.blackColor,
                        ),
                      ),
                      TextSpan(
                        text: 'Reset Here',
                        style: TextStyle(
                          color: Constants.primaryColor,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              // OR Section
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
              const SizedBox(
                height: 20,
              ),
              // Google SignIn Button
              Container(
                width: size.width,
                decoration: BoxDecoration(
                    border: Border.all(color: Constants.primaryColor),
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      height: 30,
                      child: Image.asset('assets/images/google.png'),
                    ),
                    Text(
                      'Sign In with Google',
                      style: TextStyle(
                        color: Constants.blackColor,
                        fontSize: 18.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              // Register Link
              GestureDetector(
                // onTap: () {
                //   Navigator.pushReplacement(
                //       context,
                //       PageTransition(
                //           child: const SignUp(),
                //           type: PageTransitionType.bottomToTop));
                // },
                child: Center(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'New to Planty? ',
                        style: TextStyle(
                          color: Constants.blackColor,
                        ),
                      ),
                      TextSpan(
                        text: 'Register',
                        style: TextStyle(
                          color: Constants.primaryColor,
                        ),
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
