import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cool_dropdown/cool_dropdown.dart';
import 'package:cool_dropdown/models/cool_dropdown_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:list_of_utils/app/data/const.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class NewsAPI extends StatelessWidget {
  const NewsAPI({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<NewsAPIController>(
      builder: (controller) => Scaffold(
          backgroundColor: KColor.white,
          appBar: _appbar(),
          body: controller.newsTopHeadline.isEmpty
              ? LoadingAnimationWidget.hexagonDots(
                  color: KColor.primary, size: 35)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hot News 🔥', style: KStyle.headline)
                        .paddingSymmetric(horizontal: KPadding.all.left)
                        .marginSymmetric(vertical: spacing),
                    CarouselSlider.builder(
                        itemCount: controller.newsTopHeadline.length,
                        options: CarouselOptions(height: 250),
                        itemBuilder: (context, index, realIndex) {
                          return _imageCarousel(
                              controller.newsTopHeadline[index]);
                        }).marginOnly(bottom: spacing),
                    Expanded(
                      child: DefaultTabController(
                        length: categories.length,
                        child: Column(
                          children: <Widget>[
                            _tabbarButton(controller),
                            Expanded(
                              child: TabBarView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: List.generate(
                                      categories.length,
                                      (index) => _listNewsCategories(
                                          list: categories[index].values.first,
                                          category:
                                              categories[index].keys.first))),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                )),
    );
  }

  ///[Tabbar Button]
  SizedBox _tabbarButton(NewsAPIController controller) {
    return SizedBox(
      height: 80,
      child: Card(
        elevation: 9,
        color: KColor.black,
        margin: KPadding.horizontal.add(const EdgeInsets.only(bottom: 10)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ButtonsTabBar(
                onTap: (index) {
                  controller.getRequest(
                      category: categories[index].keys.first,
                      list: categories[index].values.first);
                },
                unselectedBackgroundColor: Colors.transparent,
                unselectedLabelStyle: KStyle.body.copyWith(color: KColor.white),
                radius: 10,
                backgroundColor: KColor.primary,
                labelStyle: KStyle.body
                    .copyWith(fontWeight: FontWeight.bold, color: KColor.white),
                contentPadding: KPadding.horizontal,
                tabs: List.generate(
                    categories.length,
                    (index) => Tab(
                          text: categories[index].keys.first.capitalizeFirst,
                        ))),
          ),
        ),
      ),
    );
  }

  ///[ ListView News Tabbar]
  _listNewsCategories({required List<News> list, required String category}) {
    final _ = Get.find<NewsAPIController>();
    return list.isEmpty
        ? Center(
            child: LoadingAnimationWidget.fallingDot(
                color: KColor.primary, size: 35),
          )
        : RefreshIndicator(
            onRefresh: () =>
                _.getRequest(category: category, list: list, refresh: true),
            color: KColor.primary,
            child: ListView.builder(
                padding: KPadding.all,
                itemCount: list.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  var news = list[index];
                  return SizedBox(
                    height: 120,
                    child: Card(
                        color: KColor.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Card(
                                        elevation: 0,
                                        color: KColor.primary,
                                        margin: EdgeInsets.zero,
                                        child: Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: Text(news.source.name,
                                              style: KStyle.body.copyWith(
                                                  color: KColor.white,
                                                  fontSize: 10)),
                                        )),
                                    Container(
                                      alignment: Alignment.center,
                                      height: 40,
                                      child: Text(
                                        news.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: KStyle.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: KColor.black),
                                      ),
                                    ),
                                    Text('${news.publishedAt}'.substring(0, 10),
                                        style: KStyle.italic),
                                  ],
                                ),
                              ),
                              AspectRatio(
                                aspectRatio: 1 / 1,
                                child: Card(
                                  color: KColor.white,
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5)),
                                  elevation: 0,
                                  child: news.urlToImage == null
                                      ? Container(
                                          color: KColor.black,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.error_outline_outlined,
                                                color: KColor.white,
                                                size: 18,
                                              ),
                                              Text('No Image',
                                                  style: KStyle.body.copyWith(
                                                      color: KColor.white,
                                                      fontSize: 10)),
                                            ],
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: news.urlToImage,
                                          progressIndicatorBuilder: (context,
                                                  url, downloadProgress) =>
                                              LoadingAnimationWidget.fallingDot(
                                                  color: KColor.primary,
                                                  size: 35),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  );
                }),
          );
  }

  ///[ Image Carousel]
  Card _imageCarousel(News news) {
    return Card(
      margin: KPadding.vertical.add(const EdgeInsets.symmetric(horizontal: 4)),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 9,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          news.urlToImage == null
              ? Container(
                  color: KColor.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_outlined,
                        color: KColor.white,
                      ).marginSymmetric(horizontal: spacing),
                      Text('No Image',
                          style: KStyle.headline.copyWith(color: KColor.white)),
                    ],
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: news.urlToImage,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      LoadingAnimationWidget.fallingDot(
                          color: KColor.primary, size: 35),
                  errorWidget: (context, url, error) => Container(
                    color: KColor.black,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_outlined,
                          color: KColor.white,
                        ).marginSymmetric(horizontal: spacing),
                        Text('No Image',
                            style:
                                KStyle.headline.copyWith(color: KColor.white)),
                      ],
                    ),
                  ),
                  fit: BoxFit.cover,
                ),
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [KColor.black, Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter)),
          ),
          Padding(
            padding: const EdgeInsets.all(11.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${news.publishedAt}'.substring(0, 10),
                    style: KStyle.italic.copyWith(color: KColor.white)),
                Text(news.title,
                    style: KStyle.headline.copyWith(color: KColor.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ///[ App Bar]
  AppBar _appbar() {
    final _ = Get.find<NewsAPIController>();
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: KColor.white,
      systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: KColor.white),
      title: Text(
        'News',
        style: KStyle.body.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Icon(
        Icons.arrow_back_ios_new,
        color: KColor.black,
      ),
      actions: [
        SizedBox(
          width: 130,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
            child: CoolDropdown(
              resultOptions: ResultOptions(
                  openBoxDecoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border: Border.all(color: KColor.primary),
                      boxShadow: [
                    BoxShadow(
                        color: KColor.black.withOpacity(.3),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 1))
                  ])),
              dropdownTriangleOptions: const DropdownTriangleOptions(
                  align: DropdownTriangleAlign.right),
              defaultItem: CoolDropdownItem(label: '🇺🇸 America', value: 'us'),
              dropdownOptions: DropdownOptions(
                color: KColor.white,
                width: 100,
                height: 300,
                borderRadius: BorderRadius.circular(10),
                padding: KPadding.all,
                shadows: [
                  BoxShadow(
                      color: KColor.black.withOpacity(.3),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
                curve: Curves.fastEaseInToSlowEaseOut,
              ),
              dropdownItemOptions: DropdownItemOptions(
                  textStyle: KStyle.body,
                  selectedTextStyle: KStyle.body.copyWith(color: KColor.white),
                  selectedBoxDecoration: BoxDecoration(color: KColor.primary)),
              isMarquee: true,
              dropdownList: countries,
              controller: _.countryDropdownC,
              onChange: (p0) {
                _.changeCountry(p0);
              },
            ),
          ),
        )
      ],
    );
  }
}

