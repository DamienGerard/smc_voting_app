import 'package:smc_voting_app/utils/candidate.dart';
import 'package:smc_voting_app/utils/election.dart';
import 'package:flutter/material.dart';

// Define a custom Form widget.
class ElectionBallotForm extends StatefulWidget {
  final Election election;

  ElectionBallotForm({Key? key, required this.election}) : super(key: key);

  @override
  ElectionBallotState createState() {
    return ElectionBallotState(election);
  }
}

// Define a corresponding State class.
// This class holds data related to the form.
class ElectionBallotState extends State<ElectionBallotForm> {
  final Election election;

  String chosenCandidateId = '';
  Candidate? chosenCandidate;
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.

  ElectionBallotState(this.election);

  @override
  Widget build(BuildContext context) {
    List<Widget> header = [
      Expanded(
          flex: 5,
          child: Text('Candidate name',
              style: TextStyle(fontSize: 18, color: Colors.black))),
      Expanded(
          flex: 3,
          child: Text('Party',
              style: TextStyle(fontSize: 18, color: Colors.black)))
    ];

    return Scaffold(
        appBar: AppBar(
          title: Text('Ballot'),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Column(
                children: [
                  Text(election.name,
                      style: TextStyle(fontSize: 30, color: Colors.black)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('start:  ',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.black)),
                          Text(election.voting_time.toString().substring(0, 16),
                              style: TextStyle(
                                  fontSize: 15, color: Colors.indigo)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('end:  ',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.black)),
                          Text(
                              election.tallying_time
                                  .toString()
                                  .substring(0, 16),
                              style: TextStyle(
                                  fontSize: 15, color: Colors.indigo)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.amber,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: header,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: election.getCandidates().length,
                itemBuilder: (BuildContext ctxt, int index) {
                  Color tileColour = Colors.white;
                  if (chosenCandidateId ==
                      election.getCandidates()[index].candidate_id) {
                    tileColour = Colors.green;
                  }
                  return ListTile(
                    //contentPadding: EdgeInsets.fromLTRB(2, 4, 2, 4),
                    tileColor: tileColour,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Hero(
                              tag:
                                  '${election.getCandidates()[index].name}__heroTag',
                              child: Text(
                                election.getCandidates()[index].name,
                                style: Theme.of(context).textTheme.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ),
                        Expanded(
                            flex: 4,
                            child: Text(
                              '${election.getCandidates()[index].party}',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.black),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )),
                      ],
                    ),
                    onTap: () {
                      if (chosenCandidateId !=
                          election.getCandidates()[index].candidate_id) {
                        setState(() {
                          chosenCandidateId =
                              election.getCandidates()[index].candidate_id;
                          chosenCandidate = election.getCandidates()[index];
                        });
                      } else {
                        setState(() {
                          chosenCandidateId = '';
                          chosenCandidate = null;
                        });
                      }
                    },
                  );
                },
              ),
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 55,
                  child: ElevatedButton(
                      onPressed: () {
                        if (election.hasVoted == 1) {
                          /*return*/ showDialog<void>(
                            context: context,
                            //barrierDismissible: false, // user must tap button!
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Already voted'),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: const <Widget>[
                                      Text('You have already voted.'),
                                      Text('You cannot vote more than once.'),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Ok'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }

                        /*if (election.hasVoted == 2) {
                          return showDialog<void>(
                            context: context,
                            //barrierDismissible: false, // user must tap button!
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Please wait'),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: const <Widget>[
                                      Text('You have already casted a ballot.'),
                                      Text(
                                          'Please wait while the system process your vote.'),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Ok'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }*/

                        if (chosenCandidateId == '') {
                          /*return*/ showDialog<void>(
                            context: context,
                            //barrierDismissible: false, // user must tap button!
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Invalid ballot'),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: const <Widget>[
                                      Text(
                                          'Please choose a candidate before casting your vote'),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Ok'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }

                        if (election.hasVoted == 1) {
                          /*return*/ showDialog<void>(
                            context: context,
                            //barrierDismissible: false, // user must tap button!
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Already voted'),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: const <Widget>[
                                      Text('You have already voted.'),
                                      Text('You cannot vote more than once.'),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Ok'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }

                        if (election.hasVoted >= 0) {
                          /*return*/ showDialog<void>(
                            context: context,
                            //barrierDismissible: false, // user must tap button!
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Review'),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: <Widget>[
                                      Text(
                                          'You are going to vote for ${chosenCandidate!.name} from the ${chosenCandidate!.party}'),
                                      Text('Do you want to proceed?'),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Yes'),
                                    onPressed: () {
                                      election.castVote(chosenCandidateId);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('No'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: Text('Cast my Vote',
                          style: TextStyle(fontSize: 15, color: Colors.white))),
                )),
          ],
        ));
  }
}
