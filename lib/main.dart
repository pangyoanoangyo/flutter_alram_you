import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewLifeCh_Alram',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Pretendard',
        brightness: Brightness.dark,
      ),
      home: MainPage(),
    );
  }
}

// 메인 페이지
class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String serverAddress = 'ws://1.232.60.26:6024/ws/notification/';  // 기본값 변경

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF303F9F),
              Color(0xFF3949AB),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '알림 시스템',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),
                // Container(
                //   decoration: BoxDecoration(
                //     color: Colors.white.withOpacity(0.9),
                //     borderRadius: BorderRadius.circular(15),
                //   ),
                //   child: TextField(
                //     controller: TextEditingController(text: serverAddress),
                //     onChanged: (value) {
                //       setState(() {
                //         serverAddress = value;
                //       });
                //     },
                //     style: TextStyle(
                //       color: Colors.black,
                //       fontSize: 16,
                //       fontWeight: FontWeight.w500,
                //     ),
                //     decoration: InputDecoration(
                //       labelText: '웹소켓 서버 주소',
                //       labelStyle: TextStyle(
                //         color: Colors.blue[900],
                //         fontSize: 16,
                //       ),
                //       contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                //       border: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(15),
                //       ),
                //     ),
                //   ),
                // ),
                SizedBox(height: 60),
                _buildMainButton(
                  context,
                  '악기/보컬팀',
                  Icons.music_note,
                  InstrumentPage(serverAddress: serverAddress),
                  Colors.orange,
                ),
                SizedBox(height: 30),
                _buildMainButton(
                  context,
                  '방송팀',
                  Icons.tv,
                  BroadcastPage(serverAddress: serverAddress),
                  Colors.green,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context, String text, IconData icon, Widget page, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => page,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: Duration(milliseconds: 500),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.white),
            SizedBox(width: 15),
            Text(
              text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 악기팀 페이지
class InstrumentPage extends StatefulWidget {
  final String serverAddress;

  const InstrumentPage({Key? key, required this.serverAddress}) : super(key: key);

  @override
  _InstrumentPageState createState() => _InstrumentPageState();
}
class _InstrumentPageState extends State<InstrumentPage> with SingleTickerProviderStateMixin {
  late WebSocketChannel channel;
  String? selectedInstrument;
  String? selectedControl;
  String name = "";
  List<Map<String, dynamic>> messages = [];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Map<String, String>> instruments = [
    {'type': 'drum', 'label': 'DRUM(드럼)'},
    {'type': 'bass', 'label': 'BASS(베이스)'},
    {'type': 'guitar', 'label': 'GUITAR(기타)'},
    {'type': 'synth1', 'label': 'SYNTH1(신디 1)'},
    {'type': 'synth2', 'label': 'SYNTH2(신디 2)'},
    {'type': 'vocal', 'label': 'VOCAL(보컬)'},
  ];

  final List<Map<String, String>> controls = [
    {'type': 'volume-up', 'label': '볼륨 업'},
    {'type': 'volume-down', 'label': '볼륨 다운'},
    {'type': 'look', 'label': 'Look at me'},
  ];

  @override
  void initState() {
    super.initState();
    connectWebSocket();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void connectWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse(widget.serverAddress),
    );

    channel.stream.listen((message) {
      final decodedMessage = jsonDecode(message);
      setState(() {
        messages.add(decodedMessage);
        // 새 메시지가 추가될 때마다 애니메이션 실행
        _animationController.forward().then((_) {
          _animationController.reset();
        });
      });
    });
  }

  void sendNotification() {
    if (name.isEmpty || selectedInstrument == null || selectedControl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력해주세요.')),
      );
      return;
    }

    final message = jsonEncode({
      'name': name,
      'instrument': selectedInstrument,
      'control': selectedControl,
    });

    channel.sink.add(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('요청이 전송되었습니다.')),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('악기팀 화면'),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  name = value;
                });
              },
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: '이름을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '악기를 선택하세요:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: instruments.map((instrument) => _buildInstrumentChip(instrument)).toList(),
            ),
            SizedBox(height: 20),
            Text(
              '컨트롤을 선택하세요:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: controls.map((control) {
                bool isSelected = selectedControl == control['type'];
                return ChoiceChip(
                  label: Text(control['label']!),
                  selected: isSelected,
                  onSelected: (isSelected) {
                    setState(() {
                      selectedControl = isSelected ? control['type'] : null;
                    });
                  },
                  selectedColor: Colors.blue[700],
                  backgroundColor: Colors.grey[200],
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                );
              }).toList(),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: sendNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '전송하기',
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) => _buildNotificationCard(messages[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentChip(Map<String, String> instrument) {
    bool isSelected = selectedInstrument == instrument['type'];
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.all(4),
      child: ChoiceChip(
        label: Text(
          instrument['label']!,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        selected: isSelected,
        onSelected: (isSelected) {
          setState(() {
            selectedInstrument = isSelected ? instrument['type'] : null;
          });
          _animationController.forward().then((_) => _animationController.reverse());
        },
        selectedColor: Colors.blue[700],
        backgroundColor: Colors.grey[200],
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> message) {
    return AnimatedContainer(  // SlideTransition 대신 AnimatedContainer 사용
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: message['type'] == 'confirmation' ? Colors.green[100] : Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              message['type'] == 'confirmation' ? Icons.check_circle : Icons.info,
              color: message['type'] == 'confirmation' ? Colors.green : Colors.blue,
            ),
          ),
          title: Text(
            message['type'] == 'confirmation' ? '확인됨' : '알림',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text('이름: ${message['name']}'),
              Text('악기: ${message['instrument']}'),
              Text('컨트롤: ${message['control']}'),
            ],
          ),
        ),
      ),
    );
  }
}
class BroadcastPage extends StatefulWidget {
  final String serverAddress;