///[ Categories]
final List<Map<String, List<News>>> categories = [
  {'business': <News>[]},
  {'entertainment': <News>[]},
  {'general': <News>[]},
  {'health': <News>[]},
  {'science': <News>[]},
  {'sports': <News>[]},
  {'technology': <News>[]},
];

///[List Country]
final List<CoolDropdownItem> countries = [
  CoolDropdownItem(label: '🇺🇸 USA', value: 'us'),
  CoolDropdownItem(label: '🇮🇩 Indonesia', value: 'id'),
  CoolDropdownItem(label: '🇦🇪 UAE', value: 'ae'),
  CoolDropdownItem(label: '🇦🇷 Argentina', value: 'ar'),
  CoolDropdownItem(label: '🇦🇺 Australia', value: 'au'),
  CoolDropdownItem(label: '🇲🇾 Malaysia', value: 'my'),
  CoolDropdownItem(label: '🇯🇵 Japan', value: 'jp'),
];

///[ GetxController]
class NewsAPIController extends GetxController {
  //! Set ur API Key
  String apiKey = '';
  String country = 'us';
  var newsTopHeadline = <News>[].obs;
  final countryDropdownC = DropdownController();

  @override
  void onInit() {
    getHeadline();
    // To get data category business when launch app
    getRequest(
        category: categories[0].keys.first, list: categories[0].values.first);
    super.onInit();
  }

//  When country gets changed
  Future<void> changeCountry(String value) async {
    if (countryDropdownC.isOpen) {
      countryDropdownC.close();
    }
    country = value;
    update();
    // Clear all list
    newsTopHeadline.clear();
    for (var e in categories) {
      e.values.first.clear();
    }
    // Get request again
    getHeadline();
    // To get data category business when launch app
    getRequest(
        category: categories[0].keys.first, list: categories[0].values.first);
  }

