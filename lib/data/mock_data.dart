import '../models/incident.dart';
import '../utils/constants.dart';

const demoStudentEmail = 'amina@alustudent.com';
const demoStaffEmail = 'staff@alueducation.com';

List<Incident> seedIncidents() {
  final now = DateTime.now();
  DateTime ago({int m = 0, int h = 0, int d = 0}) =>
      now.subtract(Duration(minutes: m, hours: h, days: d));

  return [
    Incident(
      id: 'i1',
      title: 'Water shortage',
      description:
          'There has been no water supply in the student residence since this morning. This is affecting many students on the 2nd floor. Kindly check and fix the issue.',
      category: IncidentCategory.water,
      location: 'Student Residence',
      status: IncidentStatus.inProgress,
      reporterId: demoStudentEmail,
      reporterName: 'Amina Hassan',
      createdAt: ago(h: 2),
      history: [
        StatusEntry(IncidentStatus.submitted, ago(h: 2)),
        StatusEntry(IncidentStatus.inProgress, ago(m: 30)),
      ],
    ),
    Incident(
      id: 'i2',
      title: 'Broken classroom projector',
      description:
          'The projector in Room 204 does not turn on. Lectures are being delayed.',
      category: IncidentCategory.facilities,
      location: 'Block B, Room 204',
      status: IncidentStatus.inProgress,
      reporterId: demoStudentEmail,
      reporterName: 'Amina Hassan',
      createdAt: ago(d: 1),
      history: [
        StatusEntry(IncidentStatus.submitted, ago(d: 1)),
        StatusEntry(IncidentStatus.inProgress, ago(h: 6)),
      ],
    ),
    Incident(
      id: 'i3',
      title: 'Overflowing bin',
      description:
          'The bins behind the cafeteria are overflowing and attracting flies.',
      category: IncidentCategory.sanitation,
      location: 'Cafeteria',
      status: IncidentStatus.resolved,
      reporterId: demoStudentEmail,
      reporterName: 'Amina Hassan',
      createdAt: ago(d: 3),
      history: [
        StatusEntry(IncidentStatus.submitted, ago(d: 3)),
        StatusEntry(IncidentStatus.inProgress, ago(d: 2, h: 5)),
        StatusEntry(IncidentStatus.resolved, ago(d: 2)),
      ],
    ),
    Incident(
      id: 'i4',
      title: 'Power outage in the library',
      description:
          'Lights and sockets on the first floor of the library have no power.',
      category: IncidentCategory.electricity,
      location: 'Library',
      status: IncidentStatus.submitted,
      reporterId: 'james@alustudent.com',
      reporterName: 'James Okoro',
      createdAt: ago(h: 5),
      history: [StatusEntry(IncidentStatus.submitted, ago(h: 5))],
    ),
    Incident(
      id: 'i5',
      title: 'Loose stair railing',
      description:
          'The railing on the staircase at Block A is loose and could cause a fall.',
      category: IncidentCategory.safety,
      location: 'Block A, Lecture Hall',
      status: IncidentStatus.inProgress,
      reporterId: 'grace@alustudent.com',
      reporterName: 'Grace Uwase',
      createdAt: ago(d: 2),
      history: [
        StatusEntry(IncidentStatus.submitted, ago(d: 2)),
        StatusEntry(IncidentStatus.inProgress, ago(d: 1)),
      ],
    ),
    Incident(
      id: 'i6',
      title: 'Damaged chairs in the lab',
      description: 'Four chairs in the computer lab have broken backs.',
      category: IncidentCategory.furniture,
      location: 'Block C, Computer Lab',
      status: IncidentStatus.resolved,
      reporterId: 'james@alustudent.com',
      reporterName: 'James Okoro',
      createdAt: ago(d: 6),
      history: [
        StatusEntry(IncidentStatus.submitted, ago(d: 6)),
        StatusEntry(IncidentStatus.inProgress, ago(d: 5)),
        StatusEntry(IncidentStatus.resolved, ago(d: 4)),
      ],
    ),
  ];
}
