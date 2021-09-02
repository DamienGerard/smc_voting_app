import 'dart:math';

import 'package:smc_voting_app/utils/election.dart';
import 'package:flutter/material.dart';

class ElectionInfoPage extends StatelessWidget {
  final Election election;

  ElectionInfoPage(this.election);

  @override
  Widget build(BuildContext context) {
    //final fakeTally = [15, 11, 4];
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
    if (DateTime.now().compareTo(election.tallying_time) >= 0) {
      header.add(Expanded(
          flex: 2,
          child: Text('Votes',
              style: TextStyle(fontSize: 18, color: Colors.black))));
    }
    var rng = new Random();
    return Scaffold(
        appBar: AppBar(
          title: Text('Election Info'),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white70,
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
                  if (DateTime.now().compareTo(election.voting_time) < 0) {
                    return ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 1,
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
                              flex: 1,
                              child: Text(
                                '${election.getCandidates()[index].party}',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.black),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      ),
                    );
                  } else {
                    var fakeTally = [5, 4, 2];
                    return ListTile(
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
                                style: TextStyle(
                                    fontSize: 18, color: Colors.black),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      ),
                      trailing: Text(
                          /*'${election.getCandidates()[index].tally}'*/ '${fakeTally[index]}',
                          style: TextStyle(fontSize: 18, color: Colors.purple)),
                    );
                  }
                },
              ),
            ),
          ],
        ));
  }
}
