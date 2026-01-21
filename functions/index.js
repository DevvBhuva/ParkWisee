/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentCreated} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {CloudTasksClient} = require("@google-cloud/tasks");

admin.initializeApp();

// CONFIGURATION
// TODO: Replace these with your actual Project ID and Location
const PROJECT_ID = "YOUR_PROJECT_ID"; 
const LOCATION = "us-central1"; // or 'asia-south1' etc.
const QUEUE = "booking-notifications"; // You must create this queue in GCP Console

const tasksClient = new CloudTasksClient();

/**
 * Triggered when a new booking is created in 'users/{userId}/bookings/{bookingId}'
 * OR 'parkings/{parkingId}/bookings/{bookingId}' depending on your needs.
 * 
 * Assuming 'users/{userId}/bookings/{bookingId}' is the source of truth for the user.
 */
exports.onBookingCreated = onDocumentCreated(
  "users/{userId}/bookings/{bookingId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No data associated with the event");
      return;
    }

    const booking = snapshot.data();
    const bookingId = event.params.bookingId;
    const userId = event.params.userId;

    // 1. Data Parsing
    // Note: Using 'startTime' and 'endTime' to match your Flutter 'Booking' model using CamelCase.
    // If your DB uses 'slot_start_time', change these fields accordingly.
    const startTimeStamp = booking.startTime || booking.slot_start_time;
    const endTimeStamp = booking.endTime || booking.slot_end_time;
    
    // Check if expected fields exist
    if (!startTimeStamp || !endTimeStamp) {
      logger.warn(`Booking ${bookingId} missing start/end time. Skipping scheduling.`);
      return;
    }

    // Convert Firestore Timestamp to Date
    const startTime = startTimeStamp.toDate();
    const endTime = endTimeStamp.toDate();

    // 2. Schedule Times (5 minutes before)
    const startNotificationTime = new Date(startTime.getTime() - 5 * 60 * 1000);
    const endNotificationTime = new Date(endTime.getTime() - 5 * 60 * 1000);

    // 3. Prepare Payload Data
    // We pass minimal data to the Task, which will call our HTTP function
    const payloadStart = {
      type: 'START_SOON',
      bookingId,
      userId,
      parkingName: booking.spotName || booking.parking_name || "Parking Spot",
      vehicleNumber: booking.vehicleNumber || booking.vehicle_number || "Vehicle",
      // If fcm_token is NOT in booking, we can fetch it in the task handler from User doc.
      // But if it IS in booking as requested:
      fcmToken: booking.fcm_token || booking.fcmToken, 
    };

    const payloadEnd = {
      ...payloadStart,
      type: 'END_SOON',
    };

    try {
      // 4. Enqueue Tasks
      await enqueueTask(payloadStart, startNotificationTime);
      await enqueueTask(payloadEnd, endNotificationTime);
      
      logger.info(`Scheduled notifications for booking ${bookingId}`);
    } catch (error) {
      logger.error(`Failed to schedule notifications for ${bookingId}`, error);
    }
  }
);

/**
 * Helper to enqueue a Cloud Task
 */
async function enqueueTask(payload, scheduleTime) {
  const queuePath = tasksClient.queuePath(PROJECT_ID, LOCATION, QUEUE);
  
  // URL of the HTTP function that will send the FCM
  // You get this URL after deploying: https://us-central1-YOUR_PROJECT.cloudfunctions.net/sendScheduledNotification
  const url = `https://${LOCATION}-${PROJECT_ID}.cloudfunctions.net/sendScheduledNotification`;

  const task = {
    httpRequest: {
      httpMethod: "POST",
      url,
      body: Buffer.from(JSON.stringify(payload)).toString("base64"),
      headers: {
        "Content-Type": "application/json",
      },
    },
    scheduleTime: {
      seconds: Math.floor(scheduleTime.getTime() / 1000),
    },
  };

  await tasksClient.createTask({parent: queuePath, task});
}

/**
 * HTTPS Function called by Cloud Tasks to actually send the notification.
 */
exports.sendScheduledNotification = onRequest(async (req, res) => {
  const {type, userId, parkingName, vehicleNumber, fcmToken: tokenFromPayload} = req.body;

  if (!tokenFromPayload) {
      // Optional: Fetch latest token from 'users/{userId}' if not in payload
      // const userDoc = await admin.firestore().collection('users').doc(userId).get();
      // ...
      logger.warn("No FCM token provided in payload.");
      res.status(400).send("No Token");
      return;
  }
  
  let title = "";
  let body = "";

  if (type === 'START_SOON') {
    title = "Parking Starts in 5 Mins ⏳";
    body = `Your slot at ${parkingName} for ${vehicleNumber} is starting soon.`;
  } else if (type === 'END_SOON') {
    title = "Parking Ends in 5 Mins ⚠️";
    body = `Your slot at ${parkingName} is expiring. Retrieve your vehicle or extend.`;
  } else {
    res.status(200).send("Unknown Type");
    return;
  }

  const message = {
    token: tokenFromPayload,
    notification: {
      title,
      body,
    },
    data: {
      // Add any data required for navigation
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: type 
    },
    android: {
      priority: 'high',
    },
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
    logger.info(`Notification sent: ${type} to ${userId}`);
    res.status(200).send("Sent");
  } catch (error) {
    logger.error("Error sending FCM", error);
    res.status(500).send(error.toString());
  }
});
