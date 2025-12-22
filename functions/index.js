const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationOnBadPosture = functions.firestore
  .document('Notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    try {
      const reason = snap.data().reason || 'وضعية سيئة!';

      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('fcmToken', '!=', null)
        .get();

      if (usersSnapshot.empty) return null;

      const tokens = [];
      usersSnapshot.forEach(doc => {
        if (doc.data().fcmToken) {
          tokens.push(doc.data().fcmToken);
        }
      });

      if (tokens.length === 0) return null;

      await admin.messaging().sendEachForMulticast({
        notification: {
          title: 'AlignMe Notification',
          body: reason,
        },
        tokens: tokens,
      });

      return null;
    } catch (error) {
      return null;
    }
  });
