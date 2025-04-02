const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize the Firebase Admin SDK
admin.initializeApp();

// Simple ping function for testing connectivity
exports.ping = functions.https.onCall((data, context) => {
  console.log('Ping function called');
  return {
    message: "Pong! Firebase Functions is connected.",
    timestamp: new Date().toISOString()
  };
});

// Function to send push notifications
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  try {
    console.log('sendPushNotification called with data:', JSON.stringify(data));
    
    const { token, payload } = data;
    
    if (!token) {
      console.error('No FCM token provided');
      throw new functions.https.HttpsError('invalid-argument', 'FCM token is required');
    }
    
    if (!payload) {
      console.error('No payload provided');
      throw new functions.https.HttpsError('invalid-argument', 'Notification payload is required');
    }
    
    // Format the message for FCM
    const message = {
      token: token,
      notification: payload.notification,
      data: payload.data || {},
      apns: {
        payload: {
          aps: {
            sound: 'default',
            alert: {
              title: payload.notification.title,
              body: payload.notification.body
            },
            contentAvailable: true
          }
        },
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert"
        }
      }
    };
    
    // Log the message we're about to send
    console.log('Sending FCM message:', JSON.stringify(message));
    
    // Send the message
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending message:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Function that triggers when a new hangout is created
exports.onNewHangout = functions.firestore
  .document('hangouts/{hangoutId}')
  .onCreate(async (snapshot, context) => {
    try {
      const hangout = snapshot.data();
      const hangoutId = context.params.hangoutId;
      
      console.log(`New hangout created with ID: ${hangoutId}`);
      
      // Only send notifications for pending hangouts
      if (hangout.status !== 'pending') {
        console.log('Hangout status is not pending, skipping notification');
        return null;
      }
      
      // Get the invitee user to send them a notification
      const inviteeId = hangout.inviteeID;
      const creatorId = hangout.creatorID;
      
      // Get the invitee's FCM token
      const inviteeDoc = await admin.firestore().collection('users').doc(inviteeId).get();
      
      if (!inviteeDoc.exists) {
        console.log(`Invitee user ${inviteeId} not found`);
        return null;
      }
      
      const inviteeData = inviteeDoc.data();
      const fcmToken = inviteeData.fcmToken;
      
      if (!fcmToken) {
        console.log(`No FCM token found for user ${inviteeId}`);
        return null;
      }
      
      // Get creator's name
      const creatorDoc = await admin.firestore().collection('users').doc(creatorId).get();
      
      if (!creatorDoc.exists) {
        console.log(`Creator user ${creatorId} not found`);
        return null;
      }
      
      const creatorData = creatorDoc.data();
      const creatorName = creatorData.displayName || 'Someone';
      
      // Send the notification
      const message = {
        token: fcmToken,
        notification: {
          title: 'New Hangout Request',
          body: `${creatorName} wants to hangout with you!`
        },
        data: {
          type: 'new_hangout_request',
          hangoutId: hangoutId,
          title: hangout.title || 'New Hangout'
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              contentAvailable: true,
              alert: {
                title: 'New Hangout Request',
                body: `${creatorName} wants to hangout with you!`
              }
            }
          },
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert"
          }
        }
      };
      
      console.log('Sending automatic notification for new hangout:', JSON.stringify(message));
      const response = await admin.messaging().send(message);
      console.log('Successfully sent automatic notification:', response);
      return { success: true };
    } catch (error) {
      console.error('Error sending automatic notification:', error);
      return { success: false, error: error.message };
    }
  });

// Function that triggers when a hangout status changes
exports.onHangoutUpdate = functions.firestore
  .document('hangouts/{hangoutId}')
  .onUpdate(async (change, context) => {
    try {
      const hangoutBefore = change.before.data();
      const hangoutAfter = change.after.data();
      const hangoutId = context.params.hangoutId;
      
      // Only process if status has changed
      if (hangoutBefore.status === hangoutAfter.status) {
        console.log('Hangout status unchanged, skipping notification');
        return null;
      }
      
      console.log(`Hangout ${hangoutId} status changed from ${hangoutBefore.status} to ${hangoutAfter.status}`);
      
      // Only send notifications for accepted or declined status changes
      if (hangoutAfter.status !== 'accepted' && hangoutAfter.status !== 'declined') {
        console.log('Status not accepted or declined, skipping notification');
        return null;
      }
      
      // Determine who to notify (creator gets notified of status changes)
      const creatorId = hangoutAfter.creatorID;
      const inviteeId = hangoutAfter.inviteeID;
      
      // Get the creator's FCM token
      const creatorDoc = await admin.firestore().collection('users').doc(creatorId).get();
      
      if (!creatorDoc.exists) {
        console.log(`Creator user ${creatorId} not found`);
        return null;
      }
      
      const creatorData = creatorDoc.data();
      const fcmToken = creatorData.fcmToken;
      
      if (!fcmToken) {
        console.log(`No FCM token found for user ${creatorId}`);
        return null;
      }
      
      // Get invitee's name
      const inviteeDoc = await admin.firestore().collection('users').doc(inviteeId).get();
      
      if (!inviteeDoc.exists) {
        console.log(`Invitee user ${inviteeId} not found`);
        return null;
      }
      
      const inviteeData = inviteeDoc.data();
      const inviteeName = inviteeData.displayName || 'Your partner';
      
      // Construct notification based on status
      const isAccepted = hangoutAfter.status === 'accepted';
      const title = isAccepted ? 'Hangout Accepted' : 'Hangout Declined';
      const body = isAccepted 
        ? `${inviteeName} accepted your hangout request!`
        : `${inviteeName} declined your hangout request.`;
      
      // Send the notification
      const message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body
        },
        data: {
          type: isAccepted ? 'hangout_accepted' : 'hangout_declined',
          hangoutId: hangoutId,
          title: hangoutAfter.title || 'Hangout'
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              contentAvailable: true,
              alert: {
                title: title,
                body: body
              }
            }
          },
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert"
          }
        }
      };
      
      console.log('Sending automatic notification for hangout update:', JSON.stringify(message));
      const response = await admin.messaging().send(message);
      console.log('Successfully sent hangout update notification:', response);
      return { success: true };
    } catch (error) {
      console.error('Error sending hangout update notification:', error);
      return { success: false, error: error.message };
    }
  }); 