  const BroadcastPage({Key? key, required this.serverAddress}) : super(key: key);

  @override
  _BroadcastPageState createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> with SingleTickerProviderStateMixin {
  late WebSocketChannel channel;
  Map<String, String>? currentMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    connectWebSocket();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  void connectWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse(widget.serverAddress),  // 전달받은 서버 주소 사용
    );

    channel.stream.listen((message) {
      print("Received message: $message");
      final data = jsonDecode(message);
      if (data['type'] == 'confirmation') {
        print("Confirmation message received and ignored.");
        return;
      }

      setState(() {
        print("Updating currentMessage...");
        currentMessage = {
          'name': data['name'],
          'instrument': data['instrument'],
          'control': data['control'],
        };
        print("Updated currentMessage: $currentMessage");
        _animationController.forward();
      });
    });
  }

  void resetDisplay() {
    if (currentMessage != null) {
      channel.sink.add(jsonEncode({
        'type': 'confirmation',
        'name': currentMessage!['name']!,
        'instrument': currentMessage!['instrument']!,
        'control': currentMessage!['control'] ?? '',
      }));
      print("확인 메시지 전송: $currentMessage");
    }

    setState(() {
      currentMessage = null;
      _animationController.reverse();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A1A1A)],
          ),
        ),
        child: Center(
        child: currentMessage == null
        ? Text(
        '방송팀 디스플레이',
        style: TextStyle(
          fontSize: 80,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 5.0,
              color: Colors.white.withOpacity(0.3),
              offset: Offset(0, 2),
            ),
          ],
        ),
      )
          : ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
      Container(
      padding: EdgeInsets.all(50),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[900]!, Colors.red[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentMessage!['instrument']!.toUpperCase(),
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black,
                  offset: Offset(0, 5),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Text(
            '${currentMessage!['name']} : ${currentMessage!['instrument']}',
            style: TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              currentMessage!['control'] ?? 'N/A',
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
    SizedBox(height: 30),
    ElevatedButton(
    onPressed: resetDisplay,
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green[600],
    padding: EdgeInsets.symmetric(
    horizontal: 40,
      vertical: 15,
    ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
    ),
      child: Text(
        '확인함',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
          ],
      ),
        ),
        ),
      ),
    );
  }
}
