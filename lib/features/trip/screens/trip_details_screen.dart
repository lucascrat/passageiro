import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/body_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/custom_pop_scope_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/loader_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/swipable_button_widget/slider_button_widget.dart';
import 'package:ride_sharing_user_app/features/auth/domain/enums/refund_status_enum.dart';
import 'package:ride_sharing_user_app/features/payment/screens/review_screen.dart';
import 'package:ride_sharing_user_app/features/refund_request/screens/refund_request_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:ride_sharing_user_app/features/safety_setup/widgets/safety_alert_bottomsheet_widget.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/features/trip/controllers/trip_controller.dart';
import 'package:ride_sharing_user_app/features/trip/widgets/parcel_details_widget.dart';
import 'package:ride_sharing_user_app/features/trip/widgets/refund_details_widget.dart';
import 'package:ride_sharing_user_app/features/trip/widgets/rider_info.dart';
import 'package:ride_sharing_user_app/features/trip/widgets/trip_details.dart';
import 'package:ride_sharing_user_app/features/trip/widgets/trip_details_top_section_widget.dart';
import 'package:ride_sharing_user_app/features/trip/widgets/trip_safety_sheet_details_widget.dart';
import 'package:ride_sharing_user_app/helper/date_converter.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class TripDetailsScreen extends StatefulWidget {
  final String tripId;
  final bool fromNotification;
  const TripDetailsScreen({super.key, required this.tripId,this.fromNotification = false});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {

  JustTheController toolTipController = JustTheController();

  @override
  void initState() {
    if(!widget.fromNotification){
      Get.find<RideController>().getRideDetails(widget.tripId, isUpdate: false);
    }
    super.initState();
  }

  @override
  void dispose() {
    toolTipController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: CustomPopScopeWidget(
        child: Scaffold(
          body: GetBuilder<RideController>(builder: (rideController){
            if(rideController.tripDetails?.customerSafetyAlert != null){
              showToolTips();
            }
            return PopScope(
              onPopInvokedWithResult: (didPop, val){
                rideController.clearRideDetails();
              },
              child: BodyWidget(
                appBar: AppBarWidget(
                  title: 'completed'.tr,
                  subTitle: rideController.tripDetails != null ?
                  '${rideController.tripDetails?.type == 'parcel' ? 'parcel'.tr : 'trip'.tr} #${rideController.tripDetails?.refId}' : '',
                  showBackButton: true, centerTitle: true,
                ),
                body: GetBuilder<TripController>(builder: (activityController) {
                  return rideController.tripDetails != null ?
                  Stack(children: [
                    Column(children: [
                      Expanded(child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                          child: Column(children: [
                            const SizedBox(height: Dimensions.paddingSizeSmall),

                            TripDetailsTopSectionWidget(tripDetails: rideController.tripDetails),
                            const SizedBox(height: Dimensions.paddingSizeSmall),

                            if(rideController.tripDetails?.currentStatus == 'returning' && rideController.tripDetails?.returnTime != null)...[
                              Container(
                                  width: Get.width,
                                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeThree,horizontal: Dimensions.paddingSizeSmall),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeThree),
                                      color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha:0.15)
                                  ),
                                  child: Text.rich(textAlign: TextAlign.center, TextSpan(
                                    style: textRegular.copyWith(
                                      fontSize: Dimensions.fontSizeLarge,
                                      color: Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha:0.8),
                                    ),
                                    children:  [
                                      TextSpan(text: 'parcel_return_estimated_time_is'.tr, style: textRegular.copyWith(
                                        color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha:0.8),
                                        fontSize: Dimensions.fontSizeSmall,
                                      )),

                                      TextSpan(
                                        text: ' ${DateConverter.stringToLocalDateTime(rideController.tripDetails!.returnTime!)}',
                                        style: textSemiBold.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: Dimensions.fontSizeSmall),
                                      ),
                                    ],
                                  ))
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall)
                            ],

                            if(rideController.tripDetails?.driver != null) ...[
                              RiderInfo(tripDetails: rideController.tripDetails!)
                            ],

                            rideController.tripDetails?.type == 'parcel' ?
                            ParcelDetailsWidget(tripDetails: rideController.tripDetails!) :
                            TripDetailWidget(tripDetails: rideController.tripDetails!),

                            if(rideController.tripDetails?.currentStatus == 'returning' && rideController.tripDetails?.type == 'parcel')...[
                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              Center(child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault,vertical: Dimensions.paddingSizeSmall),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                                    color: Theme.of(context).cardColor,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withValues(alpha:0.06),
                                          spreadRadius: 5,
                                          blurRadius: 10,
                                          offset: const Offset(0,1)
                                      )
                                    ]
                                ),
                                child: Column(children: [
                                  Text('${rideController.tripDetails?.otp?[0]}  ${rideController.tripDetails?.otp?[1]}  ${rideController.tripDetails?.otp?[2]}  ${rideController.tripDetails?.otp?[3]}',style: textBold.copyWith(fontSize: 20)),

                                  Text.rich(TextSpan(style: textRegular.copyWith(fontSize: Dimensions.fontSizeLarge,
                                      color: Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha:0.8)), children:  [

                                    TextSpan(text: 'please_share_the'.tr,
                                        style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha:0.8),
                                            fontSize: Dimensions.fontSizeDefault)),

                                    TextSpan(text: ' OTP '.tr,
                                        style: textSemiBold.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault)),

                                    TextSpan(text: 'with_the_driver'.tr, style: textRegular.copyWith(
                                        color: Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha:0.8),
                                        fontSize: Dimensions.fontSizeDefault)),]), textAlign: TextAlign.center),
                                ]),
                              )),
                              const SizedBox(height: Dimensions.paddingSizeDefault),

                              rideController.isLoading ?
                              SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0) :
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                                child: Center(child: SliderButton(
                                  action: (){
                                    rideController.parcelReturned(rideController.tripDetails?.id ?? '').then((value){
                                      if(value.statusCode == 200){
                                        showDialog(context: Get.context!, builder: (_){
                                          return parcelReceivedDialog();
                                        });
                                      }
                                    });
                                  },
                                  label: Text('parcel_received'.tr,style: TextStyle(color: Theme.of(context).primaryColor)),
                                  dismissThresholds: 0.5, dismissible: false, shimmer: false,
                                  width: 1170, height: 40, buttonSize: 40, radius: 20,
                                  icon: Center(child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).cardColor),
                                    child: Center(child: Icon(
                                      Get.find<LocalizationController>().isLtr ? Icons.arrow_forward_ios_rounded : Icons.keyboard_arrow_left,
                                      color: Colors.grey, size: 20.0,
                                    )),
                                  )),
                                  isLtr: Get.find<LocalizationController>().isLtr,
                                  boxShadow: const BoxShadow(blurRadius: 0),
                                  buttonColor: Colors.transparent,
                                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha:0.15),
                                  baseColor: Theme.of(context).primaryColor,
                                )),
                              )
                            ],
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                            if(rideController.tripDetails?.parcelRefund != null)...[
                             RefundDetailsWidget()
                            ],
                            const SizedBox(height: Dimensions.paddingSizeDefault),

                            if((Get.find<ConfigController>().config?.parcelRefundStatus ?? false) &&
                                _refundTimeValidity(rideController.tripDetails?.parcelCompleteTime ?? '2000-09-21 14:42:07') &&
                                rideController.tripDetails?.type == 'parcel' && rideController.tripDetails?.currentStatus == 'completed' &&
                                rideController.tripDetails?.parcelRefund == null
                            )...[

                              Text('if_your_parcel_is_damaged'.tr,style: textRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).colorScheme.secondaryFixedDim
                              ),textAlign: TextAlign.center),
                              const SizedBox(height: Dimensions.paddingSizeSeven),

                              InkWell(
                                onTap: ()=> Get.to(()=> RefundRequestScreen(tripId: widget.tripId)),
                                child: Text('refund_request'.tr, style: textRegular.copyWith(
                                    decoration: TextDecoration.underline,
                                    decorationColor: Theme.of(context).colorScheme.inverseSurface,
                                    color: Theme.of(context).colorScheme.inverseSurface
                                )),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeDefault),
                            ],
                          ]),
                        ),
                      )),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      (Get.find<ConfigController>().config!.reviewStatus! &&
                          ! (rideController.tripDetails?.isReviewed ?? false) &&
                          rideController.tripDetails?.driver != null &&
                          rideController.tripDetails?.paymentStatus == 'paid' &&
                          _isReviewButtonShown(rideController.tripDetails?.parcelRefund?.status)) ?
                      Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withValues(alpha: 0.1), blurRadius: 2,spreadRadius: 3,offset: Offset(0, -2))]
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                        child: ButtonWidget(
                          icon: Icons.star_border,
                          buttonText: 'give_review'.tr,
                          onPressed: () => Get.to(() => ReviewScreen(tripId: widget.tripId)),
                        ),
                      ) : const SizedBox()
                    ]),

                    if(rideController.tripDetails?.customerSafetyAlert != null)
                      Positioned(
                        right: Dimensions.paddingSizeDefault *2,
                        height: Get.height * 0.2,
                        child: JustTheTooltip(
                          backgroundColor: Get.isDarkMode ?
                          Theme.of(context).primaryColor :
                          Theme.of(context).textTheme.bodyMedium!.color,
                          controller: toolTipController,
                          preferredDirection: AxisDirection.right,
                          tailLength: 10,
                          tailBaseWidth: 20,
                          content: Container(width: Get.width * 0.5,
                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: Text(
                              'tap_to_see_safety_details'.tr,
                              style: textRegular.copyWith(
                                color: Colors.white, fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ),
                          child: InkWell(
                            onTap: ()=> Get.bottomSheet(
                              isScrollControlled: true,
                              TripSafetySheetDetailsWidget(tripDetails: rideController.tripDetails!),
                              backgroundColor: Theme.of(context).cardColor,isDismissible: false,
                            ),
                            child: Image.asset(Images.safelyShieldIcon3,height: 24,width: 24),
                          ),
                        ),
                      ),

                    if(_showSafetyFeature(rideController.tripDetails!))
                      Positioned(
                        bottom: Get.height * 0.1, right: 10,
                        child: InkWell(
                          onTap: (){
                            Get.find<SafetyAlertController>().updateSafetyAlertState(SafetyAlertState.initialState);
                            Get.bottomSheet(
                              isScrollControlled: true,
                              const SafetyAlertBottomSheetWidget(fromTripDetailsScreen: true),
                              backgroundColor: Theme.of(context).cardColor,isDismissible: false,
                            );
                          },
                          child: Image.asset(Images.safelyShieldIcon3,height: 40,width: 40),
                        ),
                      )
                  ]) :
                  const LoaderWidget();
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  void showToolTips(){
    WidgetsBinding.instance.addPostFrameCallback((_){
      Future.delayed(const Duration(milliseconds: 500)).then((_){
        toolTipController.showTooltip();
      });
    });
  }

  bool _isReviewButtonShown(RefundStatus? refundStatus){
    return refundStatus == RefundStatus.pending ?
    false :
    refundStatus == RefundStatus.approved ?
    false :
    true;
  }

  Widget parcelReceivedDialog(){
    return Dialog(
      surfaceTintColor: Get.isDarkMode ? Theme.of(context).hintColor  : Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault)),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: SizedBox(
          width: Get.width,
          child: Column(mainAxisSize:MainAxisSize.min, children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(onTap: ()=> Get.back(), child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: Image.asset(
                  Images.crossIcon,
                  height: Dimensions.paddingSizeSmall,
                  width: Dimensions.paddingSizeSmall,
                  color: Theme.of(context).cardColor,
                ),
              )),
            ),

            Image.asset(Images.parcelReturnSuccessIcon,height: 80,width: 80),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: Get.width * 0.2),
              child: Text(
                'your_parcel_returned_successfully'.tr,
                style: textSemiBold.copyWith(color: Theme.of(context).primaryColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge)

          ]),
        ),
      ),
    );
  }

  bool _refundTimeValidity(String stringDateTime){
    int time = Get.find<ConfigController>().config?.parcelRefundValidityType == 'hour' ?
    DateTime.now().difference(DateConverter.dateTimeStringToDate(stringDateTime)).inHours :
    DateTime.now().difference(DateConverter.dateTimeStringToDate(stringDateTime)).inDays;

    return time > (Get.find<ConfigController>().config?.parcelRefundValidity ?? 0) ? false : true;
  }

  bool _showSafetyFeature(TripDetails tripDetails){
    if(tripDetails.rideCompleteTime != null){
      int time = DateTime.now().difference(DateConverter.dateTimeStringToDate(tripDetails.rideCompleteTime!)).inSeconds;
      int activeTime = (Get.find<ConfigController>().config?.afterTripCompleteSafetyFeatureSetTime ?? 0);
      return (Get.find<ConfigController>().config?.afterTripCompleteSafetyFeatureActiveStatus ?? false) && tripDetails.currentStatus ==  "completed" &&
          tripDetails.type != "parcel" && activeTime > time && tripDetails.customerSafetyAlert == null ? true : false;
    }else{
      return false;
    }
  }

}

