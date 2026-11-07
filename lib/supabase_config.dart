/// Supabase project used for incident photo storage.
///
/// Both values are public by design (like the Firebase config): they only
/// identify the project. Access is controlled by the storage policies in
/// `supabase/storage_policies.sql`, which only accept verified ALU users
/// signed in through Firebase Auth.
///
/// Fill these in from Supabase dashboard -> Project Settings -> API Keys
/// (the "Publishable key", starts with sb_publishable_) and Data API (URL).
const supabaseUrl = 'https://numddfuqpdehluvzaddw.supabase.co';
const supabasePublishableKey =
    'sb_publishable_0BnZTZ4BakgHHhGYSsIDkg_WzpOgIZs';

const supabasePhotoBucket = 'incident-photos';

bool get supabaseConfigured => !supabaseUrl.contains('YOUR-PROJECT-REF');
