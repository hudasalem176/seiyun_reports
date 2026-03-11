import 'package:flutter/material.dart';
import 'package:seiyun_reports_app/screens/pickup_schedules/data/models/pickup_schedule_model.dart';
import 'package:seiyun_reports_app/core/theme/app_theme.dart';

class ScheduleTimelineItem extends StatelessWidget {
  final PickupScheduleModel schedule;

  const ScheduleTimelineItem({Key? key, required this.schedule})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            schedule.isToday || schedule.isTomorrow
                ? const Color(0xFFF1F8E9)
                : Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              schedule.isToday || schedule.isTomorrow
                  ? AppTheme.primaryGreen.withOpacity(0.3)
                  : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayInfo(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeInfo(),
                const SizedBox(height: 12),
                _buildLocationsInfo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayInfo() {
    return Column(
      children: [
        if (schedule.isToday || schedule.isTomorrow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              schedule.isToday ? 'اليوم' : 'غداً',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Text(
                schedule.day,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                schedule.date.split(' ')[0],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo() {
    return Row(
      children: [
        const Icon(Icons.access_time_filled, size: 18, color: Colors.orange),
        const SizedBox(width: 8),
        Text(
          '${schedule.startTime} - ${schedule.endTime}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationsInfo() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          schedule.locations
              .map(
                (loc) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        loc,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}
