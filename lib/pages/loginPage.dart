import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:smc_voting_app/utils/Node.dart';
import 'package:smc_voting_app/utils/candidate.dart';
import 'package:smc_voting_app/utils/election.dart';
import 'package:smc_voting_app/utils/paillier_encrpyt/paillier_key_pair.dart';
import 'package:smc_voting_app/utils/peer.dart';
import 'package:smc_voting_app/utils/services.dart';
import 'package:smc_voting_app/utils/verifier.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/export.dart' as pointycastle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';

import '../screens/takePictureScreen.dart';
import 'voter_dashboard.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appTitle = 'Login';

    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: Text(appTitle),
        ),
        body: LoginForm(),
      ),
    );
  }
}

// Create a Form widget.
class LoginForm extends StatefulWidget {
  @override
  LoginFormState createState() {
    return LoginFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class LoginFormState extends State<LoginForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  String imagePath = "";
  Image profilePic = Image(image: AssetImage('assets/profile_pic.jpg'));
  TextEditingController idController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    if (imagePath != "") {
      profilePic = Image.file(File(imagePath));
    }

    return ListView(
      children: <Widget>[
        Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 15.0),
                      child: CircleAvatar(
                        radius: 75,
                        backgroundImage: profilePic.image,
                      ),
                    ),
                    ElevatedButton(
                      child: Text("Take a picture"),
                      onPressed: () async {
                        // Ensure that plugin services are initialized so that `availableCameras()`
                        // can be called before `runApp()`
                        WidgetsFlutterBinding.ensureInitialized();

                        // Obtain a list of the available cameras on the device.
                        final cameras = await availableCameras();

                        // Get a specific camera from the list of available cameras.
                        final firstCamera = cameras[1];

                        // Navigator.pop on the Selection Screen.

                        String result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  extendBody: true,
                                  //theme: ThemeData.dark(),
                                  body: TakePictureScreen(
                                    // Pass the appropriate camera to the TakePictureScreen widget.
                                    camera: firstCamera,
                                  ),
                                ),
                              ),
                            ) ??
                            '';
                        log("imagePath: ");
                        log(imagePath);

