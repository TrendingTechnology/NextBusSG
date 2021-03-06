import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nextbussg/components/core/buttons/button.dart';
import 'package:nextbussg/components/core/line.dart';
import 'package:nextbussg/components/core/loading/loading_text.dart';
import 'package:nextbussg/services/bus.dart';
import 'package:nextbussg/services/location.dart';
import 'package:nextbussg/styles/values.dart';
import 'package:nextbussg/utils/extensions.dart';
import 'package:nextbussg/components/core/page_template.dart';
import 'package:nextbussg/components/core/space.dart';
import 'package:nextbussg/components/home/bus_stop_list.dart';
import 'package:nextbussg/components/home/favorites/favorites_list.dart';
import 'package:nextbussg/providers/favorites.dart';
import 'package:nextbussg/providers/home_rebuilder.dart';
import 'package:nextbussg/utils/strings.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // this is there to rebuild the home page when required (reloading)
    final HomeRebuilderProvider homeRebuilderProvider =
        Provider.of<HomeRebuilderProvider>(context, listen: true);

    print("Home page build");

    // slide to refresh
    // RefreshController _refreshController = RefreshController(initialRefresh: false);
    // TODO: implement pull to refresh

    return FutureBuilder(
      future: getHomeWidgets(context),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            body: PageTemplate(
              children: snapshot.data,
            ),
          );
        } else
          return Scaffold(
            body: Padding(
              padding: EdgeInsets.all(Values.pageHorizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  LoadingText(text: "Finding location ..."),
                ],
              ),
            ),
          );
      },
    );
  }

  Future<List<Widget>> getHomeWidgets(context) async {
    Widget nearMe = BusStopList(
      title: Strings.nearMeTitle.toUpperCase(),
      iconData: FontAwesomeIcons.locationArrow,
    );

    // if there are no favorites (in simlified favorites view), the favorites heading should come below near me
    // if there are in SFV, put favorites at the top

    List<Widget> widgetOrder = [
      simplifiedFavoritesView(),
      Spacing(height: 40).sliver(),
      nearMe,
      Spacing(height: 20).sliver(),
      Line().sliverToBoxAdapter(),
      Spacing(height: 20).sliver(),
      reloadButton(context).sliverToBoxAdapter(),
    ];

    // if there are no favorites, swap the position of favorites and near me
    List favorites = await FavoritesProvider.getFavorites(context, simplified: true);
    if (favorites.isEmpty) {
      // even if the SF list is empty, there may be bus stops which are not near us. That's why
      // we check if the list is empty, then check the ACTUAL amount of favorites
      // if it's more than 0, it means that it's not showing

      // so just to make it clear to the user, display a message:
      // You have 3 favorites, which are not near you.

      var noFavorites = (await FavoritesProvider.getFavorites(context, simplified: false)).length;
      widgetOrder = [
        nearMe,
        Spacing(height: 40).sliver(),
        simplifiedFavoritesView(favoritesNotShown: noFavorites),
        Spacing(height: 20).sliver(),
        Line().sliverToBoxAdapter(),
        Spacing(height: 20).sliver(),
        reloadButton(context).sliverToBoxAdapter(),
      ];
    }
    return widgetOrder;
  }

  Widget simplifiedFavoritesView({int favoritesNotShown = 0}) => FavoritesBusStopList(
        title: Strings.simplifiedFavoritesTitle.toUpperCase(),
        iconData: FontAwesomeIcons.heart,
        simplified: true,
        favoritesNotShown: favoritesNotShown,
      );

  Widget reloadButton(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Button(
            color: Colors.grey,
            text: "Refresh",
            iconData: FontAwesomeIcons.redoAlt,
            onTap: () async {
              BotToast.showText(text: "Reloading ...");
              // reload getting of location and bus stops nearby
              print("Getting new location");
              Provider.of<LocationServicesProvider>(context, listen: false)
                  .getLocation(context, reload: true)
                  .then(
                (_) {
                  print("Getting new bus stops");
                  Provider.of<BusServiceProvider>(context, listen: false)
                      .getNearestStops(context, reload: true)
                      .then(
                    (_) {
                      // rebuild home
                      print("Rebuilding home");
                      Provider.of<HomeRebuilderProvider>(context, listen: false).rebuild();

                      BotToast.showText(text: "Reloaded");
                    },
                  );
                },
              );
            },
          ),
        ],
      );
}
