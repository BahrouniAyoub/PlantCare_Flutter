import 'package:flutter/material.dart';
import 'package:flutter_onboarding/constants.dart';
import 'package:flutter_onboarding/ui/screens/widgets/profile_widget.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          height: size.height,
          width: size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 150,
                child: const CircleAvatar(
                  radius: 60,
                  backgroundImage: ExactAssetImage('assets/images/profile.jpg'),
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Constants.primaryColor.withOpacity(.5),
                    width: 5.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: size.width * .3,
                child: Row(
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        color: Constants.blackColor,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 24,
                      child: Image.asset("assets/images/verified.png"),
                    ),
                  ],
                ),
              ),
              Text(
                'johndoe@gmail.com',
                style: TextStyle(
                  color: Constants.blackColor.withOpacity(.3),
                ),
              ),
              const SizedBox(height: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  ProfileWidget(
                    icon: Icons.person,
                    title: 'My Profile',
                  ),
                  ProfileWidget(
                    icon: Icons.settings,
                    title: 'Settings',
                  ),
                  ProfileWidget(
                    icon: Icons.notifications,
                    title: 'Notifications',
                  ),
                  ProfileWidget(
                    icon: Icons.chat,
                    title: 'FAQs',
                  ),
                  ProfileWidget(
                    icon: Icons.share,
                    title: 'Share',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Log Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 16, ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/signin_page');
                    },
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
