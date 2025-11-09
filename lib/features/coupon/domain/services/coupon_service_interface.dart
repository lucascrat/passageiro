abstract class CouponServiceInterface{
  Future<dynamic> getList({int? offset = 1});
  Future<dynamic> customerAppliedCoupon(String couponId);
}