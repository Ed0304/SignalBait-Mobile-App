import 'package:flutter/material.dart';

class Header extends StatelessWidget{
  //Constructor
  const Header({super.key});

  @override
  Widget build(BuildContext context){
    return AppBar(
      title: const Text("SignalBait"),
    );
  }
  


}