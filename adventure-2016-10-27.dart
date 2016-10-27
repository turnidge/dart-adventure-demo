import 'dart:async';
import 'dart:convert';
import 'dart:io';

class Player {
  Player(this.currentRoom);

  Room currentRoom;
  List inventory = [];

  Item findItem(String name) {
    for (var item in inventory) {
      if (item.name == name) {
	return item;
      }
    }
    return null;  // null means nothing.
  }
}

class Item {
  Item(this.name, this.description);

  void printDescription() {
    if (description != null) {
      stdout.writeln(description);
    }
  }

  void printInventoryDescription() {
    stdout.writeln(name);
  }

  void onOil() {
    stdout.writeln('Um... ok.');
  }

  void onShoot() {
    stdout.writeln('A ${name} is not a thing that can be shot, per se.');
  }

  String name;
  String description;
  bool heavy = false;
}

class Revolver extends Item {
  Revolver(name, description) : super(name, description);

  void onOil() {
    stdout.writeln('Oiled');
    rusty = false;
    theItem2.description = 'A shiny revolver is here.';
  }

  void onShoot() {
    if (rusty) {
      stdout.writeln('The ${name} is too rusty to shoot.');
    } else {
      stdout.writeln('The ${name} backfires... you die.\n\n');
      die();
    }
  }

  bool rusty = true;
}

class Room {
  Room(this.description);

  void printDescription() {
    stdout.writeln(description);
    for (var item in items) {
      item.printDescription();
    }
  }

  String description;
  Map exits = {};
  List items = [];
}

void doCommand(Player player, String command) {
  var words = command.split(' ');

  var currentRoom = player.currentRoom;
  if (command == 'look') {
    currentRoom.printDescription();
  } else if (words[0] == 'take' || words[0] == 'get') {
    var name = words[1];
    var theItem;
    for (var item in currentRoom.items) {
      if (item.name == name) {
	theItem = item;
      }
    }
    if (theItem == null) {
      stdout.writeln('I don\'t see that here.  Are you crazy?');
    } else if (theItem.heavy) {
      stdout.writeln('Even a strongman couldn\'t pick that up!');
    } else {
      currentRoom.items.remove(theItem);
      player.inventory.add(theItem);
      stdout.writeln('Taken');
    }
  } else if (words[0] == 'drop') {
    var name = words[1];
    var theItem = player.findItem(name);
    if (theItem == null) {
      stdout.writeln('You aren\'t carrying that.  Are you hallucinating?');
    } else {
      player.inventory.remove(theItem);
      currentRoom.items.add(theItem);
      stdout.writeln('Dropped');
    }
  } else if (words[0] == 'shoot') {
    var theItem = player.findItem(words[1]);
    if (theItem == null) {
      stdout.writeln('You aren\'t carrying that.  Bang?');
    } else {
      theItem.onShoot();
    }
  } else if (words[0] == 'oil') {
    var theItem = player.findItem('oilcan');
     if (theItem == null) {
       stdout.writeln('You aren\'t carrying any oil.');
     } else {
       var theItem2 = player.findItem(words[1]);
       //if (theItem2 == null) {
       // stdout.writeln('You can\'t oil something you\'re not carrying');
       // } else {
       theItem2.onOil();
       //}
    }
  } else if (command.length > 0 && 'inventory'.startsWith(command)) {
    for (var item in player.inventory) {
      item.printInventoryDescription();
    }
  } else {
    var exitRoom = currentRoom.exits[command];
    if (exitRoom == null) {
      stdout.writeln('I don\'t know how to do that');
    } else {
      player.currentRoom = exitRoom;
      player.currentRoom.printDescription();
    }
  }
}

Player player = null;

void die() {
  stdout.writeln('            -------\n'
                 '           /       \\ \n'
                 '          /         \\      *  \n'
                 '          |  R I P  |     *@* \n'
                 '          |         |     \\|  \n'
                 '          |         |      |/ \n'
                 '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n\n\n');
  init();
}

void init() {
  var chamber = new Room("You are in a mysterious chamber. "
			 "There is an exit to the west.");
  var hallway = new Room("You are in a long, long east/west hallway "
			 "with doors on either side.  ");
  var mustyBedroom = new Room("You are in musty old bedroom with a "
			      "chest in the corner.  The exit is south.");
  var topOfStairs = new Room("You are at the top of a spiral staircase. "
			     "A hallway leads to the east.");
  var bottomOfStairs = new Room("You are at the bottom of a spiral staircase. "
				"There is a old wooden door to the north.");
  var workshop = new Room("You are in a cramped tinkerer's workshop. "
			  "A door leads to the north.");

  // Set up chamber.
  chamber.exits['west'] = hallway;

  chamber.items.add(new Item('mousetrap',
			     'A deadly mousetrap lies nearby.'));

  // Set up hallway.
  hallway.exits['east'] = chamber;
  hallway.exits['north'] = mustyBedroom;
  hallway.exits['west'] = topOfStairs;
  hallway.exits['south'] = workshop;

  // Set up musty bedroom.
  mustyBedroom.exits['south'] = hallway;

  mustyBedroom.items.add(new Revolver('revolver',
                                      'A rusty revolver is here.'));
  var chest = new Item('chest', null);
  chest.heavy = true;
  mustyBedroom.items.add(chest);

  // Set up top of stairs.
  topOfStairs.exits['east'] = hallway;
  topOfStairs.exits['down'] = bottomOfStairs;

  // Set up bottom of stairs.
  bottomOfStairs.exits['up'] = topOfStairs;

  var diary = new Item('diary', 'A scorched diary is discarded here.');
  bottomOfStairs.items.add(diary);

  // Set up workshop.
  workshop.exits['north'] = hallway;

  var oilcan = new Item('oilcan', 'An oilcan is here.');
  workshop.items.add(oilcan);

  player = new Player(chamber);

  // Show the player the first room.
  player.currentRoom.printDescription();
}

var subscription;

void handleCommand(command) {
  if (command.length > 0 && 'quit'.startsWith(command)) {
    stdout.writeln('Bye!  See you later!');
    subscription.cancel();
  } else {
    doCommand(player, command);
    stdout.write('> ');
  }
}

void main(String args) {
  try {
    init();

    var stream = stdin.transform(UTF8.decoder).transform(new LineSplitter());
    stdout.write('> ');
    subscription = stream.listen((command) { handleCommand(command); });
  } catch (e, st) {
    print('OOPS! -- $e\n$st');
  }
}
