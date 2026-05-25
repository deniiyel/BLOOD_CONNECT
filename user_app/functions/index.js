const admin = require("firebase-admin");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

exports.notifyDonorOnRequestCreated = onDocumentCreated(
  "requests/{requestId}",
  async (event) => {
    const request = event.data && event.data.data();
    if (!request || request.status !== "pending") return;

    const donor = await db.collection("users").doc(request.donorId).get();
    const tokens = donor.get("fcmTokens") || [];
    if (!tokens.length) return;

    await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: request.urgency === "Emergency"
          ? "Emergency blood request"
          : "New blood request",
        body: `${request.recipientName} needs ${request.bloodGroup} blood at ${request.hospital}.`,
      },
      data: {
        type: "request_created",
        requestId: event.params.requestId,
        urgency: request.urgency || "Normal",
      },
    });
  },
);

exports.notifyRecipientOnRequestStatusChanged = onDocumentUpdated(
  "requests/{requestId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after || before.status === after.status) return;

    const recipient = await db.collection("users").doc(after.recipientId).get();
    const tokens = recipient.get("fcmTokens") || [];
    if (!tokens.length) return;

    const titles = {
      accepted: "Blood request accepted",
      rejected: "Blood request declined",
      completed: "Blood request completed",
      expired: "Blood request expired",
    };

    await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: titles[after.status] || "Blood request updated",
        body: `${after.donorName}'s request status is now ${after.status}.`,
      },
      data: {
        type: "request_status_changed",
        requestId: event.params.requestId,
        status: after.status,
      },
    });
  },
);

exports.expirePendingRequests = onSchedule("every 5 minutes", async () => {
  const now = admin.firestore.Timestamp.now();
  const snap = await db
    .collection("requests")
    .where("status", "==", "pending")
    .where("expiresAt", "<=", now)
    .limit(100)
    .get();

  if (snap.empty) return;

  const batch = db.batch();
  snap.docs.forEach((doc) => {
    batch.update(doc.ref, {
      status: "expired",
      expiredAt: now,
    });
  });
  await batch.commit();
});
