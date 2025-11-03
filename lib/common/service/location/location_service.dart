import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bubbly/common/manager/session_manager.dart';
import 'package:bubbly/common/service/api/user_service.dart';
import 'package:bubbly/common/widget/confirmation_dialog.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/user_model/user_model.dart';

class LocationService {
  LocationService._();

  static final instance = LocationService._();

  Future<Position> getCurrentLocation({bool isPermissionDialogShow = false,
    Function(bool enable)? returnCallback}) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (isPermissionDialogShow) {
        Future.error('Location services are still disabled.');
        await showServiceDialog(serviceEnableCallback: returnCallback);
      } else {
        return Future.error('Location services are still disabled.');
      }
    }

    permission = await Geolocator.checkPermission();

    switch (permission) {
      case LocationPermission.denied:
        if (isPermissionDialogShow) {
          await showPermissionDialog(serviceEnableCallback: returnCallback);
          Future.error('Location permissions are denied');
        }
        return Future.error('Location permissions are denied');
      case LocationPermission.deniedForever:
        showPermissionDialog();

        returnCallback?.call(false);
        return Future.error('Location permissions are deniedForever');
      case LocationPermission.whileInUse:
      case LocationPermission.always:
      case LocationPermission.unableToDetermine:
        returnCallback?.call(true);
    }

    if (permission == LocationPermission.deniedForever) {
      returnCallback?.call(false);
      if (isPermissionDialogShow) {
        Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      } else {
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }
    }
    const double locationPrecision = 0.0001; // ~11 meters

    Position position = await Geolocator.getCurrentPosition();
    User? user = SessionManager.instance.getUser();

    final double latitude = position.latitude;
    final double longitude = position.longitude;
    final double userLatitude = user?.lat?.toDouble() ?? 0;
    final double userLongitude = user?.lon?.toDouble() ?? 0;

    // Check if position has changed significantly
    bool hasLocationChanged =
        (latitude - userLatitude).abs() > locationPrecision ||
            (longitude - userLongitude).abs() > locationPrecision;

    if (hasLocationChanged) {
      await UserService.instance
          .updateUserDetails(lat: latitude, lon: longitude);
    }
    return position;
  }

  showPermissionDialog({Function(bool enable)? serviceEnableCallback}) async {
    await Geolocator.requestPermission();
    Get.bottomSheet(ConfirmationSheet(
      title: LKey.nearbyReelsPermissionTitle.tr,
      description: LKey.nearbyReelsPermissionDescription.tr,
      onTap: () {
        openAppSettings().then(
          (value) {
            serviceEnableCallback?.call(value);
          },
        );
      },
    ));
  }

  Future<bool> showServiceDialog(
      {Function(bool enable)? serviceEnableCallback}) async {
    bool isServiceEnabled = false;
    await Get.bottomSheet(ConfirmationSheet(
      title: LKey.locationServicesDisabledTitle.tr,
      description: LKey.locationServicesDisabledDescription.tr,
      onTap: () async {
        bool value = await Geolocator.openLocationSettings();
        isServiceEnabled = value;
      },
    ));
    return isServiceEnabled;
  }
}
