import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:xl_otpsend/account.dart';
import 'package:xl_otpsend/communication.dart';
import 'package:xl_otpsend/generalsetting.dart';
import 'package:xl_otpsend/qr.dart';
import 'package:xl_otpsend/scanresult.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String REPO_LINK = "https://github.com/goaaats/xl-authenticator";

  late bool isRestartChecked = false;

  late bool isAccountSaved = false;
  String? savedName;
  String? savedSecret;

  @override
  void initState() {
    GeneralSetting.getIsAutoClose().then((value) {
      setState(() {
        isRestartChecked = value;
      });
    });

    SavedAccount.getSaved().then((value) {
      setState(() {
        if (value != null) {
          isAccountSaved = true;
          savedName = value.accountName;
          savedSecret = value.secret;
        }
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle defaultStyle = TextStyle(color: Colors.grey, fontSize: 13.0);
    TextStyle linkStyle = TextStyle(color: Colors.blue, fontSize: 13.0);

    TextStyle goodStyle = TextStyle(color: Colors.green, fontSize: 13.0);
    TextStyle badStyle = TextStyle(color: Colors.red, fontSize: 13.0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        brightness: Brightness.dark,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RichText(
                text: TextSpan(
              style: defaultStyle,
              children: <TextSpan>[
                TextSpan(text: 'Registered: '),
                TextSpan(
                    text: ((() {
                      if (isAccountSaved){
                        if (savedName != '')
                          return savedName;

                        return "Yes";
                      }

                      return "none";
                    })()),
                    style: ((() {
                      if (isAccountSaved) return goodStyle;

                      return badStyle;
                    })()),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        if (savedSecret != null) {
                          Clipboard.setData(ClipboardData(text: savedSecret));

                          Fluttertoast.showToast(
                              msg: "Secret copied!",
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0);
                        }
                      }),
              ],
            )),
            ElevatedButton(
              onPressed: () {
                _navigateAndScanQr(context);
              },
              child: Text('Set-Up OTP code'),
            ),
            Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: FutureBuilder(
                future: Communication.getSavedIp(),
                builder: (context, snapshot) {
                  return RichText(
                      text: TextSpan(
                    style: defaultStyle,
                    children: <TextSpan>[
                      TextSpan(text: 'XIVLauncher IP: '),
                      TextSpan(
                          text: ((() {
                            if (snapshot.hasData)
                              return snapshot.data as String;

                            return "not set";
                          })()),
                          style: ((() {
                            if (snapshot.hasData) return goodStyle;

                            return badStyle;
                          })()),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              if (savedSecret != null)
                                Clipboard.setData(
                                    ClipboardData(text: savedSecret));
                            }),
                    ],
                  ));
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                var result = await prompt(context,
                    title: Text("Enter XIVLauncher IP"),
                    textOK: Text("OK"),
                    textCancel: Text("Cancel"),
                    maxLines: 1,
                    minLines: 1,
                    autoFocus: true,
                    textCapitalization: TextCapitalization.none,
                    initialValue: await Communication.getSavedIp());

                if (result != null) {
                  debugPrint("Manual entry: $result");
                  setState(() {
                    Communication.setSavedIp(result);
                  });
                }
              },
              child: Text('Set XIVLauncher IP'),
            ),
            Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                    ),
                    Text("Close app after sending:"),
                    Checkbox(
                        value: isRestartChecked,
                        onChanged: (value) {
                          setState(() {
                            isRestartChecked = value as bool;
                            GeneralSetting.setIsAutoClose(value);
                          });
                        })
                  ],
                )),
            Padding(
                padding: EdgeInsets.only(top: 50, left: 10, right: 10),
                child: RichText(
                    text: TextSpan(
                  style: defaultStyle,
                  children: <TextSpan>[
                    TextSpan(text: 'By goat, see '),
                    TextSpan(
                        text: 'licenses',
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            showLicensePage(
                                context: context,
                                applicationName: "XL Authenticator",
                                applicationLegalese:
                                    "Automatic OTPs for XIVLauncher\n(c) goaaats 2020",
                                applicationIcon: Padding(
                                    padding:
                                        EdgeInsets.only(left: 100, right: 100),
                                    child: Image(
                                        image: AssetImage('assets/logo.png'))));
                          }),
                    TextSpan(text: ' and '),
                    TextSpan(
                        text: 'source code',
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            await _openRepoLink();
                          }),
                  ],
                ))),
          ],
        ),
      ),
    );
  }

  Future<void> _openRepoLink() async {
    await launch(
      REPO_LINK,
    );
  }

  _navigateAndScanQr(BuildContext context) async {
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    final result = await Navigator.push(
      context,
      // Create the SelectionScreen in the next step.
      MaterialPageRoute(builder: (context) => QRViewExample()),
    );

    if (result == null) return;

    SavedAccount? saved;

    switch (result.type) {
      case ScanResultType.Uri:
        saved = SavedAccount.parse(result.data);
        break;
      case ScanResultType.Raw:
        saved = SavedAccount.unnamed(result.data.toString().toUpperCase().replaceAll(" ", ""));
        break;
    }

    setState(() {
      if (saved != null) {
        isAccountSaved = true;
        savedName = saved.accountName;
        savedSecret = saved.secret;
      }
    });

    SavedAccount.setSaved(saved as SavedAccount);

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text("Saved!")));
  }
}
