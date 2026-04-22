import 'package:altum_view/app/bootstrap.dart';

import 'altum_view_sdk.dart';


/// normal mode
//void main() => bootstrap();

/// sdk mode
void main() {
  AltumViewSDK.configure(
    embeddedMode: false,
    clientId: "nkJ1HznwgxwGBnB6",
    clientSecret: "m2HGxuNuzUk4JiKloTBOAlulv2odRhj9OkM6hzFKJQsSeBtcyLtYBDtGjxonfV3f",
    scope:
    "camera:write room:write alert:write person:write "
        "user:write group:write invitation:write person_info:write",
  );
}