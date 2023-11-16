import 'package:flutter/material.dart';
import 'package:haba_rescue_app/map_screen.dart';
import 'package:haba_rescue_app/model/rescue_items.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedMonth;
  late int _selectedYear;
  late int _selectedDay;
  late List<DateTime> _daysInMonth;

  bool _showTwoWeeks = false;

  Map<String, dynamic>? _selectedRescue;

  String? _selectedFilter;


  void _onFilterChanged(String? value) {
    setState(() {
      _selectedFilter = value;
    });
  }

  List<Map<String, dynamic>> rescues = [
    {
      'title': 'Rescue 1',
      'description': '294 Herbert Macaulay Way, Yaba, 101212, Lagos',
      'time': '12:00 PM',
      'date': DateTime(2023, 11, 12, 12, 0),
      'policyNumber' : 'CA-00026355433-AX',
    },
    {
      'title': 'Rescue 2',
      'description': 'This is the second rescue',
      'time': '1:00 PM',
      'date': DateTime(2023, 11, 10, 13, 0),
      'policyNumber' : 'CA-00026342433-AX',
    },
    {
      'title': 'Rescue 3',
      'description': 'This is the third rescue',
      'time': '2:00 PM',
      'date': DateTime(2023, 11, 10, 14, 0),
      'policyNumber' : 'CA-00022342433-AX',
    },
    {
      'title': 'Rescue 4',
      'description': 'This is the fourth rescue',
      'time': '3:00 PM',
      'date': DateTime(2023, 11, 11, 15, 0),
      'policyNumber' : 'CA-00026002433-AX',
    },
  ];

  void addRandomCoordinates() {
    final random = Random();
    for (var rescue in rescues) {
      rescue['latitude'] = 6.5244 + random.nextDouble() / 100;
      rescue['longitude'] = 3.3792 + random.nextDouble() / 100;
    }
  }





  late List<Map<String, dynamic>> _availableRescues;

  @override
  void initState() {
    super.initState();
    // Call the function to add random coordinates
    addRandomCoordinates();
    DateTime now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _selectedDay = now.day;
    _daysInMonth = _getDaysInMonth(_selectedMonth, _selectedYear);
    _availableRescues =
        _filterRescues(_selectedDay, _selectedMonth, _selectedYear);
  }

  List<DateTime> _getDaysInMonth(int month, int year) {
    List<DateTime> daysInMonth = [];
    int numberOfDaysInMonth = DateTime(year, month + 1, 0).day;
    for (int i = 1; i <= numberOfDaysInMonth; i++) {
      daysInMonth.add(DateTime(year, month, i));
    }
    return daysInMonth;
  }

  List<Map<String, dynamic>> _filterRescues(int day, int month, int year) {
    return rescues.where((rescue) {
      DateTime rescueDate = rescue['date'];
      return rescueDate.day == day &&
          rescueDate.month == month &&
          rescueDate.year == year;
    }).toList();
  }

  void _onMonthSelected(int? month) {
    if (month != null) {
      setState(() {
        _selectedMonth = month;
        _daysInMonth = _getDaysInMonth(month, _selectedYear);
        _availableRescues =
            _filterRescues(_selectedDay, _selectedMonth, _selectedYear);
      });
    }
  }

  void _onYearSelected(int? year) {
    if (year != null) {
      setState(() {
        _selectedYear = year;
        _daysInMonth = _getDaysInMonth(_selectedMonth, year);
        _availableRescues =
            _filterRescues(_selectedDay, _selectedMonth, _selectedYear);
      });
    }
  }

  void _onDaySelected(int day) {
    setState(() {
      _selectedDay = day;
      _availableRescues =
          _filterRescues(_selectedDay, _selectedMonth, _selectedYear);
    });
  }

  Widget _buildMonthYearDropdown() {
    List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];

    int currentYear = DateTime.now().year;
    List<int> years = List.generate(10, (index) => currentYear + index);

    return Container(
      width: 160,
      child: DropdownButtonFormField<String>(
        value: '${monthNames[_selectedMonth - 1]} $_selectedYear',
        onChanged: (String? value) {
          if (value != null) {
            final parts = value.split(' ');
            final selectedMonth = monthNames.indexOf(parts[0]) + 1;
            final selectedYear = int.parse(parts[1]);
            _onMonthYearSelected(selectedMonth, selectedYear);
          }
        },
        items: years.expand((year) => monthNames.map((month) => '$month $year')).map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
        ),
      ),
    );
  }

  void _onMonthYearSelected(int month, int year) {
    setState(() {
      _selectedMonth = month;
      _selectedYear = year;
      _daysInMonth = _getDaysInMonth(_selectedMonth, _selectedYear);

      _availableRescues = rescues.where((rescue) =>
      rescue['date'].month == _selectedMonth && rescue['date'].year == _selectedYear
      ).toList();
    });
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:  EdgeInsets.only(left: 16.0),
                    child: Text(
                      'Filter Claims',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  ListTile(
                    title: Text('All'),
                    trailing: Radio<String>(
                      value: 'all',
                      groupValue: _selectedFilter,
                      onChanged: (value) => setState(() => _selectedFilter = value),
                    ),
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  ListTile(
                    title: Text('Ongoing'),
                    trailing: Radio<String>(
                      value: 'ongoing',
                      groupValue: _selectedFilter,
                      onChanged: (value) => setState(() => _selectedFilter = value),
                    ),
                    onTap: () => setState(() => _selectedFilter = 'ongoing'),
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }




  Widget _buildDaySelector() {
    return TableCalendar(
      firstDay: DateTime.utc(_selectedYear, _selectedMonth, 1),
      lastDay: DateTime.utc(_selectedYear, _selectedMonth + 1, 0),
      focusedDay: DateTime.utc(_selectedYear, _selectedMonth, _selectedDay),
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Colors.purple,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleTextFormatter: (DateTime date, dynamic locale) {
          return DateFormat.yMMM().format(date);
        },
      ),
      selectedDayPredicate: (day) =>
      day.year == _selectedYear &&
          day.month == _selectedMonth &&
          day.day == _selectedDay,

      onDaySelected: (selectedDay, focusedDay) => _onDaySelected(selectedDay.day),
      calendarFormat: CalendarFormat.twoWeeks,
      onFormatChanged: (format) {
        setState(() {
          _showTwoWeeks = format == CalendarFormat.twoWeeks;
        });
      },
    );
  }



  Widget _buildRescueListItem(Map<String, dynamic> rescue) {
    bool isSelected = _selectedRescue != null && _selectedRescue!['title'] == rescue['title'];

    return ListTile(
      leading: Container(
        width: 60.0,
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),

          border: Border.all(
            color: isSelected ? Colors.grey.shade100 : Colors.white,
            width: 2.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('h:mm').format(rescue['date']),
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('a').format(rescue['date']),
              style: TextStyle(
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
      title: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: isSelected ? null : Colors.purple[200],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rescue['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  Text(
                    rescue['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            isSelected ?
            Container(
              height: 23,
              width: 23,
              child: CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(
                  Icons.check,
                  size: 20,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ) :
            Icon(
              Icons.keyboard_arrow_right,
              color: isSelected ? Colors.green : Colors.white,
            ),
          ],
        ),
      ),

      onTap: () {
        // _onRescueListItemSelected(rescue);
        setState(() {
          _selectedRescue = isSelected ? null : rescue;
        });

        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rescue['title'],
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18.0,
                        backgroundImage: AssetImage('assets/profile_picture.png'),
                      ),
                      SizedBox(width: 10.0),
                      Container(
                        height: 1.5,
                        color: Colors.red,
                        width: 50,
                      ),
                      SizedBox(width: 10.0),
                      Icon(Icons.directions_car_outlined, size: 20, color: Colors.purple,),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: Colors.purple,),
                      SizedBox(width: 16.0),
                      Text(
                        rescue['description'],
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Handle accept button click
                          // Accept button pressed
                          // Navigate to the map screen with the location coordinates
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapScreen(
                                latitude: rescue['latitude'],
                                longitude: rescue['longitude'],
                                description: rescue['description'],
                                policyNumber: rescue['policyNumber'],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text('Accept'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        child: Text('Decline', style: TextStyle(
                          color: Colors.black
                        ),),
                      )],
                  ),
                ],
              ),
            );
          },
        );
      },

    );
  }


  Widget _buildRescueList() {
    if (_availableRescues.isEmpty) {
      return Center(child: Text('No assignments on this day', style: TextStyle(
        fontSize: 16
      ),));
    }

    return ListView.builder(
      itemCount: _availableRescues.length,
      itemBuilder: (BuildContext context, int index) {
        return _buildRescueListItem(_availableRescues[index]);
      },
    );
  }

  Widget _buildDateText() {
    DateTime currentDate = DateTime.now();
    String formattedDate = DateFormat('MMMM d, yyyy').format(currentDate);
    return Text(
      formattedDate,
      style: TextStyle(fontSize: 17.0, color: Colors.grey.shade600),
    );
  }

  Widget _buildAssignmentText() {
    DateTime currentDate = DateTime.now();
    String formattedDate = DateFormat('MMMM d, yyyy').format(currentDate);
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Assignments',
            style: TextStyle(
              fontSize: 25.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // Remove the elevation
        backgroundColor: Colors.white70,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Implement logout logic
                },
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
        leading: Container(
          // Display the profile picture as the leading widget
          margin: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: AssetImage('assets/profile_picture.png'),
            radius:
                20.0, // Adjust the radius to control the size of the profile image
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10),
        child: Column(
          children: <Widget>[
            _buildDateText(), // Display the current date
            _buildAssignmentText(), //Display title and filter
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildMonthYearDropdown(),
              ],
            ),
            SizedBox(height: 5.0),
            _buildDaySelector(),
            SizedBox(height: 10.0),
            Expanded(child: _buildRescueList()),
          ],
        ),
      ),
    );
  }

}
