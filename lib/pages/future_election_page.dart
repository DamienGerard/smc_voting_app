import 'dart:math';

import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  final List<String> litems = [
    "Item 1",
    "Item 2",
    "Item 3",
    "Item 4",
    "Item 5",
    "Item 6",
    "Item 7"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Hero List'),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white70,
              child: Column(
                children: [
                  Text('Election name',
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
                          Text('starting date time',
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
                          Text('ending date time',
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
                children: [
                  Text('Candidate name',
                      style: TextStyle(fontSize: 18, color: Colors.black)),
                  Text('Party',
                      style: TextStyle(fontSize: 18, color: Colors.black)),
                  Text('Votes',
                      style: TextStyle(fontSize: 18, color: Colors.black)),
                ],
              ) /*ListTile(
                //leading: Text('ID'),
                title: Text('Candidate Name'),
                trailing: Text('Votes'),
              )*/
              ,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: litems.length,
                itemBuilder: (BuildContext ctxt, int index) {
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Hero(
                              tag: '${litems[index]}__heroTag',
                              child: Text(
                                litems[index],
                                style: Theme.of(context).textTheme.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ),
                        Expanded(
                            flex: 1,
                            child: Text(
                              'party name',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.black),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )),
                      ],
                    ),
                    trailing:
                        /*IconButton(
                        icon: Icon(Icons.navigate_next),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ItemScreen(
                                      itemName: litems[index],
                                    )),
                          );
                        })*/
                        Text('${Random().nextInt(90) + 10}',
                            style:
                                TextStyle(fontSize: 18, color: Colors.purple)),
                  );
                },
              ),
            ),
          ],
        ));
  }
}

class ItemScreen extends StatelessWidget {
  final String itemName;

  const ItemScreen({required Key key, required this.itemName})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
      ),
      body: Container(
        child: Center(
          child: Hero(
            tag: '${itemName}__heroTag',
            child: Text(
              itemName,
              style: Theme.of(context).textTheme.title,
            ),
          ),
        ),
      ),
    );
  }
}
