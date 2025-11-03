// lib/screen/coin_wallet_screen/widget/coin_wallet_list.dart

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/extensions/common_extension.dart';
import 'package:bubbly/common/widget/text_button_custom.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/general/settings_model.dart';
import 'package:bubbly/screen/coin_wallet_screen/coin_wallet_screen_controller.dart';
import 'package:bubbly/utilities/asset_res.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';

class CoinWalletList extends StatelessWidget {
  final CoinWalletScreenController controller;

  const CoinWalletList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(
            () {
          if (controller.coinPlans.isEmpty) {
            return Center(
              child: Text(
                LKey.noCoinPackagesAvailable.tr,
                style: TextStyleCustom.outFitRegular400(
                  color: textLightGrey(context),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 20),
            itemCount: controller.coinPlans.length,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (context, index) {
              CoinPackage data = controller.coinPlans[index];
              return _buildCoinPackageItem(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildCoinPackageItem(BuildContext context, CoinPackage data) {
    return Container(
      height: 70,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 10,
            cornerSmoothing: 1,
          ),
          side: BorderSide(
            color: textLightGrey(context).withValues(alpha: .2),
          ),
        ),
        color: bgLightGrey(context),
      ),
      child: Row(
        children: [
          Image.asset(AssetRes.icCoin, width: 34, height: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${data.coinAmount ?? 0} ${LKey.coins.tr}',
                  style: TextStyleCustom.unboundedMedium500(
                    color: textDarkGrey(context),
                    fontSize: 15,
                  ),
                ),
                Text(
                  _formatPrice(data.coinPlanPrice),
                  style: TextStyleCustom.outFitRegular400(
                    color: textLightGrey(context),
                  ),
                ),
              ],
            ),
          ),
          TextButtonCustom(
            onTap: () => controller.onPurchase(data),
            title: LKey.purchase.tr,
            backgroundColor: themeAccentSolid(context),
            btnHeight: 40,
            fontSize: 15,
            titleColor: whitePure(context),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            horizontalMargin: 0,
          ),
        ],
      ),
    );
  }

  String _formatPrice(num? price) {
    if (price == null) return '';

    // يمكنك تخصيص تنسيق السعر حسب العملة المستخدمة
    // هنا نستخدم تنسيق بسيط مع رقمين عشريين
    return '${price.toStringAsFixed(2)} ${controller.settings?.currency ?? 'USD'}';
  }
}