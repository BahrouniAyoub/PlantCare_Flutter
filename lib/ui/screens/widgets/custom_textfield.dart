import 'package:flutter/material.dart';
import 'package:flutter_onboarding/constants.dart';

class CustomTextfield extends StatelessWidget {
  final IconData icon;
  final bool obscureText;
  final String hintText;
  final TextEditingController controller;  // Added controller parameter

  const CustomTextfield({
    Key? key,
    required this.icon,
    required this.obscureText,
    required this.hintText,
    required this.controller,  // Added controller to the constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,  // Set the controller to TextField
      obscureText: obscureText,
      style: TextStyle(
        color: Constants.blackColor,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        prefixIcon: Icon(
          icon, 
          color: Constants.blackColor.withOpacity(.3),
        ),
        hintText: hintText,
      ),
      cursorColor: Constants.blackColor.withOpacity(.5),
    );
  }
}
