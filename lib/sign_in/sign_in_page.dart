import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_contact_card/app/home.dart';
import 'package:digital_contact_card/custom_widgets/show_alert_dialog.dart';
import 'package:digital_contact_card/custom_widgets/show_exception_alert_dialog.dart';
import 'package:digital_contact_card/services/auth.dart';
import 'package:digital_contact_card/sign_in/password_recovery.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:digital_contact_card/sign_in/valildators.dart';

enum FormType {signIn, register}

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key, required this.isLoading}) : super(key: key);
  final bool isLoading;

  static Widget create(BuildContext context) {
    return ChangeNotifierProvider<ValueNotifier<bool>>(
      create: (_) => ValueNotifier<bool>(false),
      child: Consumer<ValueNotifier<bool>>(
        builder: (_, isLoading, __) => SignInPage(isLoading: isLoading.value),
      ),
    );
  }
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with
    EmailAndPasswordValidator, SingleTickerProviderStateMixin {

  /********** EMAIL SIGN IN STUFF **********/

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  FormType _formState = FormType.signIn;
  String get _email => _emailController.text;
  String get _password => _passwordController.text;
  bool _submitted = false;
  bool _loading = false;

  void changeFormType() {
    setState(() {
      _submitted = false;
      _formState = _formState == FormType.signIn ? FormType.register : FormType.signIn;
    });
    _emailController.clear();
    _passwordController.clear();
  }

  void submit() async {
    setState(() {
      _submitted = true;
      _loading = true;
    });
    try {
      if (_formState == FormType.signIn) {
        await Provider.of<AuthBase>(context, listen: false).signInEmail(_email, _password);
      } else {
        await Provider.of<AuthBase>(context, listen: false).createUserEmail(_email, _password);
      }
    } on Exception catch (e) {
      _showSignInError(context, e);
    } finally {
      _loading = false;
    }
  }

  void _updateState() {
    setState(() {});
  }

  void _showSignInError(BuildContext context, Exception exception) {
    if (exception is FirebaseException &&
        exception.code == 'ERROR_ABORTED_BY_USER') {
      return;
    }
    showExceptionAlertDialog(
      context,
      title: 'Sign in failed',
      exception: exception,
    );
  }

  /********** ANIMATION STUFF **********/

  late double _scale;
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 70),
      lowerBound: 0.0,
      upperBound: 0.07,
    )..addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _tapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _tapUp(TapUpDetails details) {
    _controller.reverse();
  }

  /********** UI STUFF **********/

  @override
  Widget build(BuildContext context) {
    String primaryButtonText = _formState == FormType.signIn ?
    'Sign in' : 'Register';
    String secondaryButtonText = _formState == FormType.signIn ?
    'Don\'t have an account? Register' : 'Have an account? Sign in';
    bool emailValid = emailValidator.isValid(_email);
    bool passwordValid = passwordValidator.isValid(_password);
    bool submitValid = !_loading && emailValid && passwordValid;
    bool showEmailError = _submitted && !emailValid;
    bool showPasswordError = _submitted && !passwordValid;
    _scale = 1 - _controller.value;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue, Colors.red],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: MediaQuery.of(context).size.width),
              Text(
                'Say hi to your new business card',
                textAlign: TextAlign.center,
                style: GoogleFonts.comfortaa(
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 32.0,
                  ),
                ),
              ),
              SizedBox(height: 50.0),
              TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white38),
                  errorText: showEmailError ? 'Email can\'t be empty' : null,
                  errorStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                cursorColor: Colors.white,
                controller: _emailController,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_email) => _updateState(),
              ),
              SizedBox(height: 10.0),
              TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white38),
                  errorText: showPasswordError ? 'Password can\'t be empty' : null,
                  errorStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                cursorColor: Colors.white,
                controller: _passwordController,
                autocorrect: false,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onChanged: (_password) => _updateState(),
              ),
              SizedBox(height: 30.0),
              GestureDetector(
                onTapDown: _tapDown,
                onTapUp: _tapUp,
                child: Transform.scale(
                  scale: _scale,
                  child: _signInButton(primaryButtonText, submitValid),
                ),
              ),
              _switchButton(secondaryButtonText),
              _forgotPasswordButton(_formState == FormType.signIn ? "Forgot your password?" : " "),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signInButton(String primaryButtonText, bool submitValid) {
    return TextButton(
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 40 - 150,
        child: Text(
          primaryButtonText,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
      onPressed: submitValid ? submit : null,
      style: ButtonStyle(
        overlayColor: MaterialStateColor.resolveWith((states) => Colors.transparent),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
          side: BorderSide(color: Colors.white),
        )),
      ),
    );
  }

  Widget _switchButton(String secondaryButtonText) {
    return TextButton(
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 40 - 150,
        child: Text(
          secondaryButtonText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      onPressed: !_loading ? changeFormType : null,
      style: ButtonStyle(
        overlayColor: MaterialStateColor.resolveWith((states) => Colors.transparent),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        )),
      ),
    );
  }

  Widget _forgotPasswordButton(String text) {
    return TextButton(
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 40 - 150,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PasswordRecovery(),
      )),
      style: ButtonStyle(
        overlayColor: MaterialStateColor.resolveWith((states) => Colors.transparent),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        )),
      ),
    );
  }
}
