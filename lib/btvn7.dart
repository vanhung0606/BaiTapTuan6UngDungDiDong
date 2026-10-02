import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';

void main() {
  runApp(const SmsAnalyzerApp());
}

class SmsAnalyzerApp extends StatelessWidget {
  const SmsAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMS Analyzer',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const SmsAnalyzerScreen(),
    );
  }
}

class SmsAnalyzerScreen extends StatefulWidget {
  const SmsAnalyzerScreen({super.key});

  @override
  State<SmsAnalyzerScreen> createState() => _SmsAnalyzerScreenState();
}

class _SmsAnalyzerScreenState extends State<SmsAnalyzerScreen> {
  final Telephony _telephony = Telephony.instance;

  List<SmsMessage> _allMessages = [];
  List<SmsMessage> _filteredMessages = [];

  bool _loading = true;

  String _selectedFilter = 'Tất cả';

  String _phoneFilter = '';

  @override
  void initState() {
    super.initState();
    _loadSms();
  }

  Future<void> _loadSms() async {
    setState(() {
      _loading = true;
    });

    try {
      final granted = await _telephony.requestSmsPermissions;

      if (granted != true) {
        setState(() {
          _loading = false;
        });

        return;
      }

      final messages = await _telephony.getInboxSms(
        columns: [
          SmsColumn.ID,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
        ],
      );

      setState(() {
        _allMessages = messages;
        _filteredMessages = messages;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể đọc SMS: $e'),
          ),
        );
      }
    }
  }

  bool _isAdvertising(SmsMessage sms) {
    final body = sms.body ?? '';

    return body.trim().startsWith('[QC]');
  }

  bool _isOtp(SmsMessage sms) {
    final body = sms.body ?? '';

    final regex = RegExp(
      r'\[OTP\]\s*\d{6}\b',
      caseSensitive: false,
    );

    return regex.hasMatch(body);
  }

  String? _extractOtp(SmsMessage sms) {
    final body = sms.body ?? '';

    final regex = RegExp(
      r'\[OTP\]\s*(\d{6})\b',
      caseSensitive: false,
    );

    final match = regex.firstMatch(body);

    return match?.group(1);
  }

  void _applyFilter() {
    List<SmsMessage> result = List.from(_allMessages);

    if (_phoneFilter.trim().isNotEmpty) {
      final phone = _phoneFilter.trim();

      result = result.where((sms) {
        return (sms.address ?? '').contains(phone);
      }).toList();
    }

    if (_selectedFilter == 'Quảng cáo') {
      result = result.where(_isAdvertising).toList();
    }

    if (_selectedFilter == 'OTP') {
      result = result.where(_isOtp).toList();
    }

    setState(() {
      _filteredMessages = result;
    });
  }

  Map<String, int> _getDailyStatistics() {
    final Map<String, int> statistics = {};

    for (final sms in _allMessages) {
      if (sms.date == null) continue;

      final date = DateTime.fromMillisecondsSinceEpoch(
        sms.date!,
      );

      final key =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';

      statistics[key] = (statistics[key] ?? 0) + 1;
    }

    return statistics;
  }

  Map<String, int> _getMonthlyStatistics() {
    final Map<String, int> statistics = {};

    for (final sms in _allMessages) {
      if (sms.date == null) continue;

      final date = DateTime.fromMillisecondsSinceEpoch(
        sms.date!,
      );

      final key =
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';

      statistics[key] = (statistics[key] ?? 0) + 1;
    }

    return statistics;
  }

  void _showStatistics() {
    final daily = _getDailyStatistics();
    final monthly = _getMonthlyStatistics();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: controller,
                children: [
                  const Text(
                    'Thống kê SMS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Tổng số SMS: ${_allMessages.length}',
                    style: const TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Theo ngày',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  ...daily.entries.map(
                    (entry) => ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(entry.key),
                      trailing: Text(
                        '${entry.value} SMS',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Theo tháng',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  ...monthly.entries.map(
                    (entry) => ListTile(
                      leading: const Icon(Icons.date_range),
                      title: Text(entry.key),
                      trailing: Text(
                        '${entry.value} SMS',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOtp(SmsMessage sms) {
    final otp = _extractOtp(sms);

    if (otp == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mã OTP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mã OTP được tìm thấy:'),
              const SizedBox(height: 15),
              Text(
                otp,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(int? milliseconds) {
    if (milliseconds == null) {
      return '';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
    );

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSmsItem(SmsMessage sms) {
    final isOtp = _isOtp(sms);
    final isQc = _isAdvertising(sms);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOtp
              ? Colors.orange
              : isQc
                  ? Colors.red
                  : Colors.blue,
          child: Icon(
            isOtp
                ? Icons.lock
                : isQc
                    ? Icons.campaign
                    : Icons.sms,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sms.address ?? 'Không xác định',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isOtp)
              const Chip(
                label: Text('OTP'),
                visualDensity: VisualDensity.compact,
              ),
            if (isQc)
              const Chip(
                label: Text('QC'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(sms.body ?? ''),
            const SizedBox(height: 5),
            Text(
              _formatDate(sms.date),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: isOtp
            ? () {
                _showOtp(sms);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Analyzer'),
        actions: [
          IconButton(
            onPressed: _loadSms,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _showStatistics,
            icon: const Icon(Icons.bar_chart),
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // TỔNG SMS
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.sms,
                        size: 45,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tổng số tin nhắn nhận được',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_allMessages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // TÌM THEO SỐ
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Nhập số điện thoại để lọc...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _phoneFilter = '';
                          _applyFilter();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      _phoneFilter = value;
                      _applyFilter();
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // BỘ LỌC
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  child: Row(
                    children: [
                      _filterChip('Tất cả'),
                      _filterChip('Quảng cáo'),
                      _filterChip('OTP'),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                Expanded(
                  child: _filteredMessages.isEmpty
                      ? const Center(
                          child: Text(
                            'Không tìm thấy tin nhắn.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredMessages.length,
                          itemBuilder: (context, index) {
                            return _buildSmsItem(
                              _filteredMessages[index],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _selectedFilter = label;
          });

          _applyFilter();
        },
      ),
    );
  }
}