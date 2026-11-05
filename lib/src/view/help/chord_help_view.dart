import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChordHelpView extends StatefulWidget {
  const ChordHelpView({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ChordHelpView> createState() => _ChordHelpViewState();
}

class _ChordHelpViewState extends State<ChordHelpView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16).r,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.black,
              ),
            ),
          ),
        ),
        title: Text(
          'CHORD Device Guide',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.spMin,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.primaryColor,
          labelStyle: TextStyle(
            fontSize: 13.spMin,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 13.spMin,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Buttons'),
            Tab(text: 'Status Light'),
            Tab(text: 'Hearing Test'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ButtonsTab(),
          _StatusLightTab(),
          _HearingTestTab(),
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// 1. Buttons & Gestures Tab
// ---------------------------------------------------------------------------
class _ButtonsTab extends StatelessWidget {
  const _ButtonsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20).r,
      children: [
        // Primary Pairing Callout
        Container(
          padding: const EdgeInsets.all(16).r,
          decoration: BoxDecoration(
            color: const Color(0xFF2BA9E0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF2BA9E0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8).r,
                decoration: const BoxDecoration(
                  color: Color(0xFF2BA9E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bluetooth_searching,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pairing Mode Gesture',
                      style: TextStyle(
                        fontSize: 15.spMin,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B6B92),
                      ),
                    ),
                    6.verticalSpace,
                    Text(
                      'Hold VOL+ and VOL− together for 3 seconds until the CHORD screen shows a countdown (120s) and the light blinks blue quickly.\n\nThis works even while the screen is dark.',
                      style: TextStyle(
                        fontSize: 13.spMin,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        24.verticalSpace,

        Text(
          'Buttons on the Body Unit',
          style: TextStyle(
            fontSize: 16.spMin,
            fontWeight: FontWeight.w600,
          ),
        ),
        8.verticalSpace,
        Text(
          'Three buttons control everything on the unit, plus a separate power button that wakes it from shut-down.',
          style: TextStyle(
            fontSize: 13.spMin,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
        16.verticalSpace,

        _buildGestureCard(
          title: 'VOL+ Button',
          outsideMenu:
              'Volume up one step (holding repeats every 0.25s). If muted, unmutes.',
          insideMenu: 'Moves highlight up.',
        ),
        12.verticalSpace,
        _buildGestureCard(
          title: 'VOL− Button',
          outsideMenu:
              'Volume down one step (holding repeats). Below lowest step, mutes.',
          insideMenu: 'Moves highlight down.',
        ),
        12.verticalSpace,
        _buildGestureCard(
          title: 'MODE Button (Short Press)',
          outsideMenu: 'Opens the on-device menu.',
          insideMenu: 'Selects the highlighted row.',
        ),
        12.verticalSpace,
        _buildGestureCard(
          title: 'MODE Button (Long Press 0.8s)',
          outsideMenu: 'Cycles profile: Normal → Noisy → Music → Normal.',
          insideMenu: 'Goes one screen back.',
        ),
        12.verticalSpace,
        _buildGestureCard(
          title: 'Power Button',
          outsideMenu: 'Wakes the device from shut-down.',
          insideMenu: 'No effect during menu navigation.',
        ),
        12.verticalSpace,
        _buildGestureCard(
          title: 'Screen Sleep & Wake',
          outsideMenu:
              'Screen turns off after 15 seconds without changes. Pressing any button wakes the screen without changing any setting.',
          insideMenu: 'Menu automatically closes after 10 seconds of inactivity.',
        ),
        24.verticalSpace,
      ],
    );
  }

  Widget _buildGestureCard({
    required String title,
    required String outsideMenu,
    required String insideMenu,
  }) {
    return Container(
      padding: const EdgeInsets.all(14).r,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.spMin,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          8.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Normal: ',
                style: TextStyle(
                  fontSize: 12.spMin,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Expanded(
                child: Text(
                  outsideMenu,
                  style: TextStyle(
                    fontSize: 12.spMin,
                    color: Colors.grey[800],
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          6.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'In Menu: ',
                style: TextStyle(
                  fontSize: 12.spMin,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Expanded(
                child: Text(
                  insideMenu,
                  style: TextStyle(
                    fontSize: 12.spMin,
                    color: Colors.grey[800],
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// 2. Status Light Patterns Tab
// ---------------------------------------------------------------------------
class _StatusLightTab extends StatelessWidget {
  const _StatusLightTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20).r,
      children: [
        Text(
          'What Does This Light Mean?',
          style: TextStyle(
            fontSize: 16.spMin,
            fontWeight: FontWeight.w600,
          ),
        ),
        8.verticalSpace,
        Text(
          'The status light on the body unit shows device states when the screen is dark, displayed in order of highest priority.',
          style: TextStyle(
            fontSize: 13.spMin,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
        16.verticalSpace,

        _buildLightItem(
          color: Colors.white,
          border: Colors.grey,
          pattern: 'White, one 1s flash',
          state: 'Shutting down or restarting',
        ),
        _buildLightItem(
          color: Colors.red,
          pattern: 'Red double flash every 3s',
          state: 'Fault active (earpiece processor / cable issue)',
        ),
        _buildLightItem(
          color: Colors.purpleAccent,
          pattern: 'Magenta blink',
          state: 'Firmware update running (SMP / OTA)',
        ),
        _buildLightItem(
          color: Colors.blue,
          pattern: 'Blue, fast blink',
          state: 'Pairing mode open (countdown from 120s)',
        ),
        _buildLightItem(
          color: Colors.amber,
          pattern: 'Solid amber',
          state: 'Charging over USB-C',
        ),
        _buildLightItem(
          color: Colors.green,
          pattern: 'Solid green',
          state: 'Fully charged (on the charger)',
        ),
        _buildLightItem(
          color: Colors.red,
          pattern: 'Red flash every 2s',
          state: 'Battery critical (10%)',
        ),
        _buildLightItem(
          color: Colors.red,
          pattern: 'Red flash every 5s',
          state: 'Battery low (15%)',
        ),
        _buildLightItem(
          color: Colors.cyan,
          pattern: 'Cyan flash every 5s',
          state: 'Streaming phone audio (LE Audio / ASHA)',
        ),
        _buildLightItem(
          color: Colors.blue,
          pattern: 'Blue flash every 2s',
          state: 'Waiting for a bonded phone to reconnect',
        ),
        _buildLightItem(
          color: Colors.black26,
          pattern: 'Light off',
          state: 'Connected & idle, or Bluetooth switched off',
        ),

        24.verticalSpace,
        Text(
          'Short Event Flashes',
          style: TextStyle(
            fontSize: 15.spMin,
            fontWeight: FontWeight.w600,
          ),
        ),
        12.verticalSpace,
        _buildEventItem('White 0.5s', 'Device power-on'),
        _buildEventItem('Green 0.3s', 'Phone connects'),
        _buildEventItem('Blue double flash', 'Phone disconnects'),
        _buildEventItem('Green triple flash', 'New phone pairs successfully'),
        _buildEventItem('White short flash', 'Menu action confirmed'),
        24.verticalSpace,
      ],
    );
  }

  Widget _buildLightItem({
    required Color color,
    required String pattern,
    required String state,
    Color? border,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8).r,
      child: Row(
        children: [
          Container(
            width: 18.r,
            height: 18.r,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: border ?? color),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          14.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern,
                  style: TextStyle(
                    fontSize: 13.spMin,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                2.verticalSpace,
                Text(
                  state,
                  style: TextStyle(
                    fontSize: 12.spMin,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(String trigger, String event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4).r,
      child: Row(
        children: [
          SizedBox(
            width: 130.w,
            child: Text(
              trigger,
              style: TextStyle(
                fontSize: 12.spMin,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              event,
              style: TextStyle(
                fontSize: 12.spMin,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// 3. Hearing Test (Fitting) Tab
// ---------------------------------------------------------------------------
class _HearingTestTab extends StatelessWidget {
  const _HearingTestTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20).r,
      children: [
        Container(
          padding: const EdgeInsets.all(16).r,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF16A34A),
                size: 22,
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Runs on the CHORD Device',
                      style: TextStyle(
                        fontSize: 14.spMin,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF166534),
                      ),
                    ),
                    6.verticalSpace,
                    Text(
                      'To protect fitting precision, hearing tests run directly on the CHORD device using its screen and buttons. Open the menu on your device and pick "Hearing test" to begin.\n\nNote: Please ensure you are in a quiet room and avoid streaming music from your phone during the test.',
                      style: TextStyle(
                        fontSize: 12.spMin,
                        color: const Color(0xFF166534),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        24.verticalSpace,

        Text(
          'How to Start on Your Device',
          style: TextStyle(
            fontSize: 16.spMin,
            fontWeight: FontWeight.w600,
          ),
        ),
        12.verticalSpace,
        Text(
          '1. Press the MODE button on the body unit to open the menu.\n'
          '2. Use VOL+ / VOL− to highlight "Hearing test".\n'
          '3. Press MODE to select it.',
          style: TextStyle(
            fontSize: 13.spMin,
            color: Colors.grey[800],
            height: 1.5,
          ),
        ),
        24.verticalSpace,

        Text(
          'The 3 Hearing Test Options',
          style: TextStyle(
            fontSize: 16.spMin,
            fontWeight: FontWeight.w600,
          ),
        ),
        12.verticalSpace,
        _buildSessionCard(
          title: 'Start fitting',
          description:
              'The complete guided fitting (8 steps). Computes prescription (NAL-R) and sets Profiles 1–3.',
        ),
        12.verticalSpace,
        _buildSessionCard(
          title: 'Adjust sound',
          description:
              'Fine-tune Volume, Clarity, and Fullness around your fitted profile without repeating the full test.',
        ),
        12.verticalSpace,
        _buildSessionCard(
          title: 'Whistle check',
          description:
              'Detects feedback whistles when your hand cups the ear and limits gain at offending frequencies.',
        ),
        24.verticalSpace,

        Text(
          'Steps of a Full Fitting',
          style: TextStyle(
            fontSize: 16.spMin,
            fontWeight: FontWeight.w600,
          ),
        ),
        16.verticalSpace,
        _buildStepItem(1, 'Screening', 'Six health questions to confirm hearing-aid suitability.'),
        _buildStepItem(2, 'Fit Check', 'A low hum confirms the earpiece seals correctly in the ear.'),
        _buildStepItem(3, 'Room Noise', 'Microphones measure room noise; pauses if too noisy.'),
        _buildStepItem(4, 'Tones Test', 'Plays calibrated tones; press the button when you hear them.'),
        _buildStepItem(5, 'Results', 'Calculated and stored securely inside the earpiece.'),
        _buildStepItem(6, 'Prescription', 'Applies clinical NAL-R formula to generate Profiles 1 to 3.'),
        _buildStepItem(7, 'Listen', 'New fitted sound fades in; user can ask for small adjustments.'),
        _buildStepItem(8, 'Whistle Check', 'Cups hand over ear; any feedback sets an anti-whistle limit.'),
        24.verticalSpace,
      ],
    );
  }

  Widget _buildSessionCard({
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14).r,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.spMin,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          4.verticalSpace,
          Text(
            description,
            style: TextStyle(
              fontSize: 12.spMin,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6).r,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12.r,
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.15),
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: 11.spMin,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.spMin,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                2.verticalSpace,
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12.spMin,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