  // Get News Top Headline
  Future<void> getHeadline() async {
    String url =
        'https://newsapi.org/v2/top-headlines?country=$country&apiKey=$apiKey';
    try {
      var response = await http.get(Uri.parse(url));
      var decode = jsonDecode(response.body);
      if (decode['status'] == 'ok') {
        List data = ((decode as Map<String, dynamic>))['articles'];
        for (var news in data) {
          newsTopHeadline.add(News.fromJson(news));
          update();
        }
      }
      if (decode['status'] == 'error') {
        Get.closeAllSnackbars();
        Get.showSnackbar(GetSnackBar(
          backgroundColor: KColor.primary,
          title: '${decode["code"]}'.capitalizeFirst,
          message: '${decode["message"]}'.capitalizeFirst,
        ));
      }
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        message: e.toString(),
      ));
    }
  }

  // Get Request When User Tap Tabbar
  Future<void> getRequest(
      {required String category,
      required List<News> list,
      bool? refresh = false}) async {
    String url =
        'https://newsapi.org/v2/top-headlines?category=$category&country=$country&apiKey=$apiKey';
    if (list.isEmpty || refresh == true) {
      try {
        var response = await http.get(Uri.parse(url));
        var decode = jsonDecode(response.body);
        if (decode['status'] == 'ok') {
          List data = ((decode as Map<String, dynamic>))['articles'];
          if (refresh == true) {
            list.clear();
            update();
          }
          for (var news in data) {
            list.add(News.fromJson(news));
            update();
          }
        }
      } catch (e) {
        Get.showSnackbar(GetSnackBar(
          message: e.toString(),
        ));
      }
    }
  }
}

///[ Models]
class News {
  final Source source;
  final String author;
  final String title;
  final dynamic description;
  final String url;
  final dynamic urlToImage;
  final DateTime publishedAt;
  final dynamic content;

  News({
    required this.source,
    required this.author,
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.publishedAt,
    required this.content,
  });

  factory News.fromJson(Map<String, dynamic> json) => News(
        source: Source.fromJson(json["source"]),
        author: json["author"] ?? '',
        title: json["title"] ?? '',
        description: json["description"] ?? '',
        url: json["url"] ?? '',
        urlToImage: json["urlToImage"],
        publishedAt: DateTime.parse(json["publishedAt"]),
        content: json["content"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "source": source.toJson(),
        "author": author,
        "title": title,
        "description": description,
        "url": url,
        "urlToImage": urlToImage,
        "publishedAt": publishedAt.toIso8601String(),
        "content": content,
      };
}

class Source {
  final String id;
  final String name;

  Source({
    required this.id,
    required this.name,
  });

  factory Source.fromJson(Map<String, dynamic> json) => Source(
        id: json["id"] ?? '',
        name: json["name"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}
