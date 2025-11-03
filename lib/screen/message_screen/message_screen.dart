import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/widget/custom_search_text_field.dart';
import 'package:bubbly/common/widget/custom_tab_switcher.dart';
import 'package:bubbly/common/widget/no_data_widget.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/chat/chat_thread.dart';
import 'package:bubbly/screen/message_screen/message_screen_controller.dart';
import 'package:bubbly/screen/message_screen/widget/chat_conversation_user_card.dart';
import 'package:bubbly/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:bubbly/utilities/color_res.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MessageScreenController());

    // Fix: Check if dashboard controller is registered safely
    final bool isDashboardRegistered = Get.isRegistered<DashboardScreenController>();
    final bool shouldShowBackButton = showBackButton || !isDashboardRegistered;

    return Column(
      children: [
        Container(
          color: scaffoldBackgroundColor(context),
          child: SafeArea(
            minimum: const EdgeInsets.only(top: 15),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    children: [
                      // Show back button only if explicitly requested or if not in dashboard
                      if (shouldShowBackButton)
                        GestureDetector(
                          onTap: () {
                            print("get.back");
                            Get.back();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: textDarkGrey(context),
                              size: 20,
                            ),
                          ),
                        )
                      else
                      // Smart back button - goes to home tab if in dashboard
                        GestureDetector(
                          onTap: () {
                            print("Smart back - going to home");
                            if (isDashboardRegistered) {
                              try {
                                final dashboardController = Get.find<DashboardScreenController>();
                                dashboardController.onChanged(0); // Go to Home tab
                              } catch (e) {
                                print("Error finding dashboard controller: $e");
                                Get.back();
                              }
                            } else {
                              Get.back();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: textDarkGrey(context),
                              size: 20,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          LKey.messages.tr,
                          textAlign: TextAlign.center,
                          style: TextStyleCustom.unboundedMedium500(
                              fontSize: 15, color: textDarkGrey(context)),
                        ),
                      ),
                      // Placeholder to balance the back button
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
                CustomTabSwitcher(
                  items: controller.chatCategories,
                  onTap: (index) {
                    controller.onPageChanged(index);
                    controller.pageController.animateToPage(index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.linear);
                  },
                  selectedIndex: controller.selectedChatCategory,
                  widget: Obx(() {
                    int length = controller.requestsUsers.length;
                    if (length <= 0) {
                      return const SizedBox();
                    }
                    return Container(
                      height: 22,
                      width: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorRes.likeRed,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$length',
                        style: TextStyleCustom.outFitRegular400(
                            fontSize: 12, color: whitePure(context)),
                      ),
                    );
                  }),
                  widgetTabIndex: 1,
                  margin: const EdgeInsets.all(10),
                ),
              ],
            ),
          ),
        ),
        const CustomSearchTextField(),
        Expanded(
          child: PageView(
            controller: controller.pageController,
            onPageChanged: controller.onPageChanged,
            children: const [
              ChatsListView(),
              RequestsListView(),
            ],
          ),
        )
      ],
    );
  }
}

class ChatsListView extends StatelessWidget {
  const ChatsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final MessageScreenController controller = Get.find();
    return Obx(() {
      return NoDataView(
        showShow: controller.chatsUsers.isEmpty,
        title: LKey.chatListEmptyTitle.tr,
        description: LKey.chatListEmptyDescription.tr,
        child: ListView.builder(
          itemCount: controller.chatsUsers.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            ChatThread chatConversation = controller.chatsUsers[index];
            return ChatConversationUserCard(chatConversation: chatConversation);
          },
        ),
      );
    });
  }
}

class RequestsListView extends StatelessWidget {
  const RequestsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final MessageScreenController controller = Get.find();

    return Obx(
          () => NoDataView(
        showShow: controller.requestsUsers.isEmpty,
        title: LKey.chatRequestEmptyTitle.tr,
        description: LKey.chatRequestEmptyDescription.tr,
        child: ListView.builder(
          itemCount: controller.requestsUsers.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            ChatThread chatConversation = controller.requestsUsers[index];
            return ChatConversationUserCard(chatConversation: chatConversation);
          },
        ),
      ),
    );
  }
}