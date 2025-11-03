// lib/common/service/api/gift_wallet_service.dart

import 'package:bubbly/common/service/api/api_service.dart';
import 'package:bubbly/common/service/utils/params.dart';
import 'package:bubbly/common/service/utils/web_service.dart';
import 'package:bubbly/model/general/status_model.dart';
import 'package:bubbly/model/gift_wallet/withdraw_model.dart';
 import 'package:bubbly/model/user_model/user_model.dart';
import 'package:bubbly/utilities/app_res.dart';

import '../../../model/payment/paytabs_payment_model.dart';

class GiftWalletService {
  GiftWalletService._();

  static final GiftWalletService instance = GiftWalletService._();

  Future<StatusModel> sendGift({int? userId, int? giftId}) async {
    StatusModel response = await ApiService.instance.call(
        url: WebService.giftWallet.sendGift,
        fromJson: StatusModel.fromJson,
        param: {Params.userId: userId, Params.giftId: giftId});
    return response;
  }

  Future<List<Withdraw>> fetchMyWithdrawalRequest({int? lastItemId}) async {
    WithdrawModel response = await ApiService.instance.call(
        url: WebService.giftWallet.fetchMyWithdrawalRequest,
        fromJson: WithdrawModel.fromJson,
        param: {
          Params.limit: AppRes.paginationLimit,
          Params.lastItemId: lastItemId,
        });

    return response.data ?? [];
  }

  Future<StatusModel> submitWithdrawalRequest(
      {required String coins,
        required String gateway,
        required String account}) async {
    StatusModel response = await ApiService.instance.call(
        url: WebService.giftWallet.submitWithdrawalRequest,
        fromJson: StatusModel.fromJson,
        param: {
          Params.coins: coins,
          Params.gateway: gateway,
          Params.account: account
        });

    return response;
  }

  // تم تحديث هذه الدالة للعمل مع PayTabs
  Future<PayTabsResponseModel> buyCoinsWithPayTabs({required int coinPackageId}) async {
    PayTabsResponseModel response = await ApiService.instance.call(
        url: WebService.giftWallet.buyCoins,
        fromJson: PayTabsResponseModel.fromJson,
        param: {
          Params.coinPackageId: coinPackageId,
        });
    return response;
  }

  // دالة جديدة للتحقق من حالة الدفع
  Future<PaymentConfirmationModel> confirmPayment({required String cartId}) async {
    PaymentConfirmationModel response = await ApiService.instance.call(
        url: WebService.giftWallet.confirmPayment,
        fromJson: PaymentConfirmationModel.fromJson,
        param: {
          'cart_id': cartId,
        });
    return response;
  }

  // الدالة القديمة (محتفظ بها للتوافق مع الإصدارات السابقة)
  @Deprecated('Use buyCoinsWithPayTabs instead')
  Future<User?> buyCoins({required int id, String? purchasedAt}) async {
    UserModel response = await ApiService.instance.call(
        url: WebService.giftWallet.buyCoins,
        fromJson: UserModel.fromJson,
        param: {
          Params.coinPackageId: id,
          Params.purchasedAt: purchasedAt,
        });
    if (response.status == true) {
      return response.data;
    }
    return null;
  }
}