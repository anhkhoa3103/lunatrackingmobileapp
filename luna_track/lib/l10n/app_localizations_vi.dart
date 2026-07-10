// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Luna Track';

  @override
  String get cycle => 'Chu kỳ';

  @override
  String get calendar => 'Lịch';

  @override
  String get log => 'Ghi chép';

  @override
  String get insights => 'Phân tích';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get notifications => 'Thông báo';

  @override
  String get viewProfile => 'Xem hồ sơ';

  @override
  String get howAreYouToday => 'Hôm nay bạn cảm thấy thế nào?';

  @override
  String get saveTodayLog => 'Lưu nhật ký hôm nay';

  @override
  String get saveLog => 'Lưu nhật ký';

  @override
  String get saved => 'Đã lưu!';

  @override
  String get savedLocally => 'Đã lưu cục bộ';

  @override
  String get flow => 'Lượng máu';

  @override
  String get mood => 'Tâm trạng';

  @override
  String get symptoms => 'Triệu chứng';

  @override
  String get energy => 'Năng lượng';

  @override
  String get sleep => 'Giấc ngủ';

  @override
  String get notes => 'Ghi chú';

  @override
  String get none => 'Không có';

  @override
  String get light => 'Ít';

  @override
  String get medium => 'Vừa';

  @override
  String get heavy => 'Nhiều';

  @override
  String get low => 'Thấp';

  @override
  String get high => 'Cao';

  @override
  String get poor => 'Kém';

  @override
  String get ok => 'Bình thường';

  @override
  String get good => 'Tốt';

  @override
  String get happy => 'Vui vẻ';

  @override
  String get calm => 'Bình tĩnh';

  @override
  String get anxious => 'Lo lắng';

  @override
  String get sad => 'Buồn';

  @override
  String get irritable => 'Cáu kỉnh';

  @override
  String get tired => 'Mệt mỏi';

  @override
  String get cramps => 'Đau bụng';

  @override
  String get headache => 'Đau đầu';

  @override
  String get bloating => 'Đầy hơi';

  @override
  String get backPain => 'Đau lưng';

  @override
  String get nausea => 'Buồn nôn';

  @override
  String get fatigue => 'Kiệt sức';

  @override
  String dayOf(int day, int total) {
    return 'Ngày $day / $total';
  }

  @override
  String daysLeft(int count) {
    return 'Còn $count ngày';
  }

  @override
  String get lastDayOfCycle => 'Ngày cuối chu kỳ';

  @override
  String get today => 'Hôm nay';

  @override
  String get logged => 'Đã ghi chép';

  @override
  String get noLogForThisDay => 'Chưa có nhật ký ngày này';

  @override
  String get addLog => 'Thêm nhật ký';

  @override
  String get editLog => 'Sửa nhật ký';

  @override
  String get onCycle => 'Đang hành kinh';

  @override
  String get avgCycle => 'chu kỳ TB';

  @override
  String get avgPeriod => 'kinh TB';

  @override
  String get logsTotal => 'tổng nhật ký';

  @override
  String get topSymptoms => 'Triệu chứng thường gặp';

  @override
  String get moodBreakdown => 'Phân tích tâm trạng';

  @override
  String get cycleHistory => 'Lịch sử độ dài chu kỳ';

  @override
  String get energySleep => 'Năng lượng & giấc ngủ (4 tuần)';

  @override
  String get noDataYet => 'Chưa có dữ liệu';

  @override
  String get startLogging => 'Bắt đầu ghi chép để xem phân tích';

  @override
  String get personalInfo => 'Thông tin cá nhân';

  @override
  String get cycleSettings => 'Cài đặt chu kỳ';

  @override
  String get name => 'Tên';

  @override
  String get email => 'Email';

  @override
  String get avgCycleLength => 'Chu kỳ trung bình';

  @override
  String get periodDuration => 'Thời gian hành kinh';

  @override
  String get lastPeriodStart => 'Ngày bắt đầu kỳ kinh gần nhất';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get profileSaved => 'Đã lưu hồ sơ';

  @override
  String get days => 'ngày';

  @override
  String get appearance => 'Giao diện';

  @override
  String get system => 'Hệ thống';

  @override
  String get lightMode => 'Sáng';

  @override
  String get darkMode => 'Tối';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get periodBannerTitle => 'Kỳ kinh của bạn đã bắt đầu chưa?';

  @override
  String periodBannerSubtitle(String date) {
    return 'Dự kiến: $date';
  }

  @override
  String get yesStarted => 'Có, đã bắt đầu';

  @override
  String get notYet => 'Chưa, nhắc lại sau';

  @override
  String get periodConfirmed => 'Đã ghi nhận kỳ kinh mới!';

  @override
  String get welcomeTitle => 'Chào mừng đến Luna Track';

  @override
  String get welcomeSubtitle => 'Theo dõi chu kỳ của bạn một cách thông minh';

  @override
  String get getStarted => 'Bắt đầu';

  @override
  String get cycleInfo => 'Thông tin chu kỳ';

  @override
  String get continueBtn => 'Tiếp tục';

  @override
  String get lastPeriodTitle => 'Ngày bắt đầu kỳ kinh gần nhất';

  @override
  String get finish => 'Hoàn thành';

  @override
  String get pleasePickDate => 'Vui lòng chọn ngày bắt đầu kỳ kinh gần nhất';

  @override
  String get register => 'Tạo tài khoản';

  @override
  String get login => 'Đăng nhập';

  @override
  String get password => 'Mật khẩu';

  @override
  String get noAccount => 'Chưa có tài khoản? ';

  @override
  String get haveAccount => 'Đã có tài khoản? ';

  @override
  String get signUp => 'Đăng ký';

  @override
  String get cancelBtn => 'Hủy';

  @override
  String get logoutConfirm => 'Bạn có chắc muốn đăng xuất không?';
}
