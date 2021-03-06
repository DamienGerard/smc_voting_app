import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

import 'package:smc_voting_app/utils/Node.dart';
import 'package:smc_voting_app/utils/candidate.dart';
import 'package:smc_voting_app/utils/election.dart';
import 'package:smc_voting_app/utils/paillier_encrpyt/paillier_key_pair.dart';
import 'package:smc_voting_app/utils/peer.dart';
import 'package:smc_voting_app/utils/services.dart';
import 'package:smc_voting_app/utils/verifier.dart';

const List<String> defArgs = ['voter1', 'voter1'];

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    arguments = defArgs;
  }
  exitCode = 0;
  final parser = ArgParser();
  final argResults = parser.parse(arguments);
  identifier = argResults.rest[0];
  var username = argResults.rest[0];
  var password = argResults.rest[1];
  var basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));

  var headers = {'Authorization': basicAuth};
  var request =
      http.MultipartRequest('POST', Uri.parse('$urlEA/voter_test_login'));

  request.headers.addAll(headers);

  var ipAddress = '192.168.8.104';
  var respondingPort = await getUnusedPort(ipAddress);

  request.fields.addAll(
      {'ip_address': ipAddress, 'responding_port': respondingPort.toString()});

  print('Local Id: ${await getLocalID()}');
  print('username: ${username}');
  if (username != await getLocalID()) {
    print('saving');
    await saveLocalID(username);
    var rsaKeyPair = generateRSAkeyPair(bitLength: 2048);
    await saveMyRSAPrivateKey(rsaKeyPair.privateKey);
    await saveMyRSAPublicKey(rsaKeyPair.publicKey); /**/
    var paillierKeyPair = PaillierKeyPair.generate(2048);
    await saveMyPaillierPrivateKey(paillierKeyPair.privateKey);
    await saveMyPaillierPublicKey(paillierKeyPair.publicKey);
    var public_key_str = jsonEncode({
      'rsa': {
        'modulus': rsaKeyPair.publicKey.modulus.toString(),
        'exponent': rsaKeyPair.publicKey.exponent.toString()
      },
      'paillier': {
        'g': paillierKeyPair.publicKey.g.toString(),
        'n': paillierKeyPair.publicKey.n.toString(),
        'bits': paillierKeyPair.publicKey.bits,
        'nSquared': paillierKeyPair.publicKey.nSquared.toString()
      }
    });
    request.fields.addAll({
      'public_key': public_key_str,
    });
  }

  var response = await request.send();

  if (response.statusCode == 200) {
    var resStr = await response.stream.bytesToString();
    print(resStr);
    Map<String, dynamic> resJson = jsonDecode(resStr);
    await saveMyShareNum(BigInt.from(resJson['yourShareNum']));
    var candidatesJson =
        List<Map<String, dynamic>>.from(resJson['candidatesJson']);
    Candidate candidateTemp;
    for (final candidateJson in candidatesJson) {
      candidateTemp = Candidate.fromJson(candidateJson);
      await candidateTemp.save(candidateJson['election_id']);
    }
    var electionsJson =
        List<Map<String, dynamic>>.from(resJson['electionsJson']);
    Election electionTemp;
    for (final electionJson in electionsJson) {
      electionTemp =
          (await Election.fromJson(electionJson, toConstruct: false))!;
      await electionTemp.save();
    }
    var peersJson = List<Map<String, dynamic>>.from(resJson['peersJson']);
    Peer peerTemp;
    for (var peerJson in peersJson) {
      peerJson['public_key'] = jsonDecode(peerJson['public_key']);
      peerTemp = Peer.fromJson(peerJson);
      await peerTemp.save();
    }
    var verifiersJson =
        List<Map<String, dynamic>>.from(resJson['verifiersJson']);
    Verifier verifierTemp;
    for (var verifierJson in verifiersJson) {
      verifierJson['public_key'] = jsonDecode(verifierJson['public_key']);
      verifierTemp = Verifier.fromJson(verifierJson);
      await verifierTemp.save();
    }

    var node = await Node.getNode(ipAddress, respondingPort);

    var mainToIsolateStream = await initMenuIsolate(node, node.mapElections);
    mainToIsolateStream.send({'elections': node.mapElections});
  } else {
    print(response.reasonPhrase ?? 'FAIL');
  }

  print("ending");
}

