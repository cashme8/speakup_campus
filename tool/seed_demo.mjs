// Seeds 4 demo reports into Firestore for the demo video.
//
// It signs in as a real verified student and a real staff account and writes
// through the normal Firestore security rules (no admin access), exactly like
// the app does. Re-running it skips reports that already exist.
//
// Usage (PowerShell):
//   $env:STUDENT_EMAIL="..."; $env:STUDENT_PASSWORD="..."
//   $env:STAFF_EMAIL="...";   $env:STAFF_PASSWORD="..."
//   node tool/seed_demo.mjs

const API_KEY = 'AIzaSyBrHV8Y25vggm6PG0SM1zAfdoQfr9s3fRg'; // public Firebase web/Android key
const PROJECT = 'speakup-campus';
const DOCS = `projects/${PROJECT}/databases/(default)/documents`;
const BASE = `https://firestore.googleapis.com/v1/${DOCS}`;

const REPORTS = [
  {
    id: 'demo-water-residence',
    category: 'water',
    title: 'Leaking tap in residence washroom',
    description: 'The tap in the 2nd floor washroom has been leaking all week and the floor stays wet.',
    location: 'Student Residence',
    locationDetail: '2nd floor washroom',
    anonymous: false,
    staffSteps: [
      { status: 'inProgress', note: 'Plumber booked for Thursday morning.' },
      { status: 'resolved', note: 'Tap washer replaced and floor cleaned.' },
    ],
  },
  {
    id: 'demo-electricity-blockb',
    category: 'electricity',
    title: 'Sockets not working in Block B',
    description: 'None of the wall sockets in Room 204 work, so we cannot charge laptops during class.',
    location: 'Block B',
    locationDetail: 'Room 204',
    anonymous: false,
    staffSteps: [{ status: 'inProgress', note: 'Electrician is checking the circuit breaker.' }],
  },
  {
    id: 'demo-furniture-library',
    category: 'furniture',
    title: 'Broken chairs in the library',
    description: 'Three chairs in the quiet study area have broken legs and are unsafe to sit on.',
    location: 'Library',
    locationDetail: 'Quiet study area',
    anonymous: false,
    staffSteps: [],
  },
  {
    id: 'demo-safety-gate',
    category: 'safety',
    title: 'Street light out near the main gate',
    description: 'The light next to the main gate is off at night, making the walk back very dark.',
    location: 'Main Gate',
    locationDetail: null,
    anonymous: true,
    staffSteps: [],
  },
];

// ---------- helpers ----------

function env(name) {
  const v = process.env[name];
  if (!v) {
    console.error(`Missing environment variable ${name}. See the usage notes at the top of this file.`);
    process.exit(1);
  }
  return v;
}

async function signIn(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );
  const body = await res.json();
  if (!res.ok) throw new Error(`Sign-in failed for ${email}: ${body.error?.message}`);
  return { uid: body.localId, token: body.idToken, name: body.displayName || email.split('@')[0] };
}

// Converts a plain JS value into Firestore's REST value format.
function val(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(val) } };
  return { mapValue: { fields: fields(v) } };
}
const fields = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, val(v)]));

async function commit(token, write) {
  const res = await fetch(`${BASE}:commit`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({ writes: [write] }),
  });
  if (res.ok) return { ok: true };
  const body = await res.json().catch(() => ({}));
  return { ok: false, status: res.status, message: body.error?.message ?? res.statusText };
}

const pause = (ms) => new Promise((r) => setTimeout(r, ms));

// ---------- main ----------

const student = await signIn(env('STUDENT_EMAIL'), env('STUDENT_PASSWORD'));
const staff = await signIn(env('STAFF_EMAIL'), env('STAFF_PASSWORD'));
console.log(`Signed in: student ${student.name}, staff ${staff.name}\n`);

for (const r of REPORTS) {
  const name = `${DOCS}/incidents/${r.id}`;

  // Create as the student (same fields the app writes).
  const created = await commit(student.token, {
    update: {
      name,
      fields: fields({
        title: r.title,
        description: r.description,
        category: r.category,
        location: r.location,
        locationDetail: r.locationDetail,
        status: 'submitted',
        reporterId: student.uid,
        reporterName: r.anonymous ? null : student.name,
        isAnonymous: r.anonymous,
        affectedBy: [],
        imageUrl: null,
        imagePath: null,
        history: [{ status: 'submitted', at: new Date() }],
      }),
    },
    currentDocument: { exists: false },
    updateTransforms: [
      { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
      { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
    ],
  });

  if (!created.ok) {
    if (created.status === 409 || /already exists/i.test(created.message)) {
      console.log(`- ${r.title}: already exists, skipped`);
      continue;
    }
    console.error(`x ${r.title}: create failed (${created.status}) ${created.message}`);
    if (created.status === 403) console.error('  Is the student account verified?');
    continue;
  }
  console.log(`+ ${r.title} (${r.category}, ${r.anonymous ? 'anonymous' : student.name})`);

  // Staff status changes, one history entry each (as the rules require).
  for (const step of r.staffSteps) {
    await pause(1200); // so the timeline shows distinct times
    const updated = await commit(staff.token, {
      update: { name, fields: fields({ status: step.status }) },
      updateMask: { fieldPaths: ['status'] },
      currentDocument: { exists: true },
      updateTransforms: [
        {
          fieldPath: 'history',
          appendMissingElements: {
            values: [val({ status: step.status, at: new Date(), note: step.note, byName: staff.name })],
          },
        },
        { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
      ],
    });
    if (updated.ok) {
      console.log(`    → ${step.status}: "${step.note}"`);
    } else {
      console.error(`    x status update failed (${updated.status}) ${updated.message}`);
      if (updated.status === 403) console.error('    Check that users/{uid}.role is "staff" for the staff account.');
      break;
    }
  }
}

console.log('\nDone. Open the app: the reports appear live.');
