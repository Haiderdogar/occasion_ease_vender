import 'package:flutter/material.dart';

class TimeSlot {
  final String startTime;
  final String endTime;
  final double price;
  final int maxEvents;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.maxEvents,
  });
}

class TimeSlotDialog extends StatefulWidget {
  final TimeSlot? initialSlot;

  const TimeSlotDialog({Key? key, this.initialSlot}) : super(key: key);

  @override
  _TimeSlotDialogState createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<TimeSlotDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _priceController;
  late TextEditingController _maxEventsController;

  @override
  void initState() {
    super.initState();
    _startTimeController =
        TextEditingController(text: widget.initialSlot?.startTime ?? '');
    _endTimeController =
        TextEditingController(text: widget.initialSlot?.endTime ?? '');
    _priceController =
        TextEditingController(text: widget.initialSlot?.price.toString() ?? '');
    _maxEventsController = TextEditingController(
        text: widget.initialSlot?.maxEvents.toString() ?? '');
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _priceController.dispose();
    _maxEventsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.initialSlot == null ? 'Add Time Slot' : 'Edit Time Slot',
          style: const TextStyle(color: Colors.blue)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _startTimeController,
              decoration: const InputDecoration(
                labelText: 'Start Time',
                prefixIcon: Icon(Icons.access_time, color: Colors.blue),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter start time';
                }
                return null;
              },
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  _startTimeController.text = time.format(context);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endTimeController,
              decoration: const InputDecoration(
                labelText: 'End Time',
                prefixIcon: Icon(Icons.access_time, color: Colors.blue),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter end time';
                }
                return null;
              },
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  _endTimeController.text = time.format(context);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                prefixIcon: Icon(Icons.attach_money, color: Colors.blue),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxEventsController,
              decoration: const InputDecoration(
                labelText: 'Max Events',
                prefixIcon: Icon(Icons.event, color: Colors.blue),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter max events';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text(widget.initialSlot == null ? 'Add' : 'Save',
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(TimeSlot(
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        price: double.parse(_priceController.text),
        maxEvents: int.parse(_maxEventsController.text),
      ));
    }
  }
}
