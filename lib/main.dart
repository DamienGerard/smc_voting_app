import 'package:flutter/material.dart';
import 'pages/loginPage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  /*final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await saveMyShareNum(BigInt.one);
  await saveLocalID('myID1');
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> rsaKeyPair =
      generateRSAkeyPair(bitLength: 2048);
  await saveMyRSAPrivateKey(rsaKeyPair.privateKey);
  await saveMyRSAPublicKey(rsaKeyPair.publicKey); /**/
  PaillierKeyPair paillierKeyPair = PaillierKeyPair.generate(2048);
  await saveMyPaillierPrivateKey(paillierKeyPair.privateKey);
  await saveMyPaillierPublicKey(paillierKeyPair.publicKey);*/
  runApp(LoginPage());
}