Future<SendPort> initMenuIsolate(
    Node node, Map<String, Election> elections) async {
  Completer<SendPort> completer = Completer<SendPort>();
  var isolateToMainStream = ReceivePort();

  // ignore: unused_local_variable
  var myIsolateInstance =
      await Isolate.spawn(myIsolate, isolateToMainStream.sendPort);
  var mainToIsolateStream = ReceivePort().sendPort;
  isolateToMainStream.listen((data) {
    if (data is SendPort) {
      mainToIsolateStream = data;
      completer.complete(mainToIsolateStream);
    } else if (data is String && data == 'reload') {
      print('reloading menu');
      mainToIsolateStream.send({'elections': node.mapElections});
    } else {
      node.mapElections[data['election_id']]!.castVote(data['candidate_id']);
    }
  });

  return completer.future as Future<SendPort>;
}

Future<void> myIsolate(SendPort isolateToMainStream) async {
  var elections = <String, Election>{};
  var futureElections = <String, Election>{};
  var ongoingElections = <String, Election>{};
  var pastElections = <String, Election>{};

  var mainToIsolateStream = ReceivePort();
  isolateToMainStream.send(mainToIsolateStream.sendPort);

  mainToIsolateStream.listen((electionsJson) {
    elections = electionsJson['elections'];
  });

  await Future.delayed(const Duration(seconds: 1));

  Election? electionToDisplay;
  var input;
  while (input != '-1') {
    isolateToMainStream.send('reload');
    await Future.delayed(Duration(seconds: 4));
    futureElections.clear();
    ongoingElections.clear();
    pastElections.clear();
    elections.forEach((electionId, electionObj) {
      if (DateTime.now().compareTo(electionObj.voting_time) < 0) {
        futureElections[electionId] = electionObj;
      } else if (DateTime.now().compareTo(electionObj.voting_time) >= 0 &&
          DateTime.now().compareTo(electionObj.tallying_time) < 0) {
        ongoingElections[electionId] = electionObj;
      } else if (DateTime.now().compareTo(electionObj.tallying_time) >= 0) {
        pastElections[electionId] = electionObj;
      }
    });
    //
    print('\n\nFUTURE ELECTIONS');
    futureElections.forEach((election_id, election) {
      print(
          '${election.election_id}\t${election.name}\t${election.voting_time} - ${election.tallying_time}');
    });
    print('ONGOING ELECTIONS');
    ongoingElections.forEach((election_id, election) {
      print(
          '${election.election_id}\t${election.name}\t${election.voting_time} - ${election.tallying_time}');
    });

    print('PAST ELECTIONS');
    pastElections.forEach((election_id, election) {
      print(
          '${election.election_id}\t${election.name}\t${election.voting_time} - ${election.tallying_time}');
    });
    print(
        '\n\nEnter the election id you want to proceed with(or -1 to stop): ');

    input = stdin.readLineSync();

    if (ongoingElections.containsKey(input)) {
      electionToDisplay = ongoingElections[input];
      print(
          '${electionToDisplay!.election_id}\t${electionToDisplay.name}\t${electionToDisplay.voting_time} - ${electionToDisplay.tallying_time}');
      print('CANDIDATES\n');
      var candidatesHeaders = 'Candidate id\tCandidate name\tCandidate party';

      print(candidatesHeaders);
      var candidates = electionToDisplay.getCandidates();
      var candidateStr;
      for (final candidate in candidates) {
        candidateStr =
            '${candidate.candidate_id}\t${candidate.name}\t${candidate.party}';

        print(candidateStr);
      }
      print('Enter the id of a candidate to vote for them(or -1 to go back): ');
      input = stdin.readLineSync();
      if (input != '-1') {
        isolateToMainStream.send({
          'election_id': electionToDisplay.election_id,
          'candidate_id': input
        });
      }
    } else if (futureElections.containsKey(input) ||
        pastElections.containsKey(input)) {
      if (futureElections.containsKey(input)) {
        electionToDisplay = futureElections[input];
      } else {
        electionToDisplay = pastElections[input];
      }

      print(
          '${electionToDisplay!.election_id}\t${electionToDisplay.name}\t${electionToDisplay.voting_time} - ${electionToDisplay.tallying_time}');
      print('CANDIDATES\n');
      var candidatesHeaders = 'Candidate id\tCandidate name\tCandidate party';
      if (pastElections.containsKey(electionToDisplay.election_id)) {
        candidatesHeaders += '\tVotes';
      }
      print(candidatesHeaders);
      var candidates = electionToDisplay.getCandidates();
      var candidateStr;
      for (final candidate in candidates) {
        candidateStr =
            '${candidate.candidate_id}\t${candidate.name}\t${candidate.party}';
        if (pastElections.containsKey(electionToDisplay.election_id)) {
          candidateStr += '\t${candidate.tally}';
        }
        print(candidateStr);
      }
      print('Enter anything to go back: ');
      input = stdin.readLineSync();
    }
  }
}
