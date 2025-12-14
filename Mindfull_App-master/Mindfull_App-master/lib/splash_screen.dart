import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/login_page.dart';
import 'package:mindful/widgets/logo_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    Future.delayed(
        Duration(seconds: 3),
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => LoginPage() )),
    );
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 115,),
                LogoText(),
                SizedBox(height: 130,),
                Image.asset("assets/images/vector2.png",width: 500,),
                Text('Mindful Ai Companion',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    )
                ),
                SizedBox(height: 15,),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('        Your mental wellness companion, \n                 always here to listen.\n Empowering you with AI-driven support, \n                 anytime, anywhere.',
                          maxLines: 4,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.normal,
                            fontSize: 18,
                            color: Colors.black,
                          )
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),

        Positioned(
          top:0 ,
          bottom: 550,
          left: 60,
            child: SvgPicture.asset("assets/images/line.svg")),
        Positioned(
            top:0 ,
            bottom: 250,
            left: 33.5,
            child: SvgPicture.asset("assets/images/light.svg")),

        Positioned(
            top:0 ,
            bottom: 650,
            left: 115,
            child: SvgPicture.asset("assets/images/line.svg")),
        Positioned(
            top:0 ,
            bottom: 375,
            left: 88,
            child: SvgPicture.asset("assets/images/light.svg")),
      ],
    );
  }
}