                        setState(() {
                          imagePath = result;
                        });
                      },
                    ),
                  ]),
                  TextFormField(
                    controller: idController,
                    decoration: InputDecoration(labelText: 'Enter your NID'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'You must enter something';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: 'Enter your Password'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'You must enter something';
                      }
                      return null;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        bool proceed = true;
                        bool stop = false;
                        // Validate returns true if the form is valid, or false
                        // otherwise.
                        if (_formKey.currentState!.validate() &&
                            imagePath != "") {
                          // If the form is valid, display a Snackbar.
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Processing Data')));
                          String username = idController.text;
                          String password = passwordController.text;
                          String basicAuth = 'Basic ' +
                              base64Encode(utf8.encode('$username:$password'));

                          final facePicBytes =
                              await File(imagePath).readAsBytes();
                          final facePicUri = base64Encode(facePicBytes);
                          //log(face_pic_uri);
                          var headers = {'Authorization': basicAuth};
                          var request = http.MultipartRequest(
                              'POST', Uri.parse('$urlEA/voter_login'));
                          request.fields.addAll({'face_pic': facePicUri});

                          request.headers.addAll(headers);
                          String ipAddress =
                              await WifiInfo().getWifiIP() ?? '127.0.0.1';
                          print(ipAddress);
                          //return;
                          int respondingPort = await getUnusedPort(ipAddress);

                          request.fields.addAll({
                            'ip_address': ipAddress,
                            'responding_port': respondingPort.toString()
                          });

                          if (await getLocalID() != username) {
                            if (await getLocalID() != '') {
                              await showDialog<void>(
                                context: context,
                                //barrierDismissible: false, // user must tap button!
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Warning'),
                                    content: SingleChildScrollView(
                                      child: ListBody(
                                        children: <Widget>[
                                          Text(
                                              'This is not the NId you used to login last time. If you continue your public keys will be updated. You will not be able to participate in the verifaction process and the tallying process of any ongoing election'),
                                          Text('Do you want to proceed?'),
                                        ],
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Yes'),
                                        onPressed: () {
                                          proceed = true;
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text('No'),
                                        onPressed: () {
                                          proceed = false;
                                          stop = true;
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }

                            if (proceed) {
                              await saveLocalID(username);
                              pointycastle.AsymmetricKeyPair<
                                      pointycastle.RSAPublicKey,
                                      pointycastle.RSAPrivateKey> rsaKeyPair =
                                  generateRSAkeyPair(bitLength: 2048);
                              await saveMyRSAPrivateKey(rsaKeyPair.privateKey);
                              await saveMyRSAPublicKey(
                                  rsaKeyPair.publicKey); /**/
                              PaillierKeyPair paillierKeyPair =
                                  PaillierKeyPair.generate(2048);
                              await saveMyPaillierPrivateKey(
                                  paillierKeyPair.privateKey);
                              await saveMyPaillierPublicKey(
                                  paillierKeyPair.publicKey);
                              String public_key_str = jsonEncode({
                                'rsa': {
                                  'modulus':
                                      rsaKeyPair.publicKey.modulus.toString(),
                                  'exponent':
                                      rsaKeyPair.publicKey.exponent.toString()
                                },
                                'paillier': {
                                  'g': paillierKeyPair.publicKey.g.toString(),
                                  'n': paillierKeyPair.publicKey.n.toString(),
                                  'bits': paillierKeyPair.publicKey.bits,
                                  'nSquared': paillierKeyPair.publicKey.nSquared
                                      .toString()
                                }
                              });
                              request.fields.addAll({
                                'public_key': public_key_str,
                              });
                            }
                          }

                          if (stop) {
                            return;
                          }

                          //print(request.fields);
                          http.StreamedResponse response = await request.send();

                          if (response.statusCode == 200) {
                            String resStr =
                                await response.stream.bytesToString();
                            log(resStr);
                            Map<String, dynamic> resJson = jsonDecode(resStr);
                            await saveMyShareNum(
                                BigInt.from(resJson['yourShareNum']));
                            List<Map<String, dynamic>> candidatesJson =
                                List<Map<String, dynamic>>.from(
                                    resJson["candidatesJson"]);
                            Candidate candidateTemp;
                            for (final candidateJson in candidatesJson) {
                              candidateTemp = Candidate.fromJson(candidateJson);
                              await candidateTemp
                                  .save(candidateJson['election_id']);
                            }
                            List<Map<String, dynamic>> electionsJson =
                                List<Map<String, dynamic>>.from(
                                    resJson["electionsJson"]);
                            var knownElections =
                                await Election.elections(toConstruct: false);
                            var electionsToKillIds = <String>[];
                            for (final election in knownElections) {
                              electionsToKillIds.add(election!.election_id);
                            }
                            print(electionsToKillIds);
                            for (final electionJson in electionsJson) {
                              if (electionsToKillIds
                                  .contains(electionJson['election_id'])) {
                                electionsToKillIds
                                    .remove(electionJson['election_id']);
                              }
                            }
                            print('elections to be killed');

                            for (final electionId in electionsToKillIds) {
                              var deadElection =
                                  Election.getElection(electionId);
                              (await deadElection)!.delete();
                            }

                            Election electionTemp;
                            for (final electionJson in electionsJson) {
                              electionTemp = (await Election.fromJson(
                                  electionJson,
                                  toConstruct: false))!;
                              await electionTemp.save();
                            }
                            List<Map<String, dynamic>> peersJson =
                                List<Map<String, dynamic>>.from(
                                    resJson["peersJson"]);
                            Peer peerTemp;
                            for (var peerJson in peersJson) {
                              peerJson['public_key'] = jsonDecode(
                                  peerJson['public_key'] ?? jsonEncode(''));
                              peerTemp = Peer.fromJson(peerJson);
                              await peerTemp.save();
                            }
                            List<Map<String, dynamic>> verifiersJson =
                                List<Map<String, dynamic>>.from(
                                    resJson["verifiersJson"]);
                            Verifier verifierTemp;
                            for (var verifierJson in verifiersJson) {
                              verifierJson['public_key'] =
                                  jsonDecode(verifierJson['public_key']);
                              verifierTemp = Verifier.fromJson(verifierJson);
                              await verifierTemp.save();
                            }
                            print('here');
                            Node node =
                                await Node.getNode(ipAddress, respondingPort);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        VoterDashboard(node))); /**/
                          } else {
                            print(response.reasonPhrase);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    await response.stream.bytesToString())));
                          }
                        } else if (imagePath == "") {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Make sure to take a picture')));
                        }
                      },
                      child: Text('Submit'),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
