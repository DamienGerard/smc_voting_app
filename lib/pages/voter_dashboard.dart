import 'dart:convert';

import 'package:smc_voting_app/pages/election_ballot.dart';
import 'package:smc_voting_app/pages/election_info_page.dart';
import 'package:smc_voting_app/pages/future_election_page.dart';
import 'package:smc_voting_app/utils/Node.dart';
import 'package:smc_voting_app/utils/candidate.dart';
import 'package:smc_voting_app/utils/election.dart';
import 'package:flutter/material.dart';
import 'package:smc_voting_app/utils/services.dart';
import 'package:http/http.dart' as http;

class VoterDashboard extends StatefulWidget {
  Node node;

  VoterDashboard(this.node);

  @override
  _VoterDashboardState createState() => _VoterDashboardState(node);
}

class _VoterDashboardState extends State<VoterDashboard> {
  Node node;
  _VoterDashboardState(this.node);

  @override
  Widget build(BuildContext context) {
    var futureElections = <ElectionCard>[];
    var ongoingElections = <ElectionCard>[];
    var pastElections = <ElectionCard>[];

    node.mapElections.forEach((electionId, electionObj) {
      if (DateTime.now().compareTo(electionObj.voting_time) < 0) {
        futureElections.add(new ElectionCard(electionObj));
      } else if (DateTime.now().compareTo(electionObj.voting_time) >= 0 &&
          DateTime.now().compareTo(electionObj.tallying_time) < 0) {
        ongoingElections.add(new ElectionCard(electionObj));
      } else if (DateTime.now().compareTo(electionObj.tallying_time) >= 0) {
        pastElections.add(new ElectionCard(electionObj));
      }
    });

    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(text: 'Future elections'),
                Tab(text: 'Ongoing elections'),
                Tab(text: 'Past elections'),
              ],
            ),
            title: Text('Voter Dashboard'),
          ),
          body: TabBarView(
            children: [
              ListView(
                padding: const EdgeInsets.all(8),
                children: futureElections,
              ),
              ListView(
                padding: const EdgeInsets.all(8),
                children: ongoingElections,
              ),
              ListView(
                padding: const EdgeInsets.all(8),
                children: pastElections,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              print('Reload pressed');
              var response = await http.get(Uri.parse('$urlEA/elections'));

              if (response.statusCode == 200) {
                String resStr = response.body;
                Map<String, dynamic> resJson = jsonDecode(resStr);
                print(resJson['electionsJson']);
                List<Map<String, dynamic>> electionsJson =
                    List<Map<String, dynamic>>.from(resJson["electionsJson"]);
                List<Map<String, dynamic>> candidatesJson =
                    List<Map<String, dynamic>>.from(resJson["candidatesJson"]);
                Candidate candidateTemp;
                var electionsToKillIds =
                    List<String>.from(node.mapElections.keys);
                print('elections to kill');
                print(electionsToKillIds);
                for (final electionJson in electionsJson) {
                  if (electionsToKillIds
                      .contains(electionJson['election_id'])) {
                    electionsToKillIds.remove(electionJson['election_id']);
                  }
                }

                for (final electionId in electionsToKillIds) {
                  await node.mapElections[electionId]!.delete();
                  node.mapElections.remove(electionId);
                }

                for (var candidateJson in candidatesJson) {
                  if (!node.mapElections
                      .containsKey(candidateJson['election_id'])) {
                    candidateTemp = Candidate.fromJson(candidateJson);
                    await candidateTemp.save(candidateJson['election_id']);
                  }
                }
                Election electionTemp;
                for (final electionJson in electionsJson) {
                  if (!node.mapElections
                      .containsKey(electionJson['election_id'])) {
                    electionJson['has_voted'] = 0;
                    electionTemp = (await Election.fromJson(electionJson))!;
                    node.mapElections[electionTemp.election_id] = electionTemp;
                    await electionTemp.save();
                  }
                }
              } else {
                print(response.reasonPhrase);
              }
              setState(() {});
            },
            child: const Icon(Icons.refresh_sharp),
            backgroundColor: Colors.green,
          ),
        ),
      ),
    );
  }
}

class ElectionCard extends StatelessWidget {
  final Election election;

  ElectionCard(this.election);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 3.0),
        child: SizedBox(
          height: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: Text(
                    election.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
              Expanded(
                flex: 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('start:  ',
                            style:
                                TextStyle(fontSize: 15, color: Colors.black)),
                        Text(election.voting_time.toString().substring(0, 16),
                            style:
                                TextStyle(fontSize: 15, color: Colors.indigo)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('end:  ',
                            style:
                                TextStyle(fontSize: 15, color: Colors.black)),
                        Text(election.tallying_time.toString().substring(0, 16),
                            style:
                                TextStyle(fontSize: 15, color: Colors.indigo)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        if (DateTime.now().compareTo(election.voting_time) < 0) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ElectionInfoPage(election)));
        } else if (DateTime.now().compareTo(election.voting_time) >= 0 &&
            DateTime.now().compareTo(election.tallying_time) < 0) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ElectionBallotForm(election: election)));
        } else if (DateTime.now().compareTo(election.tallying_time) >= 0) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ElectionInfoPage(election)));
        }
        print("tapped on container");
      },
    );
  }
}
