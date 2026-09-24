import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PreviouslyPairedList extends StatelessWidget {
  const PreviouslyPairedList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previously Paired on this account',
          style: TextStyle(
            fontSize: 16.spMin,
            fontWeight: FontWeight.w600,
          ),
        ),
        16.verticalSpace,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).r,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              _buildDeviceItem('YYT-4435-5e', 'Paired 2 days ago'),
              Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
              _buildDeviceItem('AID-6721-9x', 'Paired 2 days ago'),
              Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
              _buildDeviceItem('AID-8347-2p', 'Paired 2 days ago'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceItem(String name, String timeInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12).r,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8).r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: Icon(
              Icons.hearing,
              size: 20.spMin,
              color: Colors.grey[700],
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.spMin,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                4.verticalSpace,
                Text(
                  timeInfo,
                  style: TextStyle(
                    fontSize: 12.spMin,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_horiz,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }
}
