import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.43.4';
import { google } from 'https://esm.sh/googleapis@140.0.1';

// Get the Firebase service account key from Supabase secrets
const FIREBASE_SERVICE_ACCOUNT_KEY = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY');

let jwt;

if (FIREBASE_SERVICE_ACCOUNT_KEY) {
  jwt = new google.auth.JWT({
    email: JSON.parse(FIREBASE_SERVICE_ACCOUNT_KEY).client_email,
    key: JSON.parse(FIREBASE_SERVICE_ACCOUNT_KEY).private_key,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
}

async function getAccessToken() {
  return new Promise((resolve, reject) => {
    if (!jwt) {
      return reject('Firebase service account key not found.');
    }
    jwt.authorize((err, tokens) => {
      if (err) {
        return reject(err);
      }
      if (tokens?.access_token) {
        resolve(tokens.access_token);
      } else {
        reject('Failed to retrieve access token.');
      }
    });
  });
}

async function sendFcmNotification(notification, profile) {
  try {
    const accessToken = await getAccessToken();
    const message = {
      message: {
        token: profile.fcm_token,
        notification: {
          title: notification.title || 'New Notification',
          body: notification.message || 'You have a new notification from GrocerMate.',
        },
        data: {
          notification_id: notification.id.toString(),
          type: notification.type,
        },
      },
    };

    const projectId = JSON.parse(FIREBASE_SERVICE_ACCOUNT_KEY!).project_id;
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(message),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      console.error('FCM send error:', response.status, errorBody);
    } else {
      console.log('Successfully sent notification for user:', notification.recipient_id);
    }
  } catch (error) {
    console.error('Error sending FCM notification:', error);
  }
}


const supabaseAdmin = createClient(SUPABASE_URL!, SUPABASE_ANON_KEY!);

console.log("Function started, listening for new notifications...");

supabaseAdmin
  .channel('new_notification_channel')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'notifications' }, async (payload) => {
      console.log('Change received!', payload);
      const newNotification = payload.new;

      if (!newNotification || !newNotification.recipient_id) {
          console.error('Received invalid notification payload:', newNotification);
          return;
      }
      
      // Fetch the recipient's FCM token from the profiles table
      const { data: profile, error: profileError } = await supabaseAdmin
        .from('profiles')
        .select('fcm_token')
        .eq('id', newNotification.recipient_id)
        .single();
      
      if (profileError || !profile || !profile.fcm_token) {
        const errorMessage = profileError ? profileError.message : 'Profile or FCM token not found for recipient ' + newNotification.recipient_id;
        console.error(errorMessage);
        return;
      }

      await sendFcmNotification(newNotification, profile);
  })
  .subscribe((status, err) => {
      if (status === 'SUBSCRIBED') {
          console.log('Successfully subscribed to new_notification_channel!');
      }
      if (status === 'CHANNEL_ERROR') {
          console.error('Subscription error:', err);
      }
  });

// Note: Deno.serve is not used here as this function is long-running and listens for DB changes.
// The function will stay alive as long as the subscription is active.
// We need to keep the process running.
const keepAlive = () => setTimeout(keepAlive, 1000 * 60 * 60);
keepAlive();
