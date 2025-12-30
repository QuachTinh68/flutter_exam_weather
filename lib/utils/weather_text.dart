/// Mô tả đầy đủ cho weather_code theo WMO (World Meteorological Organization).
class WeatherText {
  static String describe(int code) {
    switch (code) {
      // Trời quang
      case 0:
        return 'Trời quang';
      
      // Mây
      case 1:
        return 'Ít mây';
      case 2:
        return 'Có mây';
      case 3:
        return 'Nhiều mây';
      
      // Sương mù
      case 45:
        return 'Sương mù';
      case 48:
        return 'Sương mù đóng băng';
      
      // Mưa phùn
      case 51:
        return 'Mưa phùn nhẹ';
      case 53:
        return 'Mưa phùn vừa';
      case 55:
        return 'Mưa phùn nặng';
      case 56:
        return 'Mưa phùn đóng băng nhẹ';
      case 57:
        return 'Mưa phùn đóng băng nặng';
      
      // Mưa
      case 61:
        return 'Mưa nhẹ';
      case 63:
        return 'Mưa vừa';
      case 65:
        return 'Mưa nặng';
      case 66:
        return 'Mưa đóng băng nhẹ';
      case 67:
        return 'Mưa đóng băng nặng';
      
      // Tuyết
      case 71:
        return 'Tuyết nhẹ';
      case 73:
        return 'Tuyết vừa';
      case 75:
        return 'Tuyết nặng';
      case 77:
        return 'Hạt tuyết';
      
      // Mưa rào
      case 80:
        return 'Mưa rào nhẹ';
      case 81:
        return 'Mưa rào vừa';
      case 82:
        return 'Mưa rào nặng';
      
      // Tuyết rào
      case 85:
        return 'Tuyết rào nhẹ';
      case 86:
        return 'Tuyết rào nặng';
      
      // Dông
      case 95:
        return 'Dông';
      case 96:
        return 'Dông có mưa đá';
      case 99:
        return 'Dông mạnh có mưa đá';
      
      default:
        return 'Thời tiết #$code';
    }
  }
}
