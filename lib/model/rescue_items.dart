class RescueItem {
  DateTime date;
  String title;
  String description;
  double latitude;
  double longitude;
  bool isSelected;

  RescueItem({
    required this.date,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.isSelected = false,
  });
}